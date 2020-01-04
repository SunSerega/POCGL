uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';
{$reference 'itextsharp.dll'}
uses CoreFuncData;

uses iTextSharp.text.pdf;
uses iTextSharp.text.pdf.parser;
uses System.Text;
uses System.Threading;

type
  ThrVars = static class
    [System.ThreadStatic] static find_next_cache: Dictionary<string, integer>;
    [System.ThreadStatic] static chapters_def: integer;
  end;
  

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

function FindNext(self: string; from: integer; params keys: array of string); extensionmethod :=
  keys.Select(key->
    if not ThrVars.find_next_cache.ContainsKey(key) or ( (ThrVars.find_next_cache[key]<=from) and (ThrVars.find_next_cache[key]<>-1) ) then
    begin
      Result := self.IndexOf(key,from);
      if Result<>-1 then Result += key.Length;
      ThrVars.find_next_cache[key] := Result;
    end else
    begin
      Result := ThrVars.find_next_cache[key];
    end
  )
  .Where(ind->ind<>-1)
  .DefaultIfEmpty(-1)
  .Min
;

function DistinctByLast<T1,T2>(self: sequence of T1; key_selector: T1->T2): sequence of T1; extensionmethod;
begin
  var res := new List<T1>;
  var d := new Dictionary<T2,T1>;
  
  foreach var a in self do
  begin
    var key := key_selector(a);
    var prev: T1;
    if d.TryGetValue(key, prev) then
      res.Remove(prev);
    d[key] := a;
    res += a;
  end;
  
  Result := res;
end;

function DistinctBy<T1,T2>(self: sequence of T1; key_selector: T1->T2): sequence of T1; extensionmethod;
begin
  var prev := new HashSet<T2>;
  
  foreach var a in self do
    if prev.Add(key_selector(a)) then
      yield a;
  
end;



function FindChapterIndex(text: string; chapter: List<(integer,string)>): integer;
begin
  if chapter.Count=0 then exit;
  
  var chap_name := chapter.Select(t->t[0]).JoinIntoString('.');
  if chapter.Count=1 then
    chap_name := $'Chapter {chap_name}{#10}' else
    chap_name := $'{chap_name} {chapter.Last[1]}';
  
  Result := text.LastIndexOf(chap_name);
  if Result<ThrVars.chapters_def then raise new System.InvalidOperationException($'chapter "{chap_name.Trim}" not found');
end;

function FindAllChapters(text: string): sequence of List<(integer,string)>;
begin
  var names := new List<string>;
  
  var ind1 := text.IndexOf('Contents'#10)+'Contents'#10.Length;
  var ind2 := text.IndexOf('A Invariance');
  ThrVars.chapters_def := ind2;
  foreach var l in text.Substring(ind1,ind2-ind1).ToWords(#10) do
  begin
    if not l[1].IsDigit then continue;
    
    ind1 := l.IndexOf(' ');
    ind2 := l.lastIndexOf(' ');
    if ind1=ind2 then continue;
    
//    Otp(l);
    
    var ch_val := l.Remove(ind1).ToWords('.').ConvertAll(s->s.ToInteger);
    var ch_name :=
      l.Substring(ind1+1,ind2-ind1-1)
      .TrimEnd(' .'.ToArray)
    ;
    if ch_name='' then continue;
    
//    Otp($'{ch_val.JoinIntoString(''.'')} : {ch_name}');
    
    var req_l := ch_val.Length-1;
    if names.Count<req_l then raise new System.InvalidOperationException('chapters out of order');
    if names.Count>req_l then names.RemoveRange(req_l,names.Count-req_l);
    
    names += ch_name;
    yield ch_val.ZipTuple(names).ToList;
  end;
  
  yield new List<(integer,string)>;
end;



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

function GetAllFuncs(s: string): sequence of CoreFuncDef;
begin
  var ind1 := 0;
  var res := new StringBuilder;
  ThrVars.find_next_cache := new Dictionary<string, integer>;
  
  var append_ind := s.LastIndexOf('A'#10'Invariance');
  if append_ind=-1 then raise new System.InvalidOperationException('Appendix start not found');
  
  var chap_enum: IEnumerator<List<(integer,string)>> := FindAllChapters(s).GetEnumerator;
  if not chap_enum.MoveNext then raise new System.InvalidOperationException('no chapters found');
  var curr_chapter := chap_enum.Current;
  var curr_chapter_ind := FindChapterIndex(s, curr_chapter);
  if not chap_enum.MoveNext then raise new System.InvalidOperationException('only one chapter found');
  var next_chapter := chap_enum.Current;
  var next_chapter_ind := FindChapterIndex(s, next_chapter);
  
//  Otp( next_chapter );
//  Otp( next_chapter_ind );
//  Otp( '='*50 );
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
//    Otp(ind1);
    
    var ind2 := s.FindNext(ind1, '(', #10)-1;
    if s[ind2+1]=#10 then continue;
    
    if ind1>append_ind then
    begin
      if curr_chapter.Count<>0 then curr_chapter := new List<(integer,string)>;
    end else
    if next_chapter_ind <> -1 then
      while next_chapter_ind<ind1 do
      begin
        curr_chapter := next_chapter;
        curr_chapter_ind := next_chapter_ind;
        
        if not chap_enum.MoveNext then
        begin
          next_chapter_ind := -1;
//          Otp('done with chapters');
          break;
        end;
        
        next_chapter := chap_enum.Current;
        next_chapter_ind := FindChapterIndex(s, next_chapter);
        
//        Otp( next_chapter );
//        Otp(( next_chapter_ind, ind1, s.Substring(ind1-30,ind2-ind1+60) ));
//        Otp( '='*50 );
      end;
    
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
      .Select(fs-> fs.StartsWith('gl')?fs:'gl'+fs )
      .Select(fs->
      begin
        Result := new CoreFuncDef(fs);
        Result.chapter := curr_chapter;
      end)
    ;
  end;
  
end;



procedure ProcessPdf(fname, v: string);
begin
  var Main_ToDo := 0; //ToDo в заголовке описывающем разделы - не должны быть #0-ов. Ну и лишние пробелы тоже убрать
  
  Otp($'Formating version {v}');
//  lock output do Writeln($'%%%Formating version {v}');
  var s :=
    ReadPdfFile(fname).Remove(#13)
    .Replace('Chapter', 'Chapter ').Replace('  ', ' ')
    
    .Replace('9.3 Feedback Loops Between Textures and the Frame-'#10'buffer',   '9.3 Feedback Loops Between Textures and the Framebuffer')
    .Replace('9.5 Mapping between Pixel and Element in Attached Im-'#10'age',   '9.5 Mapping between Pixel and Element in Attached Image')
    .Replace('9.6 Conversion to Framebuffer-Attachable Image Com-'#10'ponents', '9.6 Conversion to Framebuffer-Attachable Image Components')
    
    .Replace('10.10Conditional Rendering',  '10.10 Conditional Rendering')
    .Replace('10.10Submission Queries',     '10.10 Submission Queries')
    .Replace('SegmentFeatures',             'Segment Features')
    
    .Replace('Sp eci'#0'cation',            'Specication')
    .Replace('O'#0'set',                    'Offset')
    .Replace('bu'#0'er',                    'buffer')
    .Replace('Bu'#0'er',                    'Buffer')
    .Replace('Mini'#0'cation',              'Minification')
    .Replace('Magni'#0'cation',             'Magnification')
    
    .Replace('Speci?cation',                'Specification')
    .Replace('Mini?cation',                 'Minification')
    .Replace('Magni?cation',                'Magnification')
    
    .Replace('Intro duction',               'Introduction')
    .Replace('Op enGL',                     'OpenGL')
    .Replace('Op eration',                  'Operation')
    .Replace('Ob jects',                    'Objects')
    .Replace('Co ordinate',                 'Coordinate')
    .Replace('Viewp ort',                   'Viewport')
    .Replace('Pro cessing',                 'Processing')
    .Replace('Mo des',                      'Modes')
    .Replace('for W riting',                'for Writing')
    .Replace('Up dates',                    'Updates')
    .Replace('Sp ecial',                    'Special')
    
//    .Replace('Introduction',                'Introduction')
//    .Replace('Introduction',                'Introduction')
//    .Replace('Introduction',                'Introduction')
//    .Replace('Introduction',                'Introduction')
//    .Replace('Introduction',                'Introduction')
    
  ;
  
  System.IO.Directory.CreateDirectory(GetFullPath($'..\formated pdfs', GetEXEFileName));
  WriteAllText(GetFullPath($'..\formated pdfs\test {v}.txt', GetEXEFileName), s, Encoding.UTF8);
//  Halt;
  
  var funcs :=
    GetAllFuncs(s)
    .DistinctByLast(f-> f.name + (f.chapter.Count=0?'*':'') )
    .DistinctBy(f-> f.name )
//    .OrderBy(f->f.name) // это ломает порядок разделов справки. правда, это не смертельно так то...
    .ToList
  ;
  
//  funcs.PrintLines;
  
  var bw := new System.IO.BinaryWriter(System.IO.File.Create(GetFullPath($'..\{v} funcs.bin',GetEXEFileName)));
  bw.Write(funcs.Count);
  foreach var f in funcs do f.Save(bw);
  bw.Close;
  
//  readln;
//  Halt;
  
  Otp($'Done with version {v}');
//  lock output do Writeln($'%%%Done with version {v}');
end;



begin
  try
    
    ReadLines(GetFullPath('..\versions order.dat',GetEXEFileName))
    .Where(l->l.Contains('='))
    .Select(l->l.Split('='))
    .Where(l->l[1]<>'') // только в этой программе важно, для 1.1 файл не .pdf
    .Select(l->(l[0].TrimEnd(#9),l[1]))
    
//    .TakeLast(1)
//    .Skip(3)
    
    .Select(l->ProcTask(()->
      ProcessPdf(GetFullPath($'..\..\..\Reps\OpenGL-Registry\specs\gl\glspec{l[1]}.pdf',GetEXEFileName), l[0])
    )).CombineAsyncTask
    .SyncExec;
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
    on e: Exception do ErrOtp(e);
  end;
end.