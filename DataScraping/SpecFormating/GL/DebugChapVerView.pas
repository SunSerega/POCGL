uses CoreFuncData;

var sw: System.IO.StreamWriter;

type
  Chapter = class
    id: integer;
    name: string;
    funcs := new List<string>;
    sub_ch := new List<Chapter>;
    top: Chapter;
    
    constructor(id: integer; name: string; top: Chapter);
    begin
      self.id := id;
      self.name := name;
      self.top := top;
    end;
    
    function GetFullId: sequence of integer;
    begin
      if top<>nil then yield sequence top.GetFullId;
      yield id;
    end;
    
    procedure Println(lvl: integer := 0);
    begin
      sw.Write($'{#9*lvl}{GetFullId.JoinIntoString(''.'')} : "{name}"');
      if funcs.Count<>0 then sw.Write($' [{funcs.JoinIntoString}]');
      sw.WriteLine;
      foreach var chap in sub_ch do
        chap.Println(lvl+1);
    end;
    
    public function ToString: string; override :=
    $'Chapter[{GetFullId.JoinIntoString(''.'')} : {name}]';
    
  end;

function ReadAllChaps(fname: string): List<Chapter>;
begin
  Result := new List<Chapter>;
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  
  loop br.ReadInt32 do
  begin
    var fd := CoreFuncDef.Load(br);
//    writeln(fd);
    if fd.chapter.Count=0 then fd.chapter += (0,'');
    
    var curr_lst := Result;
    var curr_head: Chapter := nil;
    foreach var cd in fd.chapter do
    begin
      var curr_heads := curr_lst.FindAll(chap-> (chap.id=cd[0]) and (chap.name=cd[1]) );
      if curr_heads.Count>1 then raise new System.ArgumentException($'multiple heads: {curr_heads.JoinIntoString}');
      
      if curr_heads.Count=0 then
      begin
        curr_head := new Chapter(cd[0],cd[1],curr_head);
        curr_lst += curr_head;
      end else
        curr_head := curr_heads.Single;
      
      curr_lst := curr_head.sub_ch;
    end;
    
    curr_head.funcs += fd.name;
  end;
  
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
    WriteAllText('ChapVer.log', '', new System.Text.UTF8Encoding(true));
    sw := new System.IO.StreamWriter('ChapVer.log', true, new System.Text.UTF8Encoding(true));
    
    var vrs := 
      ReadLines('versions order.dat')
      .Where(l->l.Contains('='))
      .Select(l->l.Split('=')[0].TrimEnd(#9))
      .ToList
    ;
    
    sw.WriteLine;
    foreach var v in vrs do
    begin
      sw.WriteLine($'OpenGL {v}');
      sw.WriteLine;
      
      foreach var chap in ReadAllChaps($'{v} funcs.bin') do
        chap.Println;
      
      if v<>vrs.Last then
      begin
        sw.WriteLine;
        sw.WriteLine('='*50);
      end;
      
    end;
    
    sw.Close;
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.