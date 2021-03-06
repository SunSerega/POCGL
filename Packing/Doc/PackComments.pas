﻿uses POCGL_Utils  in '..\..\POCGL_Utils';

uses AOtp         in '..\..\Utils\AOtp';
uses ATask        in '..\..\Utils\ATask';
uses AQueue       in '..\..\Utils\AQueue';
uses CLArgs       in '..\..\Utils\CLArgs';
uses Fixers       in '..\..\Utils\Fixers';

uses CommentableData;

type
  CommentData = sealed class
    private used: boolean;
    private source: string;
    private comment: string;
    
    public constructor(source: string; comment: string);
    begin
      self.source := source;
      self.comment := comment;
    end;
    
    public static all := new Dictionary<string, CommentData>;
    public static procedure LoadFile(fname: string) :=
    foreach var bl in FixerUtils.ReadBlocks(fname, true) do
      if bl[0]=nil then
        continue else // Комментарий в начале файла
      if all.ContainsKey(bl[0]) then
        Otp($'ERROR: key %{bl[0]}% found in "{all[bl[0]].source}" and "{GetRelativePathRTA(fname)}"') else
        all[bl[0]] := new CommentData(GetRelativePathRTA(fname), bl[1].JoinToString(#10).Trim);
    public static procedure LoadAll(nick: string);
    begin
      var path := GetFullPathRTA(nick);
      if not System.IO.Directory.Exists(path) then
      begin
        Otp($'WARNING: Skipped [{nick}], because data folder not found');
        exit;
      end;
      foreach var fname in System.IO.Directory.EnumerateFiles(path, '*.dat', System.IO.SearchOption.AllDirectories) do
        LoadFile(fname);
    end;
    
    private static function GetPrintableData(key: string): string;
    begin
      var val := all[key];
      Result := $'Comment [{key}] from [{val.source}]';
    end;
    
    public static function ApplyToKey(key: string; prev: List<string> := nil): string;
    begin
      var cd: CommentData;
      if all.TryGetValue(key, cd) then
      begin
        cd.used := true;
        Result := Apply(cd.comment, prev);
      end else
        Otp($'ERROR: key %{key}% wasn''t found!');
    end;
    
    static function Apply(l: string; prev: List<string> := nil): string;
    begin
      if prev=nil then
        prev := new List<string> else
      if l in prev then
        raise new MessageException($'Comment loop chain:{#10}{prev.Select(GetPrintableData).JoinToString(#10)}]');
      prev += l;
      var res := new StringBuilder;
      
      var ind_comment := l.IndexOf('//');
      if ind_comment=-1 then ind_comment := l.Length;
      
      var last_ind := 0;
      while true do
      begin
        var ind1 := l.IndexOf('%', last_ind, ind_comment-last_ind);
        if ind1=-1 then break;
        
        var ind2 := l.IndexOf('%', ind1+1, ind_comment-ind1-1);
        if ind2=-1 then raise new System.InvalidOperationException($'>>>{l}<<<');
        
        res.Append(l, last_ind, ind1-last_ind);
        ind1 += 1;
        
        res += ApplyToKey(l.Substring(ind1,ind2-ind1));
        
        last_ind := ind2+1;
        if last_ind=l.Length then break;
      end;
      
      res.Append(l, last_ind,l.Length-last_ind);
      Result := res.ToString;
    end;
    
  end;
  
begin
  try
    var nick := GetArgs('nick').SingleOrDefault;
    var fls := GetArgs('fname').ToArray;
    
    if is_separate_execution and string.IsNullOrWhiteSpace(nick) and (fls.Length=0) then
    begin
      
      nick := 'OpenCLABC';
      fls := | 'Modules.Packed\OpenCLABC.pas' |;
      
    end;
    
    CommentData.LoadAll(nick);
    
    var all_skipped := new Dictionary<string, AsyncQueue<CommentableBase>>;
    foreach var fname in fls do all_skipped[fname] := new AsyncQueue<CommentableBase>;
    
    (
      ProcTask(()->
      begin
        var skipped_types := new HashSet<string>;
        var skipped := new System.IO.StreamWriter(GetFullPathRTA($'{nick}.skipped.log'), false, enc);
        
        foreach var q in all_skipped.Values do
          foreach var c in q do
          match c with
            
            CommentableType(var ct):
            if skipped_types.Add(ct.FullName) then
              skipped.WriteLine(ct.FullName);
            
            CommentableTypeMember(var cm):
            if (cm.Type=nil) or not skipped_types.Contains(cm.Type.FullName) then
              skipped.WriteLine(cm.FullName);
            
          end;
        
        skipped.Close;
      end)
    *
      fls.Select(fname->ProcTask(()->
      begin
        var res := new System.IO.StreamWriter($'{fname}.docres', false, enc);
        var skipped := all_skipped[fname];
        
        var last_line: string := nil;
        var already_commented := false;
        foreach var c in CommentableBase.FindAllCommentalbes(ReadLines(fname), l->
        begin
          already_commented := (last_line<>nil) and last_line.TrimStart(' ').StartsWith('///');
          if last_line<>nil then res.WriteLine(last_line);
          
          last_line := CommentData.Apply(l);
          
          Result := true;
        end) do
        begin
          if already_commented then continue;
          var key := c.FullName;
          
          if not CommentData.all.ContainsKey(key) then
            skipped.Enq(c) else
          begin
            var spaces := last_line.TakeWhile(ch->ch=' ').Count;
            foreach var l in CommentData.ApplyToKey(key).Split(#10) do
            begin
              res.Write(' ' * spaces);
              res.Write('///');
              res.WriteLine(l);
            end;
          end;
          
        end;
        if last_line<>nil then res.Write(last_line);
        
        res.Close;
        skipped.Finish;
        
//        if is_secondary_proc then
        begin
          System.IO.File.Delete(fname);
          System.IO.File.Move($'{fname}.docres', fname);
        end;
        
      end)).CombineAsyncTask
    ).SyncExec;
    
    foreach var key in CommentData.all.Keys do
      if not CommentData.all[key].used then
        Otp($'WARNING: key %{key}% wasn''t used!');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.