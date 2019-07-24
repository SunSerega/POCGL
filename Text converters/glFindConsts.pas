program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

const
  HeaderFile = 'C:\Users\Master in EngLiSH\Desktop\OpenGL-Registry\api\GL\glcorearb.h';
//  HeaderFile = 'C:\Users\Ко\Desktop\OpenGL-Registry-master\api\GL\glcorearb.h';

function ReadHeader: List<string>;
begin
  try
    
    Result :=
      ReadLines(HeaderFile)
      .Where(l->l.StartsWith('#define'))
      .ToList
    ;
    
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
      halt;
    end;
  end;
end;

var header := ReadHeader;
var err := false;

function FindConstVal(cname: string): string;
begin
  if not cname.StartsWith('GL_') then cname := 'GL_' + cname;
  var mask := $'#define {cname} ';
  var res := header.Where(l->l.StartsWith(mask)).ToList;
  
  if res.Count=1 then
  begin
    Result := res.Single;
  end else
  begin
    Result := '';
    err := true;
    
    if res.Count=0 then
      writeln($'значение {cname} не найдено') else
    begin
      writeln($'значений {cname} несколько:');
      res.PrintLines;
    end;
    
    writeln;
  end;
  
end;

begin
  try
    
    System.Windows.Forms.Clipboard.SetText(
      #13#10 +
      System.Windows.Forms.Clipboard.GetText
      .ToWords(#10,#13)
      .Select(l->l.Contains(' ')?l.Remove(l.IndexOf(' ')):l)
      .Where(l->l<>'')
      .Where(l->l.All(ch-> (ch in '_x') or ch.IsDigit or (ch.IsLetter and ch.IsUpper) ))
      .Select(FindConstVal)
      .JoinIntoString(#13#10)
    );
    
    System.Console.Beep;
    if err then
      readln else
//      Exec('gl format enum.exe')
    ;
    
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.