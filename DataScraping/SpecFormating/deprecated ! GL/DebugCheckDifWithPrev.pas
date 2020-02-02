uses CoreFuncData;

type
  FuncChapterComparer = class(System.Collections.Generic.EqualityComparer<List<(integer,string)>>)
    
    public function Equals(x, y: List<(integer,string)>): boolean; override :=
    x.Take(2).SequenceEqual(y.Take(2));
    
    public function GetHashCode(obj: List<(integer,string)>): integer; override :=
    obj.Count=0?0:
    obj.Last[1].GetHashCode;
    
  end;

function ReadAllFuncs(fname: string): Dictionary<List<(integer,string)>, HashSet<string>>;
begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  Result := new Dictionary<List<(integer,string)>, HashSet<string>>(new FuncChapterComparer);
  
  loop br.ReadInt32 do
  begin
    var fd := CoreFuncDef.Load(br);
    if fd.chapter.Count>2 then fd.chapter.RemoveRange(2,fd.chapter.Count-2);
    
    var fhs: HashSet<string>;
    if not Result.TryGetValue(fd.chapter, fhs) then
    begin
      fhs := new HashSet<string>;
      Result[fd.chapter] := fhs;
    end;
    
    fhs += fd.name;
  end;
  
end;

begin
  try
    var d1 := ReadAllFuncs('4.6 funcs.bin');
    var d2 := ReadAllFuncs('prev funcs.bin');
    
//    d1.PrintLines;
//    writeln;
//    d2.PrintLines;
//    writeln;
    
    foreach var key in d2.Keys do
    begin
      var key_str := key.Select(t->t[0]).JoinIntoString('.');
      
      if not d1.ContainsKey(key) then
        foreach var f in d2[key].Sorted do writeln($'{key_str}, removed: "{f}"') else
      begin
        var hs2 := d2[key];
        var hs1 := d1[key];
        
        foreach var f in hs2.Sorted do
          if not hs1.Remove(f) then
            writeln($'{key_str}, removed: "{f}"');
        
        foreach var f in hs1.Sorted do writeln($'{key_str}, new: "{f}"');
        
      end;
      
      d1.Remove(key);
    end;
    
    foreach var key in d1.Keys do
    begin
      var key_str := key.Select(t->t[0]).JoinIntoString('.');
      foreach var f in d1[key].Sorted do writeln($'{key_str}, new: "{f}"');
    end;
    
  except
    on e: Exception do writeln(e);
  end;
  
  writeln('done');
  readln;
end.