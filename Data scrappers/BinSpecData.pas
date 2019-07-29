unit BinSpecData;

{$region Misc}

function FindAllIndexes(self, s: string): sequence of integer; extensionmethod;
begin
  var ind := 0;
  
  while true do
  begin
    ind := self.IndexOf(s, ind);
    if ind=-1 then break;
    
    ind := ind+s.Length;
    if s.EndsWith(#10) then ind -= 1;
    
    yield ind;
  end;
  
end;

function Distinct<T1,T2>(self: sequence of T1; selector: T1->T2): sequence of T1; extensionmethod;
begin
  var prev := new HashSet<T2>;
  foreach var a in self do
    if prev.Add(selector(a)) then
      yield a;
end;

function WherePrev<T>(self: sequence of T; predicate: T->boolean): sequence of T; extensionmethod;
begin
  var enm := self.GetEnumerator;
  if not enm.MoveNext then exit;
  
  var prev := enm.Current;
  yield prev;
  
  while enm.MoveNext do
  begin
    var a := enm.Current;
    if predicate(prev) then yield a;
    prev := a;
  end;
  
end;

function FindBrackets(self: string; from: integer): (integer,integer); extensionmethod;
begin
  var ind1 := self.IndexOf('(',from);
  if ind1=-1 then exit;
  
  var ind2 := self.IndexOf(')',ind1+1);
  if ind2=-1 then raise new System.ArgumentException(self);
  if self.IndexOf('(',ind1+1, ind2-ind1-1) <> -1 then
  begin
    var t := self.FindBrackets(ind1+1);
    ind2 := self.IndexOf(')',t[1]+1);
  end;
  if ind2=-1 then raise new System.ArgumentException(self);
  
  Result := (ind1,ind2);
end;

{$endregion}

type
  
  {$region Chapters}
  
  {$region Curr list}
  
  // Addition to ***
  // Additions to ***
  // Modifications to ***
  //=== SpecModifications
  // 
  // Name String/Name Strings         === ExtStrings
  // New Procedures and Functions[:]  === NewFuncs
  // Contacts/Contact                 === AuthorContacts
  // Contributors                     === ContributorsList
  // Errors                           === Errors
  // Issues                           === Issues
  // New Keywords                     === NewKeywords
  // New State                        === NewState
  // New Tokens:/New Tokens***        === NewTokens
  // New Types                        === NewTypes
  // Notice                           === Notice
  // Status                           === Status
  // Version:/Version                 === Version
  
  {$endregion Curr list}
  
  {$region TODO Full list}
  
  // У многих заголовков может быть рандомное ":" на конце. У них *** стоит без пробела перед ним
  
  /// (N1,N2,N3)=Chapt# ; (AN1,AN2)=Appendix# ; (V1,V2,V3)=GLVersion ; (SpecChaptName)=ChapterName ; ProfType=[Compatibility,Core]
  /// V1,V2 и AN1 могут быть "X", что значит их неопределённость
  /// N1 может быть "???", что так же значит неопределённость
  //
  // Addition to Chapter {N1} of OpenGL {V1}.{V2} Specification ({SpecChaptName})
  // Additions to Chapter {N1} of {V1}.{V2} ***
  // Additions to Chapter {N1} of the GL ***
  // Additions to Chapter {N1} of the GLX {V1}.{V2} ***
  // Additions to Chapter {N1} of the OpenGL {V1}.{V2} ***
  // Additions to Chapter {N1} of the OpenGL ES {V1}.{V2} ***
  // Additions to {N1}.{N2}.{N3} {SpecChaptName}
  // Additions to Chapter {N1} of the OpenGL Core Profile Specification, Version 4.3
  // Additions to{\n}Chapter {N} of the OpenGL ES {V1}.{V2} Specification ({SpecChaptName}) /// Строк с индентификаторами чаптеров - много. Этот бред только в "EXT\EXT_color_buffer_float.txt"
  // Additions to Chapter 1-11 of the OpenGL ES 3.2
  // Additions to Chapter 13.7, Polygons of the OpenGL ES 3.2 Specification
  // Additions to Chapter 14 (Programmable Fragment Processing) of the OpenGL ES 3.2 Specification
  // Additions to Chapter 14.2.2, Shader Inputs of the OpenGL ES 3.2 Specification
  //
  // Additions to Appendix {AN1}***
  // Additions to Appendix A.3 Invariance Rules
  // Additions to Appendix {AN1} of the OpenGL {V1}.{V2} ***
  // Additions to Appendix {AN1} of the OpenGL {V1}.{V2}.{V3} ***
  // Additions to Appendix {AN1} of the OpenGL ES {V1}.{V2} ***
  // Additions to Appendices A through G of the OpenGL {V1}.{V2} Specification
  //
  //=== OGL_SpecAddition
  
  // "Additions to AMD_compressed_ATC_texture and AMD_compressed_3DC_texture
  //=== Ext_SpecAddition
  
  /// (N1,N2,N3)=Chapt# (V1,V2,V3)=GLVersion ; (SpecChaptName)=ChapterName ; ProfType=[Compatibility,Core]
  // Additions to Chapter {N1} of the OpenGL Shading Language {V1}.{V2} ***
  // Additions to Chapter {N1} of the OpenGL Shading Language {V1}.{V2}.{V3} ***
  // Additions to Appendix A (Looking up Paths in Trees) of the OpenGL Shading Language 1.50 Specification
  //=== GLSL_SpecAddition
  
  // "Addendum: Using this extension." === Examples
  // "TODO", "TODO:" === ToDo
  
  {$endregion TODO Full list}
  
  {$region Chapter types}
  
  ExtSpecChapter = abstract class
    header_end: string;
    contents: string;
    
    constructor(s: string);
    begin
      s := s.Trim(' ');
      var ind := s.IndexOf(#10);
      self.header_end := s.Remove(ind).Trim(#10' '.ToArray);
      self.contents := s.Substring(ind+1).Trim(#10' '.ToArray);
    end;
    
  end;
  
  SpecModificationsChapter = class(ExtSpecChapter)
    
  end;
  
  ExtStringsChapter = class(ExtSpecChapter)
    
    strings: array of string;
    
    constructor(s: string);
    begin
      inherited Create(s);
      self.strings :=
        contents
        .Split(#10)
        .Select(s->s.Trim(' '))
        .Where(s->s<>'')
        .Where(s->s.All(ch->  ch.IsDigit or ch.IsLetter or (ch='_')  ))
        .ToArray;
    end;
    
  end;
  
  NewFuncsChapter = class(ExtSpecChapter)
    funcs := new List<(string,string)>;
    
    static function TryCreate(s: string): NewFuncsChapter;
    begin
      Result := new NewFuncsChapter(s);
      
      var last_ind := 0;
      while true do
      begin
        var t := s.FindBrackets(last_ind);
        if t=nil then break;
        last_ind := t[1]+1;
        
        if s.IndexOf('.', t[0]+1, t[1]-t[0]-1) <> -1 then continue; // в скобках бывают комментарии. Благо, их можно отличить - у них в конце точка
        
        var name_ind := s.LastIndexOfAny(' *'.ToArray,t[0]-1)+1;
        if name_ind=-1 then raise new System.ArgumentException(s);
        var func_name := s.Substring(name_ind, t[0]-name_ind);
        while s[name_ind] in ' *' do name_ind -= 1;
        
        var f_ind := s.LastIndexOf(' ',name_ind-1)+1; // даже если вернёт -1, это вполне устраивает как ответ
        
        var func_text := s.Substring(f_ind, t[1]+1-f_ind);
        func_text := func_text.Replace(#10,' ');
        while func_text.Contains('  ') do func_text := func_text.Replace('  ',' ');
        
        Result.funcs += ( func_name, func_text );
      end;
      
      if Result.funcs.Count=0 then Result := nil;
    end;
    
  end;
  
  AuthorContactsChapter = class(ExtSpecChapter)
    
  end;
  
  ContributorsListChapter = class(ExtSpecChapter)
    
  end;
  
  ErrorsChapter = class(ExtSpecChapter)
    
  end;
  
  IssuesChapter = class(ExtSpecChapter)
    
  end;
  
  NewKeywordsChapter = class(ExtSpecChapter)
    
  end;
  
  NewStateChapter = class(ExtSpecChapter)
    
  end;
  
  NewTokensChapter = class(ExtSpecChapter)
    
  end;
  
  NewTypesChapter = class(ExtSpecChapter)
    
  end;
  
  NoticeChapter = class(ExtSpecChapter)
    
  end;
  
  StatusChapter = class(ExtSpecChapter)
    
  end;
  
  VersionChapter = class(ExtSpecChapter)
    
  end;
  
  {$endregion Chapter types}
  
  {$endregion Chapters}
  
  ExtSpec = class
    fname: string;
    
    SpecModifications := new List<SpecModificationsChapter>;
    ExtStrings:       ExtStringsChapter := nil;
    NewFuncs:         NewFuncsChapter := nil;
    AuthorContacts:   AuthorContactsChapter := nil;
    ContributorsList: ContributorsListChapter := nil;
    Errors:           ErrorsChapter := nil;
    Issues            := new List<IssuesChapter>; // иногда одна (обычно первая) из секций говорит что секция перенесена, но есть файлы и с 2 секциями
    NewKeywords:      NewKeywordsChapter := nil;
    NewState:         NewStateChapter := nil;
    NewTokens         := new List<NewTokensChapter>; // бывают с приписками WGL/GLX
    NewTypes:         NewTypesChapter := nil;
    Notice:           NoticeChapter := nil;
    Status:           StatusChapter := nil;
    Version:          VersionChapter := nil;
    
    
    
    static function InitFromFile(fname: string): ExtSpec;
    begin
      var spec_text := ReadAllText(fname).Remove(#13).Replace(#9,' '*4);
      while spec_text.Contains(' '#10) do spec_text := spec_text.Replace(' '#10, #10); //ToDo переместить в скачивающую программу
      
      // у незаконченных расширений - криво прописана спецификация (не приведена в общий вид с остальными расширениями)
      if spec_text.Split(#10).Any(l->l.StartsWith('XXX')) then exit;
      
      // OES\OES_stencil_wrap.txt
      // SGI\akeley_future_extensions.txt
      //В этих файлах не хранятся расширения. У всех расширений есть этот раздел:
      if not spec_text.Contains('Name String') then exit;
      
      Result := new ExtSpec;
      Result.fname := fname;
//      writeln(fname);
      
      
      
      var inds := new List<(string, integer)>;
      
      {$region inds fill}
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Addition to '                    ).Select(ind->('SpecModifications', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Additions to '                   ).Select(ind->('SpecModifications', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Modifications to '               ).Select(ind->('SpecModifications', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Name String'#10                  ).Select(ind->('ExtStrings', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Name Strings'#10                 ).Select(ind->('ExtStrings', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedures and Functions'#10 ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedures and Functions:'#10).Select(ind->('NewFuncs', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Contact'#10                      ).Select(ind->('AuthorContacts', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Contacts'#10                     ).Select(ind->('AuthorContacts', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Contributors'#10                 ).Select(ind->('ContributorsList', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Errors'#10                       ).Select(ind->('Errors', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Issues'#10                       ).Select(ind->('Issues', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Keyword'#10                  ).Select(ind->('NewKeywords', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New State'#10                    ).Select(ind->('NewState', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Tokens:'#10                  ).Select(ind->('NewTokens', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Tokens'                      ).Select(ind->('NewTokens', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Types'#10                    ).Select(ind->('NewTypes', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Notice'#10                       ).Select(ind->('Notice', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Status'#10                       ).Select(ind->('Status', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Version:'#10                     ).Select(ind->('Version', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Version'#10                      ).Select(ind->('Version', ind)));
      
      {$endregion inds fill}
      
      // special funcs
      var sf1 := fname.EndsWith('EXT_pixel_buffer_object.txt'); // в этом файле 2 статуса, примерно одинаковых
      
      foreach var p in
        inds.OrderBy(t->t[1])
        .WherePrev(t->
        begin
          case t[0] of
            
            'SpecModifications': spec_text.IndexOf(' or',t[1],spec_text.IndexOf(#10,t[1])-t[1]);
            
            else Result := true;
          end;
        end)
        .Distinct(t->spec_text.IndexOf(#10,t[1]))
        .Append(nil).Pairwise do
      begin
        var ind1 := p[0][1];
        var ind2: integer;
        if p[1]=nil then
          ind2 := spec_text.Length else
        begin
          ind2 := p[1][1];
          ind2 := spec_text.IndexOf(#10,ind2);
          ind2 := spec_text.LastIndexOf(#10,ind2-1)+1;
        end;
        var chapt_contents := spec_text.Substring(ind1, ind2-ind1);
//        writeln(p[0][0]);
        
        case p[0][0] of
          
          'SpecModifications':                                      Result.SpecModifications  += SpecModificationsChapter .Create   (chapt_contents);
          'ExtStrings':       if (Result.ExtStrings      =nil) then Result.ExtStrings         := ExtStringsChapter        .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple ExtStrings chapters in {fname}');
          'NewFuncs':         if (Result.NewFuncs        =nil) then Result.NewFuncs           := NewFuncsChapter          .TryCreate(chapt_contents) else raise new System.InvalidOperationException($'multiple NewFuncs chapters in {fname}');
          'AuthorContacts':   if (Result.AuthorContacts  =nil) then Result.AuthorContacts     := AuthorContactsChapter    .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple AuthorContacts chapters in {fname}');
          'ContributorsList': if (Result.ContributorsList=nil) then Result.ContributorsList   := ContributorsListChapter  .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple ContributorsList chapters in {fname}');
          'Errors':           if (Result.Errors          =nil) then Result.Errors             := ErrorsChapter            .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple Errors chapters in {fname}');
          'Issues':                                                 Result.Issues             += IssuesChapter            .Create   (chapt_contents);
          'NewKeywords':      if (Result.NewKeywords     =nil) then Result.NewKeywords        := NewKeywordsChapter       .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple NewKeywords chapters in {fname}');
          'NewState':         if (Result.NewState        =nil) then Result.NewState           := NewStateChapter          .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple NewState chapters in {fname}');
          'NewTokens':                                              Result.NewTokens          += NewTokensChapter         .Create   (chapt_contents);
          'Notice':           if (Result.Notice          =nil) then Result.Notice             := NoticeChapter            .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple Notice chapters in {fname}');
          'Status':           if (Result.Status=nil)    or sf1 then Result.Status             := StatusChapter            .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple Status chapters in {fname}');
          'Version':          if (Result.Version         =nil) then Result.Version            := VersionChapter           .Create   (chapt_contents) else raise new System.InvalidOperationException($'multiple Version chapters in {fname}');
          
        end;
        
      end;
      
      if Result.ExtStrings=nil then raise new System.InvalidOperationException($'no ExtStrings chapter in file {fname}');
      
      
      
    end;
    
  end;
  
  BinSpecDB = class
    exts := new List<ExtSpec>;
    
    
    
    static function InitFromFolder(dir: string): BinSpecDB;
    begin
      Result := new BinSpecDB;
      
      foreach var fname in System.IO.Directory.EnumerateFiles(dir,'*.txt',System.IO.SearchOption.AllDirectories) do
      try
        var ext := ExtSpec.InitFromFile(fname);
        if ext=nil then continue;
        Result.exts += ext;
      except
        on e: Exception do
        begin
          writeln(fname);
          writeln(e);
          writeln('*'*50);
        end;
      end;
      
    end;
    
    procedure Save(fname: string);
    begin
      var ToDo := 0;
      
      foreach var ext in exts do
        if ext.NewFuncs<>nil then
        begin
          ext.NewFuncs.funcs.Select(t->t[1]).PrintLines;
          Writeln('='*50);
        end;
      
    end;
    
    static function InitFromFile(fname: string): BinSpecDB;
    begin
      var ToDo := 0;
      
      
      
    end;
    
  end;
  
end.