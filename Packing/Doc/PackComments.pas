uses CommentableData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

type
  CommentData = class
    private used: boolean;
    private source: string;
    private comment: string;
    
    public constructor(source: string; comment: string);
    begin
      self.source := source;
      self.comment := comment;
    end;
    
    public static all := new Dictionary<string, CommentData>;
    public static procedure Load(dir: string) :=
    foreach var fname in System.IO.Directory.EnumerateFiles(dir) do
    begin
      var sb: StringBuilder := nil;
      var cns := new List<string>;
      
      foreach var l in ReadLines(fname, new System.Text.UTF8Encoding(true)) do
        if l.StartsWith('#') then
        begin
          
          if sb<>nil then
          begin
            sb.Length-=1;
            var comment := sb.ToString.TrimEnd(#10,#13);
//            Write($'>>>{comment}<<<');
            foreach var cn in cns do
              if all.ContainsKey(cn) then
                Writeln($'ERROR: key %{cn}% found in "{all[cn].source}" and "{fname}"') else
                all.Add(cn, new CommentData(fname, comment));
            cns.Clear;
            sb := nil;
          end;
          
          cns.Add(l.Substring(1).Trim);
        end else
        begin
          if sb=nil then sb := new StringBuilder;
          sb.AppendLine(l);
        end;
      
      if (sb<>nil) and (cns.Count<>0) then
      begin
        sb.Length-=1;
        var comment := sb.ToString.TrimEnd(#10,#13);
        foreach var cn in cns do
          all.Add(cn, new CommentData(fname, comment));
      end;
      
    end;
    
    static function Apply(l: string; prev: List<string> := nil): string;
    begin
      if prev=nil then prev := new List<string>;
      prev += l;
      var res := new StringBuilder;
      
      var last_ind := 0;
      while true do
      begin
        var ind1 := l.IndexOf('%', last_ind);
        if ind1=-1 then break;
        
        var ind2 := l.IndexOf('%', ind1+1);
        if ind2=-1 then raise new System.InvalidOperationException($'>>>{l}<<<');
        
        res.Append(l, last_ind, ind1-last_ind);
        ind1 += 1;
        var key := l.Substring(ind1,ind2-ind1);
        var val: CommentData;
        if all.TryGetValue(key, val) then
        begin
          val.used := true;
          res.Append( Apply(all[key].comment, prev.ToList) ); //ToDo ошибки prev
        end else
          Writeln($'ERROR: key %{key}% not found!');
        
        last_ind := ind2+1;
        if last_ind=l.Length then break;
      end;
      
      res.Append(l, last_ind,l.Length-last_ind);
      Result := res.ToString;
    end;
    
  end;
  
begin
  try
    var CommandLineArgs := PABCSystem.CommandLineArgs();
    if not CommandLineArgs.Contains('SecondaryProc') then CommandLineArgs := Arr('fname=OpenCLABC');
    
    var fname := CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault;
    if fname=nil then raise new MessageException('Invalid args: [' + CommandLineArgs.Select(arg->$'"{arg}"').JoinIntoString + ']' );
    fname := fname.SubString('fname='.Length);
    
    var exe_path := System.IO.Path.GetDirectoryName(GetEXEFileName);
    
    var res := System.IO.File.CreateText($'{exe_path}\{fname}.res.pas');
    var last_line: string := nil;
    
    var skiped := System.IO.File.CreateText($'{exe_path}\{fname}.skiped.dat');
    
    CommentData.Load($'{exe_path}\{fname}');
    CommentableData.FindCommentable(ReadLines(fname+'.pas'),
      l->
      begin
        if last_line<>nil then res.WriteLine(last_line);
        last_line := CommentData.Apply(l);
        Result := not l.TrimStart(' ').StartsWith('///');
      end,
      c->
      begin
        if CommentData.all.ContainsKey(c) then
        begin
          var pre := last_line.Substring(0,last_line.TakeWhile(ch->ch=' ').Count)+'///';
          foreach var l in CommentData.Apply($'%{c}%').Remove(#13).Split(#10) do
          begin
            res.Write(pre);
            res.WriteLine(l);
          end;
        end else
        if not c.Contains('.operator') then
          skiped.WriteLine(c);
      end
    );
    res.Write(last_line);
    
    foreach var key in CommentData.all.Keys do
      if not CommentData.all[key].used then
        Writeln($'WARNING: key %{key}% wasn''t used!');
    
    res.Close;
    skiped.Close;
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.