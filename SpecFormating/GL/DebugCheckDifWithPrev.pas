uses CoreFuncData;

function ReadAllFuncsPrev(fname: string): HashSet<string>;
begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  var cap := br.ReadInt32;
  Result := new HashSet<string>(cap);
  loop cap do Result += br.ReadString;
end;

function ReadAllFuncs(fname: string): HashSet<string>;
begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  var cap := br.ReadInt32;
  Result := new HashSet<string>(cap);
  loop cap do Result += CoreFuncDef.Load(br).name;
end;

begin
  try
    var hs1 := ReadAllFuncs('4.6 funcs.bin');
    var hs2 := ReadAllFuncsPrev('prev funcs.bin');
    
    foreach var f in hs2.Sorted do
      if not hs1.Remove(f) then
        writeln($'"{f.Substring(2)}" not found');
    
    if hs1.Any then
    begin
      writeln;
      writeln('new funcs:');
      hs1.Sorted.PrintLines(f->f.Substring(2));
    end;
    
  except
    on e: Exception do writeln(e);
  end;
  
  readln;
end.