uses MiscUtils in '..\..\Utils\MiscUtils.pas';
{$reference 'itextsharp.dll'}

uses iTextSharp.text.pdf;
uses iTextSharp.text.pdf.parser;
uses System.Text;

function ReadPdfFile(fname: string): string;
begin
  var sb := new StringBuilder;
  var r := new PdfReader(fname);
  
  for var page := 1 to r.NumberOfPages do
  begin
//    var strategy := new SimpleTextExtractionStrategy;
    var strategy := new LocationTextExtractionStrategy;
    var currentText := PdfTextExtractor.GetTextFromPage(r, page, strategy);
    
    currentText := Encoding.UTF8.GetString(ASCIIEncoding.Convert(Encoding.Default, Encoding.UTF8, Encoding.Default.GetBytes(currentText)));
    
    sb += currentText;
  end;
  
  r.Close;
  Result := sb.ToString;
end;

var find_next_cache: Dictionary<string, integer>;

function FindNext(self: string; from: integer; params keys: array of string); extensionmethod :=
  keys.Select(key->
    if not find_next_cache.ContainsKey(key) or ( (find_next_cache[key]<=from) and (find_next_cache[key]<>-1) ) then
    begin
      Result := self.IndexOf(key,from);
      if Result<>-1 then Result += key.Length;
      find_next_cache[key] := Result;
    end else
    begin
      Result := find_next_cache[key];
    end
  )
  .Where(ind->ind<>-1)
  .DefaultIfEmpty(-1)
  .Min
;

function MultiplyFunc(f, templ, repl: string): sequence of string;
begin
  if not f.Contains('{') then templ := templ.Replace('{','f').Replace('}','g');
  
  if f.Contains(templ) then
  begin
    foreach var r in repl.ToWords do
      yield f.Replace(templ, r);
  end else
    yield f;
  
end;

function GetAllFuncs(s: string): sequence of string;
begin
  var ind1 := 0;
  var res := new StringBuilder;
  find_next_cache := new Dictionary<string, integer>;
  
  while true do
  begin
    
    ind1 := s.FindNext(ind1,
      #10'void ',
      #10'enum ',
      #10'uint ',
      #10'sync ',
      #10'int ',
      #10'ubyte ',
      #10'boolean '
    );
    if ind1=-1 then break;
    
    var ind2 := s.FindNext(ind1, '(', #10)-1;
    if s[ind2+1]=#10 then continue;
    
    var f := s.Substring(ind1,ind2-ind1).Trim;
    ind1 := s.IndexOf(')', ind2);
    
    if f in [
      '',
      'DrawArraysOneInstance',
      'DrawElementsOneInstance',
      'handle' ,
      'c=',
      'c/',
      'callback',
      'ptrbits Sync object handle'
    ] then continue;
    
    yield sequence Arr(f)
      
      .SelectMany(fs-> MultiplyFunc(fs, '{12}',                       '1 2')                      )
      .SelectMany(fs-> MultiplyFunc(fs, '{23}',                       '2 3')                      )
      .SelectMany(fs-> MultiplyFunc(fs, '{34}',                       '3 4')                      )
      .SelectMany(fs-> MultiplyFunc(fs, '{123}',                      '1 2 3')                    )
      .SelectMany(fs-> MultiplyFunc(fs, '{234}',                      '2 3 4')                    )
      .SelectMany(fs-> MultiplyFunc(fs, '{1234}',                     '1 2 3 4')                  )
      .SelectMany(fs-> MultiplyFunc(fs, '{1,2,3,4}',                  '1 2 3 4')                  )
      
      .SelectMany(fs-> MultiplyFunc(fs, '{f}',                        'f')                        )
      .SelectMany(fs-> MultiplyFunc(fs, '{if}',                       'i f')                      )
      .SelectMany(fs-> MultiplyFunc(fs, '{fd}',                       'f d')                      )
      .SelectMany(fs-> MultiplyFunc(fs, '{sfd}',                      's f d')                    )
      .SelectMany(fs-> MultiplyFunc(fs, '{ifd}',                      'i f d')                    )
      .SelectMany(fs-> MultiplyFunc(fs, '{i ui}',                     'i ui')                     )
      .SelectMany(fs-> MultiplyFunc(fs, '{u ui}',                     'i ui')                     )
      .SelectMany(fs-> MultiplyFunc(fs, '{sifd}',                     's i f d')                  )
      .SelectMany(fs-> MultiplyFunc(fs, '{ifds}',                     'i f d s')                  )
      .SelectMany(fs-> MultiplyFunc(fs, '{if ui}',                    'i f ui')                   )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsifd}',                    'b s i f d')                )
      .SelectMany(fs-> MultiplyFunc(fs, '{uiusf}',                    'ui us f')                  )
      .SelectMany(fs-> MultiplyFunc(fs, '{ifd ui}',                   'i f d ui')                 )
      .SelectMany(fs-> MultiplyFunc(fs, '{sifdub}',                   's i f d ub')               )
      .SelectMany(fs-> MultiplyFunc(fs, '{ui us f}',                  'ui us f')                  )
      .SelectMany(fs-> MultiplyFunc(fs, '{bs ubus}',                  'b s ub us')                )
      .SelectMany(fs-> MultiplyFunc(fs, '{sifd ub}',                  's i f d ub')               )
      .SelectMany(fs-> MultiplyFunc(fs, '{b s ub us}',                'b s ub us')                )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsiubusui}',                'b s i ub us ui')           )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsi ubusui}',               'b s i ub us ui')           )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsifdubusui}',              'b s i f d ub us ui')       )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsi ub us ui}',             'b s i ub us ui')           )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsifd ubusui}',             'b s i f d ub us ui')       )
      .SelectMany(fs-> MultiplyFunc(fs, '{bsifd ub us ui}',           'b s i f d ub us ui')       )
      
      .SelectMany(fs-> MultiplyFunc(fs, '1,2,3,4',                    '1 2 3 4')                  )
      
      .SelectMany(fs-> MultiplyFunc(fs, '{2x3,3x2,2x4,4x2,3x4,4x3}',  '2x3 3x2 2x4 4x2 3x4 4x3')  )
      
      .SelectMany(fs-> MultiplyFunc(fs, 'ClearBuffer?',               'ClearBufferfi')            )
      .SelectMany(fs-> MultiplyFunc(fs, 'ClearNamedFramebuffer?',     'ClearNamedFramebufferfi')  )
      
      
      .SelectMany(fs-> MultiplyFunc(fs, 'i v',                        'i_v')                      )
      .SelectMany(fs-> MultiplyFunc(fs, 'i64 v',                      'i64_v')                    )
      
      .SelectMany(fs-> MultiplyFunc(fs, 'Mo de',                      'Mode')                     )
      .SelectMany(fs-> MultiplyFunc(fs, 'Zo om',                      'Zoom')                     )
      .SelectMany(fs-> MultiplyFunc(fs, 'Co ord',                     'Coord')                    )
      .SelectMany(fs-> MultiplyFunc(fs, 'Bo olean',                   'Boolean')                  )
      .SelectMany(fs-> MultiplyFunc(fs, 'TexCo ord',                  'TexCoord')                 )
      .SelectMany(fs-> MultiplyFunc(fs, 'Viewp ort',                  'Viewport')                 )
      
      .SelectMany(fs-> MultiplyFunc(fs, 'Bu'#0'er',                   'Buffer')                   )
      .SelectMany(fs-> MultiplyFunc(fs, 'O'#0'set',                   'Offset')                   )
      
      .Select(fs->fs.TrimStart('*'))
      .Select(fs-> fs.StartsWith('gl')?fs.SubString(2):fs )
    ;
  end;
  
end;

procedure ProcessPfd(fname, v: string);
begin
  
  Otp($'Formating version {v}');
  var s := ReadPdfFile(fname).Remove(#13);
  
//  WriteAllText($'test {v}.txt', s, Encoding.UTF8);
//  Halt;
  
  var funcs :=
    GetAllFuncs(s)
    .Distinct
    .Sorted
    .ToList
  ;
  
//  funcs.PrintLines;
  
  var bw := new System.IO.BinaryWriter(System.IO.File.Create($'SpecFormating\GL\{v} funcs.bin'));
  bw.Write(funcs.Count);
  foreach var f in funcs do bw.Write('gl'+f);
  bw.Close;
  
//  Halt;
end;

begin
  try
    
    ReadLines('SpecFormating\GL\versions order.dat')
    .Where(l->l.Contains('='))
    .Select(l->l.Split('='))
    .Where(l->l[1]<>'') // только в этой программе важно, для 1.1 файл не .pdf
    .Select(l->(l[0].TrimEnd(#9),l[1]))
//    .Skip(3)
    .ForEach(l-> ProcessPfd($'Reps\OpenGL-Registry\specs\gl\glspec{l[1]}.pdf', l[0]) );
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.