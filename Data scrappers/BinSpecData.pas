unit BinSpecData;

type
  
  {$region Chapters}
  
  {$region Curr list}
  
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
  
  ExtSpecChapter = abstract class
    header_end: string;
    contents: string;
    
    constructor(s: string);
    begin
      var ind := s.IndexOf(#10);
      self.header_end := s.Remove(ind);
      self.contents := s.Substring(ind+1);
    end;
    
  end;
  
  {$endregion Chapters}
  
  ExtSpec = class
    fname, name, ext_string: string;
    SectNames := new List<string>;
    
    
    
    static function InitFromFile(fname: string): ExtSpec;
    begin
      var spec_text := ReadAllText(fname).Remove(#13).Split(#10);
      if spec_text.Any(l->l.StartsWith('XXX')) then exit; // у незаконченных расширений - криво прописана спецификация (не приведена в общий вид с остальными расширениями)
      Result := new ExtSpec;
//      writeln(fname);
      
      var ToDo := 0;
      Result.fname := fname;
      
      var res := new StringBuilder;
      var in_header := false;
      var last_header: string;
      foreach var l in spec_text do
      begin
        in_header := (l<>'') and char.IsLetter(l[1]);
        
        if in_header then
        begin
          if res.Length<>0 then res += ' ';
          res += l;
        end else
        if res.Length<>0 then
        begin
          var header := res.ToString.Trim(#9, ' ');
          while header.Contains('  ') do header := header.Replace('  ', ' ');
          if last_header.Contains('Name String') or last_header.Contains('New Procedures and Functions') then
            Result.SectNames += header;
          last_header := header;
          
          res.Length := 0;
        end;
        
      end;
      
    end;
    
  end;
  
  BinSpecDB = class
    exts := new List<ExtSpec>;
    
    
    
    static function InitFromFolder(dir: string): BinSpecDB;
    begin
      Result := new BinSpecDB;
      
      foreach var fname in System.IO.Directory.EnumerateFiles(dir,'*.txt',System.IO.SearchOption.AllDirectories) do
      begin
        var ext := ExtSpec.InitFromFile(fname);
        if ext=nil then continue;
        Result.exts += ext;
      end;
      
    end;
    
    procedure Save(fname: string);
    begin
      var ToDo := 0;
      
      var maxl := exts.Max&<ExtSpec,integer>(ext->ext.fname.Length);
      
      var prev := new HashSet<string>;
      foreach var t in 
        exts.SelectMany(
          ext->
          ext.SectNames
          .Select(spec->(ext.fname.PadRight(maxl),spec))
        )
        .OrderBy(t->t[1])
      do if prev.Add(t[1]) then
        writeln($'{t[0]} : {t[1]}');
      
    end;
    
    static function InitFromFile(fname: string): BinSpecDB;
    begin
      var ToDo := 0;
      
      
      
    end;
    
  end;
  
end.