program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

var
  keywords := HSet('begin', 'end', 'params', 'type', 'end', 'program', 'array', 'unit', 'label', 'event', 'in', 'packed', 'property');

function SkipCharsFromTo(self: sequence of char; f,t: string): sequence of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  enm.MoveNext;
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

function TakeCharsFromTo(self: sequence of char; f,t: string): sequence of array of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  enm.MoveNext;
  var q := new Queue<char>;
  var res := new List<char>;
  
  while true do
  begin
    while q.Count<f.Length do
    begin
      q += enm.Current;
      if not enm.MoveNext then exit;
    end;
    
    if q.SequenceEqual(f) then
    begin
      q.Clear;
      
      while true do
      begin
        while q.Count<t.Length do
        begin
          q += enm.Current;
          if not enm.MoveNext then
          begin
            res.AddRange(q);
            yield res.ToArray;
            exit;
          end;
        end;
        
        if q.SequenceEqual(t) then
          break else
          res += q.Dequeue;
        
      end;
      
      yield res.ToArray;
      res.Clear;
      q.Clear;
    end else
      q.Dequeue;
    
  end;
  
end;

function GetAllCombos<T>(variants: sequence of sequence of T): sequence of sequence of T;
begin
  
  if not variants.Any then
    yield Seq&<T> else
  if variants.Count=1 then
    yield sequence variants.First.Select(curr->Seq(curr)) else
    yield sequence variants.First.SelectMany(curr->GetAllCombos(variants.Skip(1)).Select(next->next.Prepend(curr)));
  
end;

function pas_to_gl_t(self: string): string; extensionmethod;
begin
  case self of
    'SByte':  Result := 'b';
     'Byte':  Result := 'ub';
     'Int16': Result := 's';
    'UInt16': Result := 'us';
     'Int32': Result := 'i';
    'UInt32': Result := 'ui';
     'Int64': Result := 'i64';
    'UInt64': Result := 'ui64';
    'single': Result := 'f';
    'double': Result := 'd';
  end;
end;

function GetTypeDefString(s: string): sequence of (string, string);
begin
  var rc := s.Count(ch->ch='*');
  s := s.Replace('const*','*').Remove('const ', ' ', '*', #13, #10);
  
  case s.ToLower of
    
    'bool':                   s := 'boolean';
    
    'glbyte':                 s := 'SByte';
    'glubyte':                s := 'Byte';
    'glchararb':              s := 'Byte';
    'glboolean':              s := 'Byte';
    
    'glshort':                s := 'Int16';
    'glushort':               s := 'UInt16';
    'ushort':                 s := 'UInt16';
    
    'glint':                  s := 'Int32';
    'glsizei':                s := 'Int32';
    'glclampx':               s := 'Int32';
    'int':                    s := 'Int32';
    'int32':                  s := 'Int32';
    'gluint':                 s := 'UInt32';
    'glbitfield':             s := 'UInt32';
    'uint':                   s := 'UInt32';
    'dword':                  s := 'UInt32';
    'unsignedint':            s := 'UInt32';
    
    'glint64':                s := 'Int64';
    'glint64ext':             s := 'Int64';
    'int64':                  s := 'Int64';
    'gluint64':               s := 'UInt64';
    'gluint64ext':            s := 'UInt64';
    'unsignedlong':           s := 'UInt64';
    
    'glfloat':                s := 'single';
    'glclampf':               s := 'single';
    'float':                  s := 'single';
    'gldouble':               s := 'double';
    'glclampd':               s := 'double';
    
    'glfixed':                s := 'fixed';
    'glhalfnv':               s := 'half';
    
    'glintptr':               s := 'IntPtr';
    'glintptrarb':            s := 'IntPtr';
    'proc':                   s := 'IntPtr';
    'handle':                 s := 'IntPtr';
    'lpvoid':                 s := 'IntPtr';
    'glsizeiptr':             s := 'UIntPtr';
    'glsizeiptrarb':          s := 'UIntPtr'; 
    
    'pgpu_device':            s := '^GPU_Device_Affinity_Info';
    
    'glenum':                 s := 'ErrorCode';
    
    'glsync':                 s := 'GLsync';
    'gleglimageoes':          s := 'GLeglImageOES';
    'glhandlearb':            s := 'GLhandleARB';
    'hgpunv':                 s := 'GPUAffinityHandle';
    'hvideooutputdevicenv':   s := 'VideoOutputDeviceHandleNV';
    'hvideoinputdevicenv':    s := 'VideoInputDeviceHandleNV';
    'hpvideodev':             s := 'VideoDeviceHandleNV';
    'gleglclientbufferext':   s := 'GLeglClientBufferEXT';
    'glvdpausurfacenv':       s := 'GLvdpauSurfaceNV';
    'hpbufferext':            s := 'PBufferName';
    'lpcstr':                 s := 'string';
    'hpbufferarb':            s := 'HPBufferARB';
    'hdc':                    s := 'GDI_DC';
    'pixelformatdescriptor':  s := 'GDI_PixelFormatDescriptor';
    'henhmetafile':           s := 'GDI_HENHMetafile';
    'layerplanedescriptor':   s := 'GDI_LayerPlaneDescriptor';
    'colorref':               s := 'GDI_COLORREF';
    'hglrc':                  s := 'HGLRC';
    'lpglyphmetricsfloat':    s := 'GDI_LPGlyphmetricsFloat';
    
    'struct_cl_context':      s := 'cl_context';
    'struct_cl_event':        s := 'cl_event';
    
    'gldebugproc':            s := 'GLDEBUGPROC';
    'gldebugprocarb':         s := 'GLDEBUGPROC';
    'glvulkanprocnv':         s := 'GLVULKANPROCNV';
    'gldebugprocamd':         s := 'GLDEBUGPROCAMD';
    
    'glvoid',
    'void':
    if rc<>0 then
    begin
      s := 'pointer';
      rc -= 1;
    end else
      s := 'void';
    
    'glchar',
    'char':
    if rc<>0 then
    begin
      s := 'string';
      rc -= 1;
    end else
      s := 'Byte';
    
    else raise new System.ArgumentException($'тип "{s}" не описан');
  end;
  
  s := '^'*rc + s;
  
  
  
  if s.Count(ch->ch='^')=1 then
  begin
    yield ('[MarshalAs(UnmanagedType.LPArray)] ', s.Replace('^', 'array of '));
    yield ('var ', s.Remove('^'));
    yield ('', 'pointer');
  end else
  
  if s='string' then
  begin
    yield ('[MarshalAs(UnmanagedType.LPStr)] ', s);
    yield ('', 'IntPtr');
  end else
    
    yield ('', s);
  
end;

type
  FuncDef = class
    
    name_header, name: string;
    res: string;
    lib_name := 'opengl32.dll';
    
    par := new List<sequence of (string,string)>;
    
    constructor(s: string);
    begin
      
      s := s.Remove('GL_APIENTRY', 'GLAPI', 'GL_API', 'WINAPI', 'APIENTRY');
      
      var ind1 := s.IndexOf('(');
      var ind2 := s.LastIndexOf(')');
      
      begin
        var nts := s.Remove(ind1).Trim;
        var ind := nts.LastIndexOf(' ');
        
        name := nts.Substring(ind+1);
        
        name_header := nil;
        foreach var pnh in Arr('wgl', 'gl') do
          if name.StartsWith(pnh) then
          begin
            name_header := pnh;
            name := name.SubString(pnh.Length);
            break;
          end;
        if name_header=nil then
        begin
          name_header := '';
          lib_name := 'gdi32.dll';
        end;
        if name.ToLower() in keywords then name := '&'+name;
        
//        name.Println;
        res := GetTypeDefString(nts.Remove(ind)).Last[1];
        
      end;
      
      foreach var p in s.Substring(ind1+1,ind2-ind1-1).Replace('*','* ').Split(',') do
      begin
        if p = 'void' then break;
        var ind := p.LastIndexOf(' ');
        
        var cpar := (
          p.Substring(ind+1),
          GetTypeDefString(p.Remove(ind))
        );
        
        if cpar[0].ToLower() in keywords then cpar := ('&'+cpar[0], cpar[1]);
        
        par += cpar[1].Select(
          tt->(
            tt[0] + (tt[1].ToLower.Contains(cpar[0].ToLower)?'_':'') + cpar[0],
            tt[1]
          )
        ).Select(tt->
        begin
          if not tt[0].Remove('[MarshalAs').Contains('[') then
          begin
            Result := tt;
            exit;
          end;
          
          var ind1 := tt[0].IndexOf('[',tt[0].IndexOf('[MarshalAs')+1)+1;
          var ind2 := tt[0].IndexOf(']',ind1);
//          tt[0].SubString(ind1,ind2-ind1).Println;
          var n := tt[0].SubString(ind1,ind2-ind1).ToInteger;
          
          var gl_t := tt[1].pas_to_gl_t;
          if gl_t='' then gl_t := '_'+tt[1];
          
          Result := ( tt[0].Remove(ind1-1), 'Vec'+n+gl_t );
        end).ToList.AsEnumerable;
      end;
      
    end;
    
    public function GetAllStrings: sequence of string;
    begin
      foreach var par_combo in GetAllCombos(par) do
      begin
        
        var f := res<>'void';
        var sb := new StringBuilder;
        sb += '    static ';
        
        sb += f?'function':'procedure';
        sb += ' ';
        sb += name;
        
        if par.Count<>0 then
        begin
          sb += '(';
          sb += par_combo.Select(t->$'{t[0]}: {t[1]}').JoinIntoString('; ');
          sb += ')';
        end;
        
        if f then
        begin
          sb += ': ';
          sb += res;
        end;
        
        sb += ';';
        
        sb.AppendLine;
        sb += $'    external ''{lib_name}'' name ''';
        sb += name_header;
        sb += name;
        sb += ''';';
        
        sb.AppendLine;
        yield sb.ToString;
      end;
      
    end;
    
    public function ToString: string; override :=
    GetAllStrings
    .JoinIntoString('');
    
  end;

begin
  try
    var text := System.Windows.Forms.Clipboard.GetText;
    
    text := text
      .Remove(#13)
      .SkipCharsFromTo('/*', '*/')
      .SkipCharsFromTo('typedef',';')
      .SkipCharsFromTo('#',#10)
      .JoinIntoString('')
      .ToWords(#10)
      .Where(l->l.Contains('API '))
      .Select(l->FuncDef.Create(l).ToString)
      .JoinIntoString('    '#10);
    
    text += '    ';
    
    System.Windows.Forms.Clipboard.SetText(#10+text);
    System.Console.Beep;
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.