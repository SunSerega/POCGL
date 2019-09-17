program prog;

function GetNRange(fn: string): sequence of integer;
begin
  case fn of
    'glVertex':     Result := Range(2,4);
    'glTexCoord':   Result := Range(1,4);
    'glNormal':     Result := Range(3,3);
    'glColor':      Result := Range(3,4);
    'glRasterPos':  Result := Range(2,4);
    'glIndex':      Result := Seq(0);
    'glRect':       Result := Seq(0);
    'glEvalCoord':  Result := Range(1,2);
    else raise new System.InvalidOperationException(fn);
  end;
end;

var AllTypes := Arr(
  ('b'+'',  'glbyte'),    // 0
  ('s'+'',  'glshort'),   // 1
  ('i'+'',  'glint'),     // 2
  ('ub',    'glubyte'),   // 3
  ('us',    'glushort'),  // 4
  ('ui',    'gluint'),    // 5
  ('f'+'',  'glfloat'),   // 6
  ('d'+'',  'gldouble')   // 7
);
function GetTRange(fn: string): sequence of (string, string);
begin
  case fn of
    'glVertex':     Result := Arr(1,2,6,7)  .Select(i->AllTypes[i]);
    'glTexCoord':   Result := Arr(1,2,6,7)  .Select(i->AllTypes[i]);
    'glNormal':     Result := Arr(0,1,2,6,7).Select(i->AllTypes[i]);
    'glColor':      Result := AllTypes;
    'glRasterPos':  Result := Arr(1,2,6,7)  .Select(i->AllTypes[i]);
    'glIndex':      Result := Arr(1,2,3,6,7).Select(i->AllTypes[i]);
    'glRect':       Result := Arr(1,2,6,7)  .Select(i->AllTypes[i]);
    'glEvalCoord':  Result := Arr(6,7)      .Select(i->AllTypes[i]);
    else raise new System.InvalidOperationException(fn);
  end;
end;

begin
  var sw := new System.IO.StreamWriter(System.IO.File.Create('core[generic].h'), new System.Text.UTF8Encoding(true));
  
  loop 3 do sw.WriteLine;
  
  foreach var fn in Arr('glVertex','glTexCoord','glNormal','glColor','glRasterPos','glIndex','glRect','glEvalCoord') do
  begin
    
    foreach var pc in GetNRange(fn) do
      foreach var pt in GetTRange(fn) do
        for var v := false to true do
        begin
          sw.Write('void ');
          sw.Write(fn);
          if pc<>0 then sw.Write(pc);
          sw.Write(pt[0]);
          if v then sw.Write('v');
          sw.Write('(');
          
          if v then
          begin
            sw.Write(pt[1]);
            sw.Write(' * ');
            sw.Write('v');
          end else
          for var i := 1 to Max(1,pc) do
          begin
            sw.Write(pt[1]);
            sw.Write(' ');
            sw.Write('v');
            sw.Write(i);
            if i<pc then sw.Write(', ');
          end;
          
          sw.Write(');');
          
          sw.WriteLine;
        end;
    
    sw.WriteLine;
  end;
  
  loop 1 do sw.WriteLine;
  
  sw.Close;
end.