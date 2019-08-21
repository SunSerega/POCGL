uses MiscUtils in '..\..\Utils\MiscUtils.pas';

const lf = 'Fz';
const lt = 'FC';
const lcheck = 'FC(\()';

function ExtractActualText(s: string): string;
begin
//  Result := s;
//  exit;
  
  var ind1 := 0;
  var res := new StringBuilder;
  
  while true do
  begin
    
    ind1 := s.IndexOf('(', ind1)+1;
    if ind1=0 then break;
    
    var ind2 := s.IndexOf(')', ind1);
    
    res += s.Substring(ind1,ind2-ind1);
  end;
  
  Result := res.ToString;
end;

function GetFuncNames(s: string): sequence of string;
begin
  var ind1 := 0;
  var ind2 := 0;
  
  while true do
  begin
    
    ind1 := s.IndexOf(lf,ind1);
    if ind1=-1 then break;
    ind1 += lf.Length;
    
    var cross_def := ind2>ind1;
    if cross_def then continue;
    
    ind2 := s.IndexOf(lt,ind1);
    if not s.Substring(ind2).StartsWith(lcheck) then continue;
    
    var fn := ExtractActualText(s.Substring(ind1,ind2-ind1));
    fn := fn.TrimStart('*');
    
    yield fn;
  end;
  
end;

function MultiplyFunc(s: string): sequence of string;
begin
  if not s.Contains('{') then
  begin
    yield s;
    exit;
  end;
  
  if s.Contains('{12}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{12}', '1'));
    yield sequence MultiplyFunc(s.Replace('{12}', '2'));
  end else
  
  if s.Contains('{34}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{34}', '3'));
    yield sequence MultiplyFunc(s.Replace('{34}', '4'));
  end else
  
  if s.Contains('{234}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{234}', '2'));
    yield sequence MultiplyFunc(s.Replace('{234}', '3'));
    yield sequence MultiplyFunc(s.Replace('{234}', '4'));
  end else
  
  if s.Contains('{1234}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{1234}', '1'));
    yield sequence MultiplyFunc(s.Replace('{1234}', '2'));
    yield sequence MultiplyFunc(s.Replace('{1234}', '3'));
    yield sequence MultiplyFunc(s.Replace('{1234}', '4'));
  end else
  
  if s.Contains('{bsifdubusui}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'b'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 's'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'i'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'f'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'd'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'ub'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'us'));
    yield sequence MultiplyFunc(s.Replace('{bsifdubusui}', 'ui'));
  end else
  
  if s.Contains('{fd}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{fd}', 'f'));
    yield sequence MultiplyFunc(s.Replace('{fd}', 'd'));
  end else
  
  if s.Contains('{if}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{if}', 'i'));
    yield sequence MultiplyFunc(s.Replace('{if}', 'f'));
  end else
  
  if s.Contains('{ifd}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{ifd}', 'i'));
    yield sequence MultiplyFunc(s.Replace('{ifd}', 'f'));
    yield sequence MultiplyFunc(s.Replace('{ifd}', 'd'));
  end else
  
  if s.Contains('{uiusf}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{uiusf}', 'ui'));
    yield sequence MultiplyFunc(s.Replace('{uiusf}', 'us'));
    yield sequence MultiplyFunc(s.Replace('{uiusf}', 'f'));
  end else
  
  if s.Contains('{sifdub}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{sifdub}', 's'));
    yield sequence MultiplyFunc(s.Replace('{sifdub}', 'i'));
    yield sequence MultiplyFunc(s.Replace('{sifdub}', 'f'));
    yield sequence MultiplyFunc(s.Replace('{sifdub}', 'd'));
    yield sequence MultiplyFunc(s.Replace('{sifdub}', 'ub'));
  end else
  
  if s.Contains('{bsifd}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{bsifd}', 'b'));
    yield sequence MultiplyFunc(s.Replace('{bsifd}', 's'));
    yield sequence MultiplyFunc(s.Replace('{bsifd}', 'i'));
    yield sequence MultiplyFunc(s.Replace('{bsifd}', 'f'));
    yield sequence MultiplyFunc(s.Replace('{bsifd}', 'd'));
  end else
  
  if s.Contains('{sifd}') then
  begin
    yield sequence MultiplyFunc(s.Replace('{sifd}', 's'));
    yield sequence MultiplyFunc(s.Replace('{sifd}', 'i'));
    yield sequence MultiplyFunc(s.Replace('{sifd}', 'f'));
    yield sequence MultiplyFunc(s.Replace('{sifd}', 'd'));
  end else
  
    yield s;
  
end;

begin
  try
    var s :=
      ReadAllText(GetFullPath('Reps\OpenGL-Registry\specs\gl\glspec11.ps'))
      .Replace('FB(f)','({)')
      .Replace('FB(g)','(})')
      .Replace('FB(gf)', '(}{)')
      .Replace('\013','ff')
    ;
    
    var funcs :=
      GetFuncNames(s)
      .Where(n->not (n in ['p', 'p0', 'dcli', 'scli']))
      .SelectMany(n->MultiplyFunc(n))
      .Distinct
      .ToList
    ;
    
    var bw := new System.IO.BinaryWriter(System.IO.File.Create('SpecFormating\GL\1.1 funcs.bin'));
    bw.Write(funcs.Count);
    foreach var f in funcs do bw.Write(f);
    bw.Close;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.