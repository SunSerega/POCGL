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

function DistinctBy<T1,T2>(self: sequence of T1; selector: T1->T2): sequence of T1; extensionmethod;
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

function SkipCharsFromTo(self: sequence of char; f,t: string): sequence of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  if not enm.MoveNext then exit;
  var q := new Queue<char>;
  
  while true do
  begin
    while q.Count<f.Length do
    begin
      q += enm.Current;
      if not enm.MoveNext then
      begin
        yield sequence q;
        exit;
      end;
    end;
    
    if q.SequenceEqual(f) then
    begin
      q.Clear;
      
      while true do
      begin
        while q.Count<t.Length do
        begin
          q += enm.Current;
          if not enm.MoveNext then exit;
        end;
        
        if q.SequenceEqual(t) then
          break else
          q.Dequeue;
        
      end;
      
      q.Clear;
    end else
      yield q.Dequeue;
    
  end;
  
  yield sequence q;
end;

{$endregion}

type
  
  {$region Chapters}
  
  {$region Curr list}
  
  // New Procedures and Functions[:] (there is more of this type)
  // Additions to the WGL interface:
  // Advertising WGL Extensions
  //=== NewFuncs
  // 
  // Addition to ***
  // Additions to ***
  // Modifications to ***
  //=== SpecModifications
  // 
  // Name String/Name Strings         === ExtStrings
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
  
  ExtNamesChapter = class(ExtSpecChapter)
    names: List<string>;
    
    constructor(s: string);
    begin
      inherited Create(s);
      if header_end<>'' then raise new System.ArgumentException($'ExtNameChapter had header_end of "{header_end}"');
      
      self.names :=
        contents
        .Split(#10, ',')
        .Select(s->s.Trim(' '))
        .Where(s->s<>'')
        .Select(s->
        begin
          
          Result := s;
        end)
        .ToList
      ;
      
      if names.Count=0 then raise new System.ArgumentException('no valid ext names was found');
      
    end;
    
    
    
    procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(names.Count);
      foreach var s in names do
        bw.Write(s);
    end;
    
    static function Load(br: System.IO.BinaryReader): ExtNamesChapter;
    begin
      Result := new ExtNamesChapter;
      Result.names := new List<string>(br.ReadInt32);
      loop Result.names.Capacity do
        Result.names += br.ReadString;
    end;
    
  end;
  
  SpecModificationsChapter = class(ExtSpecChapter)
    
  end;
  
  ExtStringsChapter = class(ExtSpecChapter)
    
    strings: List<string>;
    
    static function TryCreate(s: string): ExtStringsChapter;
    begin
      Result := new ExtStringsChapter(s);
      if Result.header_end<>'' then raise new System.ArgumentException($'ExtStringsChapter had header_end of "{Result.header_end}"');
      
      var none_declared := false;
      
      Result.strings :=
        Result.contents
        .Split(#10, ',')
        .Select(s->s.Trim(' '))
        .Where(s->s<>'')
        .Select(s->
        begin
          
          if Arr('(none)', 'none', 'None').Any(mask->s.StartsWith(mask)) then none_declared := true;
          
          case s of
            
            // " " вместо "_"
            'GL_EXT_primitive_bounding box': s := 'GL_EXT_primitive_bounding_box';
            'GL_OES_primitive_bounding box': s := 'GL_OES_primitive_bounding_box';
            
          end;
          
          Result := s;
        end)
        .Where(s->s.All(ch->  ch.IsDigit or ch.IsLetter or (ch = '_')  ))
        .ToList
      ;
      
      if Result.strings.Count=0 then
        if none_declared then Result := nil else
        raise new System.ArgumentException('no valid ext strings was found');
      
    end;
    
    
    
    procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(strings.Count);
      foreach var s in strings do
        bw.Write(s);
    end;
    
    static function Load(br: System.IO.BinaryReader): ExtStringsChapter;
    begin
      Result := new ExtStringsChapter;
      Result.strings := new List<string>(br.ReadInt32);
      loop Result.strings.Capacity do
        Result.strings += br.ReadString;
    end;
    
  end;
  
  NewFuncsChapter = class(ExtSpecChapter)
    funcs := new List<(string,string)>; // (name, text)
    
    static func_pnh_exceptions: Dictionary<string, string>;
    
    procedure DeTemplateFuncs(templ, TName: string; params repls: array of (string, string));
    begin
      for var i := funcs.Count-1 downto 0 do
        if funcs[i][0].Contains(templ) then
        begin
          var func := funcs[i];
          funcs.RemoveAt(i);
          
          foreach var repl in repls.Reverse do
          begin
            var id := repl[0].TrimEnd('&');
            funcs.Insert(i, (
              func[0].Replace(templ,id),
              func[1].Replace(templ,id).Replace(TName, repl[1].TrimEnd('&'))
            ));
          end;
          
        end;
    end;
    
    function FindFuncNameInd(i: integer): integer;
    begin
      while contents[i+1]=' ' do i -= 1;
      
      while i>0 do
      begin
        if contents[i+1] in ' *' then
        begin
          Result := i+1;
          exit;
        end;
        
        if contents[i+1] in ']}' then
          while not (contents[i+1] in '[{') do
            i -= 1;
        
        i-=1;
      end;
      
      Result := -1;
    end;
    
    static function TryCreate(s, fname: string): NewFuncsChapter;
    begin
      if func_pnh_exceptions=nil then
      begin
        func_pnh_exceptions := new Dictionary<string, string>;
        
        ReadLines('SpecFormating\GLExt\func pnh exceptions.dat')
        .Where(l->l.Contains('='))
        .Select(l->l.ToWords('='))
        .ForEach(l->func_pnh_exceptions.Add(l[0].TrimEnd(#9), l[1]));
        
      end;
      
      Result := new NewFuncsChapter(s);
//      if Result.header_end<>'' then raise new System.ArgumentException($'NewFuncsChapter had header_end of "{Result.header_end}"');
      
      Result.contents := Result.contents.Replace(#10,' ').SkipCharsFromTo('/*','*/').JoinIntoString;
      while Result.contents.Contains('  ') do Result.contents := Result.contents.Replace('  ',' ');
      s := Result.contents;
      
      var last_ind := 0;
      while true do
      begin
        var t := s.FindBrackets(last_ind);
        if t=nil then break;
        last_ind := t[1]+1;
        
//        s.Substring(t[0]+1,last_ind-t[0]-2).ToWords(',').Select(s->s.Trim).PrintLines;
//        writeln('-'*10);
        
        if s.Substring(t[0]+1,last_ind-t[0]-2).Contains('(') then continue;
        if not s.Substring(t[0]+1,last_ind-t[0]-2).ToWords(',').Select(s->s.Trim).All(s->(s.ToLower='void') or ( s.Remove('unsigned ', 'const ').Replace(' * ', ' ').ToWords.Length=2 )) then continue;
        case s.Substring(t[0],last_ind-t[0]) of
          '(for example)',
          '(if any)',
          '(not 8)',
          '(as before)',
          '(light maps)',
          '(GLint *)',
          '(or GLX_DONT_CARE)',
          '(GeForce FX, Quadro FX)',
          '(GLhandleARB programObject)',
          '(returns NULL)',
          '(Double Buffering)',
          '(Synchronization Primititives)',
          '(see GLX_DRAWABLE_TYPE_SGIX)',
          '(Configuration Management)',
          '(rational numbers)',
          '(X assigned)',
          '(x coefficient)',
          '(y coefficient)',
          '(z coefficient)',
          '(constant term)',
          '(UNSIGNED_SHORT formats)',
          '(or ARB_mirrored_repeat)',
          '(or MIRRORED_REPEAT_ARB)',
          '(Rendering Contexts)',
          '(the default)',
          '(see below)',
          '(major version, minor version, [profile mask])',
          '(Display *)':
            continue;
        end;
        
        if s.IndexOf('.', t[0]+1, t[1]-t[0]-1) <> -1 then continue; // в скобках бывают комментарии. Благо, их можно отличить - у них в конце точка
        
        var name_ind := Result.FindFuncNameInd(t[0]-1);
        if name_ind=-1 then
        begin
          Result.funcs += ( s.Remove(t[0]).TrimEnd, 'void '+s.Substring(0,t[1]+1) );
          continue;
        end;
        var func_name := s.Substring(name_ind, t[0]-name_ind).TrimEnd;
        while s[name_ind] in ' *' do name_ind -= 1;
        if s[name_ind] in ');' then
        begin
          Result.funcs += ( func_name, 'void '+s.Substring(name_ind, t[1]+1-name_ind) );
          continue;
        end;
        
        var f_ind := s.LastIndexOf(' ',name_ind-1)+1; // даже если вернёт -1, это вполне устраивает как ответ
        
        var fbody := s.Substring(f_ind, t[1]+1-f_ind);
        if Arr('calling','using','with','use','by','if','does','RESOLUTION','shader,').Any(rt-> fbody.StartsWith(rt) ) then continue;
        
        Result.funcs += ( func_name, fbody );
      end;
      
      Result.funcs.RemoveAll(t->t[0]='DECLARE_HANDLE');
      
      if Result.funcs.Count=0 then
      begin
        Result := nil;
        exit;
      end;
      
      for var i := 0 to Result.funcs.Count-1 do
      begin
        
        var func_name := Result.funcs[i][0];
        if func_pnh_exceptions.ContainsKey(func_name) then
          func_name := func_pnh_exceptions[func_name] else
        if not Arr('wgl', 'egl', {'glX', 'glu',} 'gl').Any(pnh->func_name.StartsWith(pnh)) then
        begin
          foreach var pnh in Arr('wgl', 'egl', 'glX', 'glu', 'gl') do
            if fname.Contains(pnh.ToUpper) or (pnh='gl') then
            begin
              func_name := pnh+func_name;
              break;
            end;
        end;
        var ffname := fname.Substring(fname.LastIndexOf('\')+1);
        foreach var ext_t in Arr('ATI', 'KHR') do
          if ffname.StartsWith(ext_t) and not func_name.EndsWith(ext_t) then
          begin
            func_name += ext_t;
            break;
          end;
        func_name := func_name.Replace('Tangent3{bdfis}EXTv', 'Tangent3{bdfis}vEXT');
        
        var func_text := Result.funcs[i][1];
        while func_text.Contains('  ') do func_text := func_text.Replace('  ',' ');
        func_text := func_text.Replace('Tangent3{bdfis}EXTv', 'Tangent3{bdfis}vEXT');
        
        Result.funcs[i] := (func_name, func_text);
      end;
      
      
      
      Result.DeTemplateFuncs('[v]', 'T ',
        ( '',   'T '  ),
        ( 'v&', 'T * ' )
      );
      
      
      
      Result.DeTemplateFuncs('{1234}{sifd}', 'T', //ToDo может лучше оставлять T[N] ?
        Range(1,4).Cartesian(Arr('s','i','f','d'))
        .Select(t->t[0]+t[1])
        .Select(s->(s,'Vec'+s))
        .ToArray
      );
      
      
      
      Result.DeTemplateFuncs('[fd]v', 'T ',
        ( 'fv', 'glfloat * '   ),
        ( 'dv', 'gldouble * ' )
      );
      
      Result.DeTemplateFuncs('[fd]', 'T ',
        ( 'f&', 'glfloat '   ),
        ( 'd&', 'gldouble ' )
      );
      
      
      
      Result.DeTemplateFuncs('[bsifd ubusui]v', 'T ',
        ( 'bv', 'glbyte * '     ),
        ( 'sv', 'glshort * '    ),
        ( 'iv', 'glint * '      ),
        ( 'fv', 'glfloat * '    ),
        ( 'dv', 'gldouble * '   ),
        ( 'ubv', 'glubyte * '   ),
        ( 'usv', 'glushort * '  ),
        ( 'uiv', 'gluint * '    )
      );
      
      Result.DeTemplateFuncs('[bsifd ubusui]', 'T ',
        ( 'b&', 'glbyte '   ),
        ( 's&', 'glshort '  ),
        ( 'i&', 'glint '    ),
        ( 'f&', 'glfloat '  ),
        ( 'd&', 'gldouble ' ),
        ( 'ub', 'glubyte '  ),
        ( 'us', 'glushort ' ),
        ( 'ui', 'gluint '   )
      );
      
      Result.DeTemplateFuncs('{bsifd}v', 'T ',
        ( 'bv', 'glbyte * '   ),
        ( 'sv', 'glshort * '  ),
        ( 'iv', 'glint * '    ),
        ( 'fv', 'glfloat * '  ),
        ( 'dv', 'gldouble * ' )
      );
      
      Result.DeTemplateFuncs('{bsifd}', 'T ',
        ( 'b&', 'glbyte '   ),
        ( 's&', 'glshort '  ),
        ( 'i&', 'glint '    ),
        ( 'f&', 'glfloat '  ),
        ( 'd&', 'gldouble ' )
      );
      
      Result.DeTemplateFuncs('{bdfis}EXTv', 'T ',
        ( 'bEXTv', 'glbyte * '   ),
        ( 'sEXTv', 'glshort * '  ),
        ( 'iEXTv', 'glint * '    ),
        ( 'fEXTv', 'glfloat * '  ),
        ( 'dEXTv', 'gldouble * ' )
      );
      
      Result.DeTemplateFuncs('{bdfis}v', 'T ',
        ( 'bv', 'glbyte * '   ),
        ( 'sv', 'glshort * '  ),
        ( 'iv', 'glint * '    ),
        ( 'fv', 'glfloat * '  ),
        ( 'dv', 'gldouble * ' )
      );
      
      Result.DeTemplateFuncs('{bdfis}', 'T ',
        ( 'b&', 'glbyte '   ),
        ( 's&', 'glshort '  ),
        ( 'i&', 'glint '    ),
        ( 'f&', 'glfloat '  ),
        ( 'd&', 'gldouble ' )
      );
      
      Result.DeTemplateFuncs('{bsifd ubusui}v', 'T*',
        ( 'bv', 'glbyte *'     ),
        ( 'sv', 'glshort *'    ),
        ( 'iv', 'glint *'      ),
        ( 'fv', 'glfloat *'    ),
        ( 'dv', 'gldouble *'   ),
        ( 'ubv', 'glubyte *'   ),
        ( 'usv', 'glushort *'  ),
        ( 'uiv', 'gluint *'    )
      );
      
      Result.DeTemplateFuncs('{ubusui}', 'T ',
        ( 'ub', 'glubyte '  ),
        ( 'us', 'glushort ' ),
        ( 'ui', 'gluint '   )
      );
      
      Result.DeTemplateFuncs('{fd}', 'T ',
        ( 'f&', 'glfloat '  ),
        ( 'd&', 'gldouble ' )
      );
      
      Result.DeTemplateFuncs('{if}v', 'T ',
        ( 'iv', 'glint * '    ),
        ( 'fv', 'glfloat * '  )
      );
      
      Result.DeTemplateFuncs('{if}', 'T ',
        ( 'i&', 'glint '    ),
        ( 'f&', 'glfloat '  )
      );
      
      Result.DeTemplateFuncs('{i,f,d}', 'T ',
        ( 'i&', 'glint '    ),
        ( 'f&', 'glfloat '  ),
        ( 'd&', 'gldouble ' )
      );
      
      Result.DeTemplateFuncs('{sifx}v', 'T*',
        ( 'sv', 'glshort *' ),
        ( 'iv', 'glint *'   ),
        ( 'fv', 'glfloat *' ),
        ( 'xv', 'glfixed *' )
      );
      
      Result.DeTemplateFuncs('{sifx}', 'T ',
        ( 's&', 'glshort ' ),
        ( 'i&', 'glint '   ),
        ( 'f&', 'glfloat ' ),
        ( 'x&', 'glfixed ' )
      );
      
      Result.DeTemplateFuncs('{ifx}v', 'T ',
        ( 'iv', 'glint *'   ),
        ( 'fv', 'glfloat *' ),
        ( 'xv', 'glfixed *' )
      );
      
      Result.DeTemplateFuncs('[i|f]', 'TYPE',
        ( 'i&', 'glint'   ),
        ( 'f&', 'glfloat' )
      );
      
      
      
      //ToDo у следующих 4 - разное кол-во параметров разное, в зависмости от цифры
      
      Result.DeTemplateFuncs('{1234}x', 'T ',
        ( '1x', 'glfixed ' ),
        ( '2x', 'glfixed ' ),
        ( '3x', 'glfixed ' ),
        ( '4x', 'glfixed ' )
      );
      
      Result.DeTemplateFuncs('{234}x', 'T ',
        ( '2x', 'glfixed ' ),
        ( '3x', 'glfixed ' ),
        ( '4x', 'glfixed ' )
      );
      
      Result.DeTemplateFuncs('{34}x', 'T ',
        ( '3x', 'glfixed ' ),
        ( '4x', 'glfixed ' )
      );
      
      Result.DeTemplateFuncs('{12}x', 'T ',
        ( '1x', 'glfixed ' ),
        ( '2x', 'glfixed ' )
      );
      
      
      
    end;
    
    
    
    procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(funcs.Count);
      foreach var t in funcs do
      begin
        bw.Write(t[0]);
        bw.Write(t[1]);
      end;
    end;
    
    static function Load(br: System.IO.BinaryReader): NewFuncsChapter;
    begin
      Result := new NewFuncsChapter;
      Result.funcs.Capacity := br.ReadInt32;
      loop Result.funcs.Capacity do
        Result.funcs += (br.ReadString,br.ReadString);
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
    is_complete: boolean;
    
    ExtNames:         ExtNamesChapter := nil;
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
    
    
    
    static function RemoveGenFolderName(fname: string): string;
    begin
      var gen_folder_name := 'SpecFormating\GLExt\ext spec texts';
      if fname.StartsWith(gen_folder_name) then
        Result := fname.Substring(gen_folder_name.Length) else
        Result := fname;
    end;
    
    static function InitFromFile(fname: string): ExtSpec;
    begin
      if fname.Substring(fname.LastIndexOf('\')+1) in [
        'GLU_SGIX_icc_compress.txt'
      ] then exit;
      
      var spec_text := ReadAllText(fname);
      
      // OES\OES_stencil_wrap.txt
      // SGI\akeley_future_extensions.txt
      //В этих файлах не хранятся расширения. У всех расширений есть этот раздел:
      if not spec_text.Contains('Name String') then exit;
      
      Result := new ExtSpec;
      Result.fname := RemoveGenFolderName(fname);
      Result.is_complete := not spec_text.Split(#10).Take(10).Any(l->l.StartsWith('XXX') or l.EndsWith('XXX'));
//      writeln(fname);
      
      
      
      var inds := new List<(string, integer)>;
      
      {$region inds fill}
      
      if spec_text.StartsWith('Name'#10) then inds += ('Name',4);
      inds.AddRange(spec_text.FindAllIndexes(#10'Name'#10                                     ).Select(ind->('Name', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Functions and Procedures'#10             ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedure and Functions'#10              ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedures and Functions'#10             ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes( '  New Procedures and Functions'#10             ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedures And Functions'#10             ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedures and Functions:'#10            ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Procedures, Functions and Structures:'#10).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Additions to the WGL interface:'#10          ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Advertising WGL Extensions'#10               ).Select(ind->('NewFuncs', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Additions to the GLX'                        ).Select(ind->('NewFuncs', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Addition to '                                ).Select(ind->('SpecModifications', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Additions to '                               ).Select(ind->('SpecModifications', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Modifications to '                           ).Select(ind->('SpecModifications', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Name String'#10                              ).Select(ind->('ExtStrings', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Name Strings'#10                             ).Select(ind->('ExtStrings', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Contact'#10                                  ).Select(ind->('AuthorContacts', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Contacts'#10                                 ).Select(ind->('AuthorContacts', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Contributors'#10                             ).Select(ind->('ContributorsList', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Errors'#10                                   ).Select(ind->('Errors', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Issues'#10                                   ).Select(ind->('Issues', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Keywords'#10                             ).Select(ind->('NewKeywords', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New State'#10                                ).Select(ind->('NewState', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Tokens:'#10                              ).Select(ind->('NewTokens', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'New Tokens'                                  ).Select(ind->('NewTokens', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'New Types'#10                                ).Select(ind->('NewTypes', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Notice'#10                                   ).Select(ind->('Notice', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Status'#10                                   ).Select(ind->('Status', ind)));
      
      inds.AddRange(spec_text.FindAllIndexes(#10'Version:'#10                                 ).Select(ind->('Version', ind)));
      inds.AddRange(spec_text.FindAllIndexes(#10'Version'#10                                  ).Select(ind->('Version', ind)));
      
      {$endregion inds fill}
      
      // special funcs
      var sf1 := fname.EndsWith('EXT_pixel_buffer_object.txt'); // в этом файле 2 статуса, примерно одинаковых
      
      foreach var p in
        inds.OrderBy(t->spec_text.IndexOf(#10,t[1]-1))
//        .PrintLines
        .WherePrev(t->
        begin
          case t[0] of
            
            'SpecModifications': Result := -1 = spec_text.IndexOf(' or',t[1],spec_text.IndexOf(#10,t[1])-t[1]);
            
            else Result := true;
          end;
        end)
        .DistinctBy(t->spec_text.IndexOf(#10,t[1]))
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
          'NewFuncs':           if NewFuncsChapter.TryCreate(chapt_contents, fname) is NewFuncsChapter(var chap) then if Result.NewFuncs=nil then Result.NewFuncs := chap else Result.NewFuncs.funcs := Result.NewFuncs.funcs.Concat(chap.funcs).DistinctBy(t->t[0]).ToList;
          
          'Name':               if (Result.ExtNames         =nil) then Result.ExtNames           := ExtNamesChapter          .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple ExtNames chapters in {fname}');
          'SpecModifications':                                         Result.SpecModifications  += SpecModificationsChapter .Create   (chapt_contents        );
          'ExtStrings':         if (Result.ExtStrings       =nil) then Result.ExtStrings         := ExtStringsChapter        .TryCreate(chapt_contents        ) else raise new System.InvalidOperationException($'multiple ExtStrings chapters in {fname}');
          'AuthorContacts':     if (Result.AuthorContacts   =nil) then Result.AuthorContacts     := AuthorContactsChapter    .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple AuthorContacts chapters in {fname}');
          'ContributorsList':   if (Result.ContributorsList =nil) then Result.ContributorsList   := ContributorsListChapter  .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple ContributorsList chapters in {fname}');
          'Errors':             if (Result.Errors           =nil) then Result.Errors             := ErrorsChapter            .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple Errors chapters in {fname}');
          'Issues':                                                    Result.Issues             += IssuesChapter            .Create   (chapt_contents        );
          'NewKeywords':        if (Result.NewKeywords      =nil) then Result.NewKeywords        := NewKeywordsChapter       .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple NewKeywords chapters in {fname}');
          'NewState':           if (Result.NewState         =nil) then Result.NewState           := NewStateChapter          .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple NewState chapters in {fname}');
          'NewTokens':                                                 Result.NewTokens          += NewTokensChapter         .Create   (chapt_contents        );
          'Notice':             if (Result.Notice           =nil) then Result.Notice             := NoticeChapter            .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple Notice chapters in {fname}');
          'Status':             if (Result.Status=nil)     or sf1 then Result.Status             := StatusChapter            .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple Status chapters in {fname}');
          'Version':            if (Result.Version          =nil) then Result.Version            := VersionChapter           .Create   (chapt_contents        ) else raise new System.InvalidOperationException($'multiple Version chapters in {fname}');
          
        end;
        
      end;
      
      if Result.ExtNames=nil then raise new System.InvalidOperationException($'no ExtNames chapter in file {fname}');
      
      if fname.EndsWith('PGI_misc_hints.txt') then
      begin
        Result.NewFuncs := new NewFuncsChapter;
        Result.NewFuncs.funcs := new List<(string, string)>;
        Result.NewFuncs.funcs += ('glHintPGI','%Broken%');
      end;
      
    end;
    
    
    
    procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(self.fname);
      bw.Write(self.is_complete);
      
      self.ExtNames.Save(bw);
      
      bw.Write(self.ExtStrings<>nil);
      if self.ExtStrings<>nil then self.ExtStrings.Save(bw);
      
      bw.Write(self.NewFuncs<>nil);
      if self.NewFuncs<>nil then self.NewFuncs.Save(bw);
      
    end;
    
    static function Load(br: System.IO.BinaryReader): ExtSpec;
    begin
      Result := new ExtSpec;
      Result.fname := br.ReadString;
      Result.is_complete := br.ReadBoolean;
      
      Result.ExtNames := ExtNamesChapter.Load(br);
      
      if br.ReadBoolean then Result.ExtStrings := ExtStringsChapter.Load(br);
      if br.ReadBoolean then Result.NewFuncs := NewFuncsChapter.Load(br);
      
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
      var bw := new System.IO.BinaryWriter(System.IO.File.Create(fname));
      
//      exts.SelectMany(ext->ext.ExtNames.names)
//      .Distinct
//      .Sorted
//      .PrintLines;
      
      bw.Write(exts.Count);
      foreach var ext in exts do
        ext.Save(bw);
      
      bw.Close;
    end;
    
    static function LoadFromFile(fname: string): BinSpecDB;
    begin
      var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
      
      Result := new BinSpecDB;
      Result.exts.Capacity := br.ReadInt32;
      loop Result.exts.Capacity do
        Result.exts += ExtSpec.Load(br);
      
      br.Close;
    end;
    
  end;
  
end.