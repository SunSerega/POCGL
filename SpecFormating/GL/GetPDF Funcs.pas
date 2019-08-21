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
    var strategy := new SimpleTextExtractionStrategy;
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
    if not find_next_cache.ContainsKey(key) or ( (find_next_cache[key]<from) and (find_next_cache[key]<>-1) ) then
    begin
      Result := self.IndexOf(key,from);
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
    )+1;
    if ind1=0 then break;
    
    var ind2 := s.FindNext(ind1, '(', #10);
    if s[ind2+1]=#10 then continue;
    
    var f := s.Substring(ind1,ind2-ind1).Trim;
    if f='OpenGL 4.6' then
    begin
      ind1 := s.IndexOf(#10,ind1)+1;
      ind2 := s.IndexOf('(', ind1);
      f := s.Substring(ind1,ind2-ind1).Trim;
    end;
    ind1 := s.IndexOf(')', ind2);
    
    if f='void callback' then continue;
    
    yield sequence Arr(f)
      
      .SelectMany(fs-> MultiplyFunc(fs, 'f123g',                      '1 2 3') )
      .SelectMany(fs-> MultiplyFunc(fs, 'f234g',                      '2 3 4') )
      .SelectMany(fs-> MultiplyFunc(fs, 'f1234g',                     '1 2 3 4') )
      
      .SelectMany(fs-> MultiplyFunc(fs, 'fifg',                       'i f') )
      .SelectMany(fs-> MultiplyFunc(fs, 'ffdg',                       'f d') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fsfdg',                      's f d') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fifdg',                      'i f d') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fi uig',                     'i ui') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fif uig',                    'i f ui') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fifd uig',                   'i f d ui') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fb s ub usg',                'b s ub us') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fbsi ub us uig',             'b s i ub us ui') )
      .SelectMany(fs-> MultiplyFunc(fs, 'fbsifd ub us uig',           'b s i f d ub us ui') )
      
      .SelectMany(fs-> MultiplyFunc(fs, 'f2x3,3x2,2x4,4x2,3x4,4x3g',  '2x3 3x2 2x4 4x2 3x4 4x3') )
      
      .SelectMany(fs-> MultiplyFunc(fs, 'ClearBuffer?',               'ClearBufferfi') )
      .SelectMany(fs-> MultiplyFunc(fs, 'ClearNamedFramebuffer?',     'ClearNamedFramebufferfi') )
      .SelectMany(fs-> MultiplyFunc(fs, 'i v',                        'i_v') )
      .SelectMany(fs-> MultiplyFunc(fs, 'i64 v',                      'i64_v') )
      
      .Select(fs-> fs.Substring(fs.LastIndexOf(' ')+1).TrimStart('*') )
    ;
  end;
  
end;

procedure ProcessPfd(fname, v: string);
begin
  
  Otp($'Getting string for version {v}');
  var s := ReadPdfFile(fname).Remove(#13);
//  WriteAllText('test.txt', s, Encoding.UTF8);
  
  Otp($'Getting funcs for version {v}');
  var funcs :=
    GetAllFuncs(s)
    .Where(f->not (f in ['DrawArraysOneInstance', 'DrawElementsOneInstance', 'handle']) )
    .Distinct
//    .Sorted
    .ToList
  ;
  
//  funcs.PrintLines;
  
  Otp($'Saving funcs for version {v}');
  var bw := new System.IO.BinaryWriter(System.IO.File.Create($'SpecFormating\GL\{v} funcs.bin'));
  bw.Write(funcs.Count);
  foreach var f in funcs do bw.Write('gl'+f);
  bw.Close;
  
end;

begin
  try
    
    ProcessPfd('Reps\OpenGL-Registry\specs\gl\glspec46.core.pdf', '4.6');
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: Exception do writeln(e);
  end;
end.