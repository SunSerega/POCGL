uses POCGL_Utils  in '..\..\POCGL_Utils';

uses AOtp         in '..\..\Utils\AOtp';
uses ATask        in '..\..\Utils\ATask';
uses AQueue       in '..\..\Utils\AQueue';
uses CLArgs       in '..\..\Utils\CLArgs';
uses Fixers       in '..\..\Utils\Fixers';
uses CodeGen      in '..\..\Utils\CodeGen';

uses DescriptionsData;

type
  CommentData = sealed class
    private used := false;
    private directly_used := false;
    private source: string;
    private comment: string;
    
    public constructor(source: string; comment: string);
    begin
      self.source := source;
      self.comment := comment;
    end;
    
    public static all := new Dictionary<string, CommentData>;
    public static procedure LoadFile(fname: string) :=
    foreach var (bl_name, bl_lns) in FixerUtils.ReadBlocks(fname, true) do
      if bl_name=nil then
        continue else // Комментарий в начале файла
      if all.ContainsKey(bl_name) then
        Otp($'ERROR: key %{bl_name}% found in "{all[bl_name].source}" and "{GetRelativePathRTA(fname)}"') else
        all[bl_name] := new CommentData(GetRelativePathRTA(fname), bl_lns.JoinToString(#10).Trim);
    public static procedure LoadAll(nick: string);
    begin
      var path := GetFullPathRTA(nick);
      if not System.IO.Directory.Exists(path) then
        System.IO.Directory.CreateDirectory(path) else
      foreach var fname in System.IO.Directory.EnumerateFiles(path, '*.dat', System.IO.SearchOption.AllDirectories) do
        LoadFile(fname);
      
//      foreach var bl_name in all.Keys do
//      begin
//        $'# {bl_name}'.Println;
//        all[bl_name].comment.Println;
//      end;
//      Halt;
      
    end;
    
    private static function GetPrintableData(key: string): string;
    begin
      var val := all[key];
      Result := $'Comment [{key}] from [{val.source}]';
    end;
    
    public static function ApplyToKey(key: string; missing_keys: AsyncQueue<string>; prev: List<string> := nil): string;
    begin
      var cd: CommentData;
      if all.TryGetValue(key, cd) then
      begin
        cd.used := true;
        var no_prev := prev=nil;
        cd.directly_used := cd.directly_used or no_prev;
        
        if no_prev then
          prev := new List<string> else
        if key in prev then
          raise new MessageException($'Comment loop chain:{#10}{prev.Select(GetPrintableData).JoinToString(#10)}]');
        prev += key;
        
        Result := Apply(cd.comment, missing_keys, prev);
        cd.comment := Result;
      end else
        missing_keys.Enq(key);
    end;
    
    static function Apply(l: string; missing_keys: AsyncQueue<string>; prev: List<string> := nil): string;
    begin
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
        
        res += ApplyToKey(l.Substring(ind1,ind2-ind1), missing_keys, prev);
        
        last_ind := ind2+1;
        if last_ind=l.Length then break;
      end;
      
      res.Append(l, last_ind,l.Length-last_ind);
      Result := res.ToString;
    end;
    
  end;
  
  FileLogData = record
    skipped := new AsyncQueue<(CommentableBase,boolean)>;
    missing := new AsyncQueue<string>;
    
    static procedure WriteAll(s: sequence of string; wr: Writer) :=
    foreach var c in s.Distinct do
    begin
      wr += '# ';
      wr += c;
      wr += #10;
    end;
    
    procedure Finish;
    begin
      skipped.Finish;
      missing.Finish;
    end;
    
    procedure Write(ignored_types: HashSet<string>; wr_missing: Writer);
    begin
      WriteAll(skipped.Where(\(c,need_report)->
      begin
        match c with
          
          CommentableType(var ct): Result :=
          ignored_types.Add(ct.FullName);
          
          CommentableTypeMember(var cm): Result :=
          (cm.Type=nil) or not ignored_types.Contains(cm.Type.FullName);
          
          else raise new System.NotImplementedException($'{c.GetType}');
        end;
        Result := Result and need_report;
      end).Select(\(c,need_report)->c.FullName) + missing, wr_missing);
    end;
    
  end;
  
begin
  try
    var nick := GetArgs('nick').SingleOrDefault;
    var fls := GetArgs('fname').ToArray;
    var use_pd := 'UseLastPreDoc' in CommandLineArgs;
    
    if is_separate_execution and string.IsNullOrWhiteSpace(nick) and (fls.Length=0) then
    begin
      
      nick := 'OpenCLABC';
      fls := | 'Modules.Packed\OpenCLABC.pas' |;
      
    end;
    
    CommentData.LoadAll(nick);
    
    var all_log_data := new Dictionary<string, FileLogData>;
    foreach var fname in fls do all_log_data[fname] := new FileLogData;
    
    (
      ProcTask(()->
      begin
        var wr_missing := new FileWriter(GetFullPathRTA($'{nick}.missing.log'));
        var wr_unused  := new FileWriter(GetFullPathRTA($'{nick}.unused.log'));
        var wr_used    := new FileWriter(GetFullPathRTA($'{nick}.used.log'));
        
        var ignored_types := new HashSet<string>;
        
        foreach var log_data in all_log_data.Values do
          log_data.Write(ignored_types, wr_missing);
        
        foreach var key in CommentData.all.Keys do
          if not CommentData.all[key].used then
          begin
            wr_unused += '# ';
            wr_unused += key;
            wr_unused += #10;
          end;
        
        CommentData.all
        .Select(kvp->(kvp.Key,kvp.Value))
        .Where(\(key,cd)->cd.directly_used)
        .OrderBy(\(key,cd)->key)
        .GroupBy(\(key,cd)->cd.comment)
        .Foreach(g->
        begin
          foreach var (key,cd) in g do
          begin
            wr_used += '# ';
            wr_used += key;
            wr_used += #10;
          end;
          wr_used += g.Key;
          wr_used += #10#10;
        end);
        
        (wr_missing * wr_unused * wr_used).Close;
      end)
    *
      fls.Select(fname->ProcTask(()->
      begin
        var pd_fname := GetFullPathRTA($'{System.IO.Path.GetFileNameWithoutExtension(fname)}.predoc');
        
        if not use_pd then
        begin
          System.IO.File.Delete(pd_fname);
          System.IO.File.Move(fname, pd_fname);
        end;
        
        var res := new System.IO.StreamWriter(fname, false, enc);
        var log_data := all_log_data[fname];
        
        var last_line: string := nil;
        var already_commented := false;
        foreach var c in CommentableBase.FindAllCommentalbes(ReadLines(pd_fname), l->
        begin
          if last_line<>nil then
          begin
            already_commented := last_line.TrimStart(' ').StartsWith('///');
            res.WriteLine(last_line);
          end;
          
          last_line := CommentData.Apply(l, log_data.missing);
          
          Result := true;
        end) do
        begin
          if already_commented then
          begin
            log_data.skipped.Enq((c,false));
            continue;
          end;
          var key := c.FullName;
          
          if not CommentData.all.ContainsKey(key) then
            log_data.skipped.Enq((c,true)) else
          begin
            var spaces := last_line.TakeWhile(ch->ch=' ').Count;
            foreach var l in CommentData.ApplyToKey(key, log_data.missing).Split(#10) do
            begin
              res.Write(' ' * spaces);
              res.Write('///');
              res.WriteLine(l.TrimEnd);
            end;
          end;
          
        end;
        if last_line<>nil then res.Write(last_line);
        
        res.Close;
        log_data.Finish;
      end)).CombineAsyncTask
    ).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.