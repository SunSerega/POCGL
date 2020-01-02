uses CoreFuncData;

var sw: System.IO.StreamWriter;

function ReadAllFuncs(fname: string): array of string;
begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  Result := new string[br.ReadInt32];
  for var i := 0 to Result.Length-1 do
    Result[i] := CoreFuncDef.Load(br).name;
end;

procedure Compare(older, newer: array of string);
begin
  var hs1 := older.ToHashSet;
  var hs2 := newer.ToHashSet;
  
  foreach var f in newer do
    if hs1.Remove(f) then hs2.Remove(f);
  
  foreach var f in hs2.Sorted do
  begin
//    writeln(f);
    var f2 :=
      hs1.Where(f2->f2.StartsWith(f))
//      .Println
      .DefaultIfEmpty('')
      .MinBy(f2->f2.Length)
    ;
    
//    f2.Println;
//    writeln('-'*50);
    
    if not hs1.Remove(f2) then
      sw.WriteLine($'New func: "{f}"') else
      sw.WriteLine($'Upd func: "{f}" (removed trailing "{f2.SubString(f.Length)}")');
    
  end;
  
  foreach var f in hs1.Sorted do
    sw.WriteLine($'Rem func: "{f}"');
  
end;

begin
  try
    WriteAllText('VerDif.log', '', new System.Text.UTF8Encoding(true));
    sw := new System.IO.StreamWriter('VerDif.log', true, new System.Text.UTF8Encoding(true));
    
    var vrs := 
      ReadLines('versions order.dat')
      .Where(l->l.Contains('='))
      .Select(l->l.Split('=')[0].TrimEnd(#9))
      .ToList
    ;
    
    vrs
    .Tabulate(v->ReadAllFuncs($'{v} funcs.bin'))
    .Prepend(('-.-', new string[0]))
    .Pairwise((t1,t2)->( (t1[0],t2[0]), (t1[1],t2[1]) ))
    
  //  .Take(1)
  //  .PrintLines;
    
    .ForEach(t->
    begin
      sw.WriteLine($'Сравниваю версии {t[0][0]} и {t[0][1]}:');
      Compare(t[1][0],t[1][1]);
      if t[0][1]<>vrs.Last then
      begin
        sw.WriteLine;
        sw.WriteLine('='*50);
        sw.WriteLine;
      end;
    end);
    
    sw.Close;
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.