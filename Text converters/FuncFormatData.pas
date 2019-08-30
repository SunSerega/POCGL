unit FuncFormatData;
{$reference System.Windows.Forms.dll}

var
  keywords := HSet('begin', 'end', 'params', 'type', 'end', 'program', 'array', 'unit', 'label', 'event', 'in', 'packed', 'property');

{$region Misc utils}

function SkipCharsFromTo2(self: sequence of char; f,t: string): sequence of char; extensionmethod;
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

function GetAllCombos<T>(variants: sequence of sequence of T): sequence of sequence of T;
begin
  
  if not variants.Any then
    Result := Seq&<sequence of T>(Seq&<T>()) else
  if variants.Count=1 then
    Result := variants.First.Select(curr->Seq(curr)) else
    Result := variants.First.SelectMany(curr->GetAllCombos(variants.Skip(1)).Select(next->next.Prepend(curr)));
  
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

{$endregion Misc utils}

type
  par_data = auto class
    fn_mask: string;        //function name:  {0}=prev name
    par_def_mask: string;   //param def:      {0}=param name
    par_call_mask: string;  //param call:     {0}=param name
    func_call_mask: string; //function call:  {0}=prev func call; {1}=param name
  end;

function GetTypeDefString(is_ret: boolean; par_n: integer; s: string; vec_l: integer): (string, List<par_data>);
begin
  
  {$region TypeConv}
  
  var rc := s.Count(ch->ch='*');
  s := s.Remove('const*', 'const ', ' ', '*', #13, #10);
  
  case s.ToLower of
    
    'bool':                     s := 'UInt32';
    'boolean':                  s := 'UInt32';
    'eglboolean':               s := 'UInt32';
    
    'glbyte':                   s := 'SByte';
    'glubyte':                  s := 'Byte';
    'glchararb':                s := 'Byte';
    'glboolean':                s := 'Byte';
    
    'glshort':                  s := 'Int16';
    'glushort':                 s := 'UInt16';
    'ushort':                   s := 'UInt16';
    
    'glint':                    s := 'Int32';
    'eglint':                   s := 'Int32';
    'glsizei':                  s := 'Int32';
    'glclampx':                 s := 'Int32';
    'int':                      s := 'Int32';
    'sizei':                    s := 'Int32';
    'int32':                    s := 'Int32';
    'int32_t':                  s := 'Int32';
    'gluint':                   s := 'UInt32';
    'uint':                     s := 'UInt32';
    'dword':                    s := 'UInt32';
    'unsignedint':              s := 'UInt32';
    
    'glint64':                  s := 'Int64';
    'glint64ext':               s := 'Int64';
    'int64':                    s := 'Int64';
    'int64_t':                  s := 'Int64';
    'gluint64':                 s := 'UInt64';
    'gluint64ext':              s := 'UInt64';
    'unsignedlong':             s := 'UInt64';
    'uint64':                   s := 'UInt64';
    
    'glfloat':                  s := 'single';
    'glclampf':                 s := 'single';
    'float':                    s := 'single';
    'gldouble':                 s := 'double';
    'glclampd':                 s := 'double';
    
    'glfixed':                  s := 'fixed';
    'glhalfnv':                 s := 'half';
    
    'glintptr':                 s := 'IntPtr';
    'glintptrarb':              s := 'IntPtr';
    'proc':                     s := 'IntPtr'; // wglGetProcAddress
    'handle':                   s := 'IntPtr';
    'lpvoid':                   s := 'IntPtr';
    'glsizeiptr':               s := 'UIntPtr';
    'glsizeiptrarb':            s := 'UIntPtr';
    'sizeiptr':                 s := 'UIntPtr';
    
    'enum':                     s := 'DummyEnum';
    'glenum':                   s := 'DummyEnum';
    'eglenum':                  s := 'DummyEnum';
    'bitfield':                 s := 'DummyFlags';
    'glbitfield':               s := 'DummyFlags';
    
    'egltimekhr':               s := 'TimeSpan';
    
    'glsync':                   s := 'GLsync';
    'sync':                     s := 'GLsync';
    'eglsynckhr':               s := 'EGLsync';
    'egldisplay':               s := 'EGLDisplay';
    'glunurbsobj':              s := 'GLUnurbs';
    'glxwindow':                s := 'GLXWindow';
    'window':                   s := 'GLXWindow';
    'glxpixmap':                s := 'GLXPixmap';
    'pixmap':                   s := 'GLXPixmap';
    'colormap':                 s := 'GLXColormap';
    'dmparams':                 s := 'GLXDMparams';
    'dmbuffer':                 s := 'GLXDMbuffer';
    'vlserver':                 s := 'GLXVLServer';
    'vlpath':                   s := 'GLXVLPath';
    'vlnode':                   s := 'GLXVLNode';
    'status':                   s := 'GLXStatus';
    'glxdrawable':              s := 'GLXDrawable';
    'glxcontext':               s := 'GLXContext';
    'glxpbuffer':               s := 'GLXPbuffer';
    'glxpbuffersgix':           s := 'GLXPbuffer';
    'glxfbconfig':              s := 'GLXFBConfig';
    'glxfbconfigsgix':          s := 'GLXFBConfig';
    'glxcontextid':             s := 'GLXContextID';
    'glxvideosourcesgix':       s := 'GLXVideoSourceSGIX';
    'glxvideocapturedevicenv':  s := 'GLXVideoCaptureDeviceNV';
    'glxvideodevicenv':         s := 'GLXVideoDeviceNV';
    '__glxextfuncptr':          s := 'GLXFuncPtr';
    'gleglimageoes':            s := 'GLeglImageOES';
    'glhandlearb':              s := 'GLhandleARB';
    'hgpunv':                   s := 'GPUAffinityHandle';
    'hvideooutputdevicenv':     s := 'VideoOutputDeviceHandleNV';
    'hvideoinputdevicenv':      s := 'VideoInputDeviceHandleNV';
    'hpvideodev':               s := 'VideoDeviceHandleNV';
    'gleglclientbufferext':     s := 'GLeglClientBufferEXT';
    'glvdpausurfacenv':         s := 'GLvdpauSurfaceNV';
    'hpbufferext':              s := 'PBufferName';
    'lpcstr':                   s := 'string';
    'hpbufferarb':              s := 'PBufferName';
    'hdc':                      s := 'GDI_DC';
    'pixelformatdescriptor':    s := 'GDI_PixelFormatDescriptor';
    'henhmetafile':             s := 'GDI_HENHMetafile';
    'layerplanedescriptor':     s := 'GDI_LayerPlaneDescriptor';
    'colorref':                 s := 'GDI_COLORREF';
    'hglrc':                    s := 'GLContext';
    
    'glxhyperpipenetworksgix':  s := 'GLXHyperpipeNetworkSGIX';
    'glxhyperpipeconfigsgix':   s := 'GLXHyperpipeConfigDataSGIX';
    'glxpiperect':              s := 'GLXPipeRect';
    'glxpiperectlimits':        s := 'GLXPipeRectLimits';
    'pgpu_device':              s := '^GPU_Device_Affinity_Info';
    'lpglyphmetricsfloat':      s := '^GDI_GlyphmetricsFloat';
    
    'display', 'xvisualinfo':
    if rc<>0 then
    begin
      s := 'P' + s;
      rc -= 1;
    end else
      raise new System.InvalidOperationException($'Запись "{s}" не описана полностью в данной версии, доступны только указатели на неё');
    
    'struct_cl_context':      s := 'cl_context';
    'struct_cl_event':        s := 'cl_event';
    
    'gldebugproc':            s := 'GLDEBUGPROC';
    'gldebugprocarb':         s := 'GLDEBUGPROC';
    'gldebugprocamd':         s := 'GLDEBUGPROC';
    'gldebugprockhr':         s := 'GLDEBUGPROC';
    'glvulkanprocnv':         s := 'GLVULKANPROCNV';
    
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
    
    else raise new System.ArgumentException($'Тип "{s}" не описан');
  end;
  
  if vec_l<>0 then
  begin
    var gl_t := s.pas_to_gl_t;
    if string.IsNullOrEmpty(gl_t) then raise new System.InvalidOperationException($'Нельзя сделать вектор из типа {s}');
    s := $'Vec{vec_l}{gl_t}';
  end;
  
  s := '^'*rc + s;
  
  {$endregion TypeConv}
  
  var par_v := new List<par_data>;
  
  if s.Count(ch->ch='^')=1 then
  begin
    s := s.Substring(1);
    if s='pointer' then s := 'IntPtr';
    
    if is_ret then
    begin
      par_v += new par_data('{0}', 'pointer', nil,  nil);
      s := 'IntPtr';
    end else
    begin
      par_v += new par_data(nil,  $'{{0}}: array of {s}', '{0}[0]', nil);
      par_v += new par_data(nil,  $'var {{0}}: {s}',      '@{0}',   nil);
      par_v += new par_data(nil,   '{0}: pointer',        '{0}',    nil);
      s := 'pointer';
    end;
    
    Result := ('pointer', par_v);
  end else
  
  if s='string' then
  begin
    
    if is_ret then
    begin
      par_v += new par_data('{0}_Str',  'string',  nil,  'Marshal.PtrToStringAnsi({0})');
      par_v += new par_data('{0}',      'IntPtr',  nil,  nil);
    end else
    begin
      par_v += new par_data(nil,  '{0}: string',  $'ptr{par_n}',  $'var ptr{par_n} := Marshal.StringToHGlobalAnsi({{1}}); {{0}} Marshal.FreeHGlobal(ptr{par_n});');
      par_v += new par_data(nil,  '{0}: IntPtr',  '{0}',          nil);
    end;
    
    Result := ('IntPtr', par_v);
  end else
  
  begin
    
    if is_ret then
      par_v += new par_data('{0}',  s,              '{0}',  nil) else
      par_v += new par_data('{0}',  $'{{0}}: {s}',  '{0}',  nil);
    
    if s.StartsWith('^') then s := 'pointer';
    Result := (s, par_v);
  end;
  
end;

type
  FuncDef = class
    
    lib_name := 'opengl32.dll';
    
    name_header, name, full_name: string;
    
    res_t: string;
    res_masks: List<par_data>;
    
    par := new List<(string,sequence of par_data)>;
    
    
    
    constructor(s: string);
    begin
      
      s := s.Remove('GL_APIENTRY', 'GL_APICALL', 'GLAPI', 'GL_API', 'WINAPI', 'APIENTRY');
      
      var ind1 := s.IndexOf('(');
      var ind2 := s.LastIndexOf(')');
      
      begin
        var nts := s.Remove(ind1).Trim;
        var ind := nts.LastIndexOf('*');
        if ind=-1 then ind := nts.LastIndexOf(' ');
        
        full_name := nts.Substring(ind+1).Trim(' ');
        
        name_header := nil;
        foreach var pnh in Arr('wgl', 'egl', 'glX', 'glu', 'gl') do
          if full_name.StartsWith(pnh) then
          begin
            name_header := pnh;
            name := full_name.SubString(pnh.Length);
            break;
          end;
        if name_header=nil then
        begin
          name_header := '';
          name := full_name;
          lib_name := 'gdi32.dll';
        end;
        if name.ToLower() in keywords then name := '&'+name;
        
//        writeln((nts.Remove(ind+1),name));
        var t := GetTypeDefString(true, 0, nts.Remove(ind+1), 0);
        res_t := t[0];
        res_masks := t[1];
        
      end;
      
      var par_n := 1;
      foreach var p in s.Substring(ind1+1,ind2-ind1-1).Replace('*','* ').ToWords(',').Select(p->p.Trim(' ')) do
      begin
        if p = 'void' then if par_n<>1 then raise new System.InvalidOperationException else break;
        var ind := p.LastIndexOf(' ');
        
        var pname := p.Substring(ind+1);
        
        var vec_l := 0;
        if pname.Contains('[') then
        begin
          if not pname.EndsWith(']') then raise new System.ArgumentException($'Ошибка синтаксиса параметра "{pname}"');
          var b_ind := pname.IndexOf('[');
          vec_l := pname.SubString(b_ind+1).TrimEnd(']').ToInteger;
          pname := pname.Remove(b_ind);
        end;
        
        var cpar := GetTypeDefString(false, par_n, p.Remove(ind), vec_l);
        
        if pname in keywords then pname := '&'+pname else
        if pname=cpar[0] then pname := '_'+pname else
        if pname.ToLower=name.ToLower then pname := '_'+pname;
        
        par += (
          $'{pname}: {cpar[0]}',
          cpar[1].ConvertAll(d->
          begin
            var lpname := pname;
            
            if d.par_def_mask.ToLower.EndsWith(' '+lpname.ToLower) then lpname := '_'+lpname else
            if d.par_def_mask.ToLower.Contains($' {lpname.ToLower} ') then lpname := '_'+lpname;
            
            Result := new par_data(
              nil,
              Format(d.par_def_mask, lpname),
              Format(d.par_call_mask, lpname),
              d.func_call_mask=nil?nil:Format(d.func_call_mask, '{0}', lpname)
            );
            
          end).AsEnumerable
        );
        
        par_n += 1;
      end;
      
    end;
    
    public function ContructCode(use_external: boolean; params comments: array of string): string;
    begin
      if
        (lib_name='gdi32.dll') or
        (name in ['CreateContext', 'MakeCurrent'])
      then use_external := true;
      
      var sb := new StringBuilder;
      var f := res_t<>'void';
      
      sb += #10;
      
      
      
      if use_external then
      begin
        
        sb += '    private static ';
        sb += f?'function':'procedure';
        sb += ' _';
        sb += name.TrimStart('&');
        
        if par.Count<>0 then
        begin
          sb += '(';
          sb += par.Select(p->p[0]).JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += res_t;
        end;
        
        sb += $'; external ''{lib_name}'' name ''{full_name}'';';
        sb += #10;
        
        foreach var comm in comments do
          if comm<>nil then
          begin
            sb += '    ///';
            sb += comm;
            sb += #10;
          end;
        
        sb += '    public static z_';
        sb += name.TrimStart('&');
        sb += ': ';
        sb += f?'function':'procedure';
        if par.Count<>0 then
        begin
          sb += '(';
          sb += par.Select(p->p[0]).JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += res_t;
        end;
        sb += ' := _';
        sb += name.TrimStart('&');
        sb += ';'#10;
        
      end else
      begin
        
        foreach var comm in comments do
          if comm<>nil then
          begin
            sb += $'    ///{comm}';
            sb += #10;
          end;
        
        sb += '    public z_';
        sb += name.TrimStart('&');
        
        //ToDo ide#144
        sb += ': ';
        sb += f?'function':'procedure';
        if par.Count<>0 then
        begin
          sb += '(';
          sb += par.Select(p->p[0]).JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += res_t;
        end;
        
        sb += ' := GetGLFuncOrNil&<';
        sb += f?'function':'procedure';
        if par.Count<>0 then
        begin
          sb += '(';
          sb += par.Select(p->p[0]).JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += res_t;
        end;
        sb += '>(''';
        sb += full_name;
        sb += ''');'#10;
        
      end;
      
      
      
      foreach var res_mask in res_masks do
        foreach var pct in GetAllCombos(par.Select(p->p[1])).Append(nil).Pairwise do
        begin
          var par_combo := pct[0];
          
          sb += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          sb += f?'function':'procedure';
          sb += ' ';
          
          var cfname := Format(res_mask.fn_mask, name.TrimStart('&'));
          if cfname.ToLower in keywords then cfname := '&'+cfname;
          sb += cfname;
          
          if par.Count<>0 then
          begin
            sb += '(';
            sb += par_combo.Select(pd->pd.par_def_mask).JoinIntoString('; ');
            sb += ')';
          end;
          
          if f then
          begin
            sb += ': ';
            sb += res_mask.par_def_mask;
          end;
          
          var need_block := par_combo.Any(pd->pd.func_call_mask<>nil);
          
          sb += need_block ? '; begin ' : ' := ';
          
          var call_sb := new StringBuilder;
          if pct[1]=nil then
          begin
            call_sb += 'z_';
            call_sb += name.TrimStart('&');
          end else
            call_sb += name;
          if par.Count<>0 then
          begin
            call_sb += '(';
            call_sb += par_combo.Select(pd->pd.par_call_mask).JoinIntoString(', ');
            call_sb += ')';
          end;
          var call_str := call_sb.ToString;
          
          if f then
          begin
            if res_mask.func_call_mask<>nil then call_str := Format(res_mask.func_call_mask, call_str);
            if need_block then call_str := 'Result := '+call_str;
          end;
          call_str += ';';
          
          foreach var pd in par_combo do
            if pd.func_call_mask<>nil then
              call_str := Format(pd.func_call_mask, call_str);
          
          sb += call_str;
          
          if need_block then sb += ' end;';
          
          sb += #10;
        end;
      
      sb += '    ';
      Result := sb.ToString;
    end;
    
    
    
    public function ToString: string; override :=
    $'FuncDef[{full_name}]';
    
  end;

function ReadGLFuncs(text: string): sequence of FuncDef :=
  text.Remove(#13)
  .SkipCharsFromTo2('/*', '*/')
  .JoinIntoString('')
  .ToWords(#10)
  .Where(l->l.Contains('('))
  .Where(l-> not(
    l.Contains('typedef') or
    l.Contains('#') or
    l.Contains('DECLARE_HANDLE')
  ))
  .Select(l->FuncDef.Create(l))
;

end.