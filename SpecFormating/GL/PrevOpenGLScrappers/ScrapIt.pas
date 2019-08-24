uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';
uses CoreFuncData in '..\CoreFuncData.pas';

const
  search_key2 = '$region ';
  search_key3 = '$endregion';
  search_key4 = 'name ''';

begin
  try
    var bw := new System.IO.BinaryWriter(System.IO.File.Create(GetFullPath('..\..\prev funcs.bin',GetEXEFileName)));
    
    bw.BaseStream.Position := 4;
    
    var last_fn := '';
    var prev_funcs := new HashSet<string>;
    var regions_stack := new List<(integer,string)>;
    
    ReadLines(GetFullPath('..\OpenGL.pas',GetEXEFileName))
    .SkipWhile(l->not l.Contains('gl = static class'))
    .TakeWhile(l->not l.Contains('end;'))
    .Foreach(l->
    begin
//      writeln('='*50);
//      writeln(l);
      
      var ind := l.IndexOf(search_key2);
      if ind<>-1 then
      begin
//        writeln(2);
        ind += search_key2.Length;
        
        l := l.Substring(ind,l.IndexOf('}')-ind);
        if not l.Contains('-') then
        begin
          regions_stack += (-1,'');
          exit;
        end;
        
        var v := l.Split(new string[](' - '), System.StringSplitOptions.None);
        regions_stack += ( v[0].ToWords('.').Select(s->s.ToInteger).Last(i->i<>0), v[1].Trim );
        exit;
      end;
      
      ind := l.IndexOf(search_key3);
      if ind<>-1 then
      begin
//        writeln(3);
        regions_stack.RemoveLast;
        exit;
      end;
      
      ind := l.IndexOf(search_key4);
      if ind<>-1 then
      begin
//        writeln(4);
        ind += search_key4.Length;
        
        var fn := l.Substring(ind,l.IndexOf('''',ind)-ind);
        if fn=last_fn then exit;
        last_fn := fn;
        if not prev_funcs.Add(fn) then raise new System.InvalidOperationException;
        
        var fd := new CoreFuncDef(fn);
        fd.chapter := regions_stack.TakeWhile(t->t[0]<>-1).ToList;
        fd.Save(bw);
        
        exit;
      end;
    end);
    
    bw.BaseStream.Position := 0;
    bw.Write(prev_funcs.Count);
    
    bw.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.