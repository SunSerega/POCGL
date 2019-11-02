unit FuncFormatData;
{$reference System.Windows.Forms.dll}

uses FuncOverloadControlData;

//Форматирование функции состоит из 3 частей:
// - 1. Получение имён и перевод изначальных типов (native_par_data)
// - 2.1. Получение всех возможных перегрузок через OverloadControl T%3. Если nil то:
// - 2.2. Получение всех возможных перегрузок из native_par_data. Тут применяются OverloadControl T%1,T%2
// - 3. Преобразование в par_masks, с добавлением всех масок вызовов и т.п.
// 
// - Тип результата обрабатывается последним в T%1
// - Если нативный тип это указатель - все не_массивы становятся var-параметрами
// - Массив превращаются в передачу [0] var-параметром
// - Строки разворачиваются в извращения с Marshal (и потом IntPtr, конечно)

var
  keywords := HSet('begin', 'end', 'params', 'type', 'end', 'program', 'array', 'unit', 'label', 'event', 'in', 'packed', 'property');
  num_chrs := Range('0','9').ToArray;

{$region Misc utils}

type
  
  native_par_data = auto class
    pname, ptype: string;
    pspec_t: string; // к примеру "string", ибо ptype будет всегда нативный (IntPtr если string). Или просто pspec_t=ptype
  end;
  
  par_data = auto class
    par_def: string;        // param def
    par_call: string;       // param call
    func_call_mask: string; // function call: {0}=prev func call
    fn_mask: string;        // function name: {0}=prev name
    gen_par: string;        // generic param name
  end;
  
procedure LoadOverloadControlFolder(path: string);
begin
  foreach var fname in System.IO.Directory.EnumerateFiles(path,'*.cfg',System.IO.SearchOption.AllDirectories) do
    OverloadController.LoadAllFromFile(fname);
end;

function GetUnusedOverloadControllers := OverloadController.GetUnused;

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

function TraslateType(pname, tname: string; vec_l: integer): native_par_data;
begin
  
  var rc := tname.Count(ch->ch='*');
  tname := tname.Remove('const*', 'const ', ' ', '*', #13, #10, #9);
  
  case tname.ToLower of
    
    'bool':                     tname := 'UInt32';
    'boolean':                  tname := 'UInt32';
    'eglboolean':               tname := 'UInt32';
    
    'glbyte':                   tname := 'SByte';
    'glboolean':                tname := 'boolean';
    'glubyte':                  tname := 'Byte';
    
    'glshort':                  tname := 'Int16';
    'glushort':                 tname := 'UInt16';
    'ushort':                   tname := 'UInt16';
    
    'glint':                    tname := 'Int32';
    'eglint':                   tname := 'Int32';
    'glsizei':                  tname := 'Int32';
    'glclampx':                 tname := 'Int32';
    'int':                      tname := 'Int32';
    'sizei':                    tname := 'Int32';
    'int32':                    tname := 'Int32';
    'int32_t':                  tname := 'Int32';
    'gluint':                   tname := 'UInt32';
    'uint':                     tname := 'UInt32';
    'dword':                    tname := 'UInt32';
    'unsignedint':              tname := 'UInt32';
    
    'glint64':                  tname := 'Int64';
    'glint64ext':               tname := 'Int64';
    'int64':                    tname := 'Int64';
    'int64_t':                  tname := 'Int64';
    'gluint64':                 tname := 'UInt64';
    'gluint64ext':              tname := 'UInt64';
    'unsignedlong':             tname := 'UInt64';
    'uint64':                   tname := 'UInt64';
    
    'glfloat':                  tname := 'single';
    'glclampf':                 tname := 'single';
    'float':                    tname := 'single';
    'gldouble':                 tname := 'double';
    'glclampd':                 tname := 'double';
    
    'glfixed':                  tname := 'fixed';
    'glhalfnv':                 tname := 'half';
    
    'glintptr':                 tname := 'IntPtr';
    'glintptrarb':              tname := 'IntPtr';
    'proc':                     tname := 'IntPtr'; // wglGetProcAddress
    'handle':                   tname := 'IntPtr';
    'lpvoid':                   tname := 'IntPtr';
    'glsizeiptr':               tname := 'UIntPtr';
    'glsizeiptrarb':            tname := 'UIntPtr';
    'sizeiptr':                 tname := 'UIntPtr';
    
    'enum':                     tname := 'DummyEnum';
    'glenum':                   tname := 'DummyEnum';
    'eglenum':                  tname := 'DummyEnum';
    'bitfield':                 tname := 'DummyFlags';
    'glbitfield':               tname := 'DummyFlags';
    
    'egltimekhr':               tname := 'TimeSpan';
    
    'glsync':                   tname := 'GLsync';
    'sync':                     tname := 'GLsync';
    'eglsynckhr':               tname := 'EGLsync';
    'egldisplay':               tname := 'EGLDisplay';
    'glunurbsobj':              tname := 'GLUnurbs';
    'glxwindow':                tname := 'GLXWindow';
    'window':                   tname := 'GLXWindow';
    'glxpixmap':                tname := 'GLXPixmap';
    'pixmap':                   tname := 'GLXPixmap';
    'colormap':                 tname := 'GLXColormap';
    'dmparams':                 tname := 'GLXDMparams';
    'dmbuffer':                 tname := 'GLXDMbuffer';
    'vlserver':                 tname := 'GLXVLServer';
    'vlpath':                   tname := 'GLXVLPath';
    'vlnode':                   tname := 'GLXVLNode';
    'status':                   tname := 'GLXStatus';
    'glxdrawable':              tname := 'GLXDrawable';
    'glxcontext':               tname := 'GLXContext';
    'glxpbuffer':               tname := 'GLXPbuffer';
    'glxpbuffersgix':           tname := 'GLXPbuffer';
    'glxfbconfig':              tname := 'GLXFBConfig';
    'glxfbconfigsgix':          tname := 'GLXFBConfig';
    'glxcontextid':             tname := 'GLXContextID';
    'glxvideosourcesgix':       tname := 'GLXVideoSourceSGIX';
    'glxvideocapturedevicenv':  tname := 'GLXVideoCaptureDeviceNV';
    'glxvideodevicenv':         tname := 'GLXVideoDeviceNV';
    '__glxextfuncptr':          tname := 'GLXFuncPtr';
    'gleglimageoes':            tname := 'GLeglImageOES';
    'glhandlearb':              tname := 'GLhandleARB';
    'hgpunv':                   tname := 'GPUAffinityHandle';
    'hvideooutputdevicenv':     tname := 'VideoOutputDeviceHandleNV';
    'hvideoinputdevicenv':      tname := 'VideoInputDeviceHandleNV';
    'hpvideodev':               tname := 'VideoDeviceHandleNV';
    'gleglclientbufferext':     tname := 'GLeglClientBufferEXT';
    'glvdpausurfacenv':         tname := 'GLvdpauSurfaceNV';
    'hpbufferext':              tname := 'PBufferName';
    'lpcstr':                   tname := 'string';
    'hpbufferarb':              tname := 'PBufferName';
    'hdc':                      tname := 'GDI_DC';
    'pixelformatdescriptor':    tname := 'GDI_PixelFormatDescriptor';
    'henhmetafile':             tname := 'GDI_HENHMetafile';
    'layerplanedescriptor':     tname := 'GDI_LayerPlaneDescriptor';
    'colorref':                 tname := 'GDI_COLORREF';
    'hglrc':                    tname := 'GLContext';
    
    'glxhyperpipenetworksgix':  tname := 'GLXHyperpipeNetworkSGIX';
    'glxhyperpipeconfigsgix':   tname := 'GLXHyperpipeConfigDataSGIX';
    'glxpiperect':              tname := 'GLXPipeRect';
    'glxpiperectlimits':        tname := 'GLXPipeRectLimits';
    'pgpu_device':              tname := '^GPU_Device_Affinity_Info';
    'lpglyphmetricsfloat':      tname := '^GDI_GlyphmetricsFloat';
    
    'display', 'xvisualinfo':
    if rc<>0 then
    begin
      tname := 'P' + tname;
      rc -= 1;
    end else
      raise new System.InvalidOperationException($'Запись "{tname}" не описана полностью в данной версии, доступны только указатели на неё');
    
    'struct_cl_context':      tname := 'cl_context';
    'struct_cl_event':        tname := 'cl_event';
    
    'gldebugproc':            tname := 'GLDEBUGPROC';
    'gldebugprocarb':         tname := 'GLDEBUGPROC';
    'gldebugprocamd':         tname := 'GLDEBUGPROC';
    'gldebugprockhr':         tname := 'GLDEBUGPROC';
    'glvulkanprocnv':         tname := 'GLVULKANPROCNV';
    
    'glvoid',
    'void':
    if rc<>0 then
    begin
      tname := 'pointer';
      rc -= 1;
    end else
      tname := 'void';
    
    'glchar',
    'char',
    'glchararb':
    if rc<>0 then
    begin
      tname := 'string';
      rc -= 1;
    end else
      tname := 'Byte';
    
    else raise new System.ArgumentException($'Тип "{tname}" не описан');
  end;
  
  tname := '^'*rc + tname;
  
  if vec_l<>0 then
  begin
    var gl_t := tname.pas_to_gl_t;
    if string.IsNullOrEmpty(gl_t) then raise new System.InvalidOperationException($'Нельзя сделать вектор из типа {tname}');
    tname := $'Vec{vec_l}{gl_t}';
  end;
  
  var native_t :=
    tname[1]='^'?   'pointer':
    tname='string'? 'IntPtr':
  tname;
  
  // array of string => array of IntPtr
  if tname[1]='^' then tname := tname.Replace('pointer','IntPtr').Replace('string','IntPtr');
  
  Result := new native_par_data(pname, native_t, tname);
end;

function GetAllOverloads(tname: string): sequence of string;
begin
  if tname='string' then Result := Seq('string','IntPtr') else
  if tname[1]='^' then
  begin
    tname := tname.Count(ch->ch='^')=1 ? tname.Substring(1) : 'IntPtr';
    Result := Seq('array of '+tname, tname, 'pointer');
  end else
    Result := Seq(tname);
end;

// ptype = тип перегрузки: (array of A,A,pointer), (string,IntPtr), (A)
// pname = имя параметра
// pnt   = переведённый неуправляемый тип параметра, как "^A"
// is_ret - true если Result а не параметр
// par_n - номер параметра, нумеруется с 1
function GetTypeMasks(ptype, pname, pnt: string; is_ret: boolean; par_n: integer): par_data;
begin
  var generic: string := nil;
  if ptype.TrimEnd(num_chrs) in ['array of T', 'T'] then
    generic := ptype.Substring(ptype.LastIndexOf(' ')+1);
  
  if ptype.StartsWith('array of ') or (ptype='&Array') then
    Result := is_ret ?  nil : new par_data( $'{pname}: {ptype}', $'pointer(Marshal.UnsafeAddrOfPinnedArrayElement({pname},0))', nil, nil, generic ) else
  
  if ((pnt[1]='^') or ((pnt='pointer') and not (ptype='IntPtr'))) and (ptype<>'pointer') then
    Result := is_ret ?  nil : new par_data( $'var {pname}: {ptype}', '@'+pname, nil, nil, generic ) else
  
  if ptype = 'string' then Result := new par_data(
    
    is_ret ? 'string'                       : $'{pname}: {ptype}',
    is_ret ? nil                            : $'ptr_{par_n}',
    is_ret ? 'Marshal.PtrToStringAnsi({0})' : $'var ptr_{par_n} := Marshal.StringToHGlobalAnsi({pname}); {{0}} Marshal.FreeHGlobal(ptr_{par_n});',
    is_ret ? '{0}_Str'                      : nil,
    generic
    
  ) else Result := new par_data(
    
    is_ret?ptype:$'{pname}: {ptype}',
    (ptype='IntPtr')and(pnt='pointer') ? $'pointer({pname})' : pname,
    nil,
    '{0}',
    generic
    
  );
  
end;

type
  FuncDef = class
    
    lib_name := 'opengl32.dll';
    
    name_header, name, full_name: string;
    f: boolean;
    
    nativ_par := new List<string>;
    par_masks := new List<List<par_data>>;
    
    
    
    static PrevFuncs := new HashSet<string>;
    
    constructor(s: string);
    begin
      
      s := s.Remove('GL_APIENTRY', 'GL_APICALL', 'GLAPI', 'GL_API', 'WINAPI', 'APIENTRY');
      
      var nativ_par_ts := new List<native_par_data>;
      
      var ind1 := s.IndexOf('(');
      var ind2 := s.LastIndexOf(')');
      
      {$region Stage 1 (native_par_data)}
      
      var nativ_ret_t: native_par_data;
      begin
        var nts := s.Remove(ind1).Trim;
        var ind := nts.LastIndexOf('*');
        if ind=-1 then ind := nts.LastIndexOf(' ');
        
        self.full_name := nts.Substring(ind+1).Trim(' ');
        if not PrevFuncs.Add(full_name) then
        begin
          self.lib_name := nil;
          exit;
        end;
        
//        full_name.Println;
        
//        if full_name='glGetString' then
//        begin
//          s := s;
//        end;
        
        self.name_header := nil;
        foreach var pnh in Arr('wgl', 'egl', 'glX', 'glu', 'gl') do
          if full_name.StartsWith(pnh) then
          begin
            self.name_header := pnh;
            self.name := full_name.SubString(pnh.Length);
            break;
          end;
        if name_header=nil then
        begin
          self.name_header := '';
          self.name := full_name;
          self.lib_name := 'gdi32.dll';
        end;
        if name.ToLower() in keywords then self.name := '&'+name;
        
        nativ_ret_t := TraslateType(nil, nts.Remove(ind+1), 0);
        
        {$region special rules}
        
        if full_name in ['glGetString','glGetStringi'] then
        begin
          nativ_ret_t.pspec_t := 'string';
          nativ_ret_t.ptype := 'IntPtr';
        end;
        
        {$endregion special rules}
        
      end;
      self.f := nativ_ret_t.ptype<>'void';
      
      var par_n := 1;
      foreach var p in s.Substring(ind1+1,ind2-ind1-1).Replace('*','* ').ToWords(',').Select(p->p.Trim) do
      begin
        if p = 'void' then if par_n<>1 then raise new System.InvalidOperationException else break;
        var ind := p.LastIndexOf(' ');
        
        var pname := p.Substring(ind+1);
        
        var vec_l := 0;
        if pname.Contains('[') then
        begin
          if not pname.EndsWith(']') then raise new System.ArgumentException($'Ошибка синтаксиса параметра "{pname}" в "{s}"');
          var b_ind := pname.IndexOf('[');
          vec_l := pname.SubString(b_ind+1).TrimEnd(']').ToInteger;
          pname := pname.Remove(b_ind);
        end;
        
        var cpar := TraslateType(pname, p.Remove(ind), vec_l);
        
        if pname in keywords then           pname := '&'+pname else
        if pname.ToLower=name.ToLower then  pname := '_'+pname else
        if pname='pointer' then             pname := '_'+pname else
        ;
        cpar.pname := pname;
        
        {$region special rules}
        
        if full_name in [
          'glDrawRangeElementsBaseVertex',
          'glDrawRangeElements',
          'glDrawElementsInstancedBaseVertexBaseInstance',
          'glDrawElementsInstancedBaseVertex',
          'glDrawElementsInstancedBaseInstance',
          'glDrawElementsInstanced',
          'glDrawElementsBaseVertex',
          'glDrawElements'
        ] then if pname='indices' then
          cpar.pspec_t := '^Void';
        
        {$endregion special rules}
        
        nativ_par_ts += cpar;
        
        par_n += 1;
      end;
      if f then nativ_par_ts += nativ_ret_t;
      
      {$endregion Stage 1 (native_par_data)}
      
//      if full_name='glGetDebugMessageLogAMD' then
//      begin
//        full_name := full_name;
//      end;
      
      var all_ovr_types: List<List<string>>;
      
      {$region Stage 2 (OverloadControl + all overloads)}
      
      var ovr_change: IOverloadChange;
      begin
        var ovr_controller := OverloadController[full_name];
        if ovr_controller=nil then ovr_controller := OverloadController.ContructNewEmpty(full_name, 'Text converters\FuncOverloadControl\0missing.cfg');
        ovr_change := ovr_controller.GetChange;
      end;
      
      all_ovr_types := ovr_change.MakeAllOverloads;
      if all_ovr_types=nil then
      begin
        all_ovr_types := new List<List<string>>;
        all_ovr_types += new List<string>;
        
        par_n := 0;
        foreach var npt in nativ_par_ts do
        begin
          var n_all_ovr_types := new List<List<string>>;
          
          var cts := ovr_change.ApplyToOneOfMasks(par_n, GetAllOverloads(npt.pspec_t).Select(ovr_change.ApplyToSingleMask) ).ToList;
          foreach var l in all_ovr_types do
            foreach var ct in cts do
            begin
              var nl := new List<string>(l.Count+1);
              nl.AddRange(l);
              nl += ct;
              n_all_ovr_types += nl;
            end;
          
          all_ovr_types := n_all_ovr_types;
          par_n += 1;
        end;
        
      end;
      
      if all_ovr_types.Count > 15 then Writeln($'WARNING: too many ({all_ovr_types.Count}) overloads of "{full_name}" func');
      
      {$endregion Stage 2 (OverloadControl + all overloads)}
      
      {$region Stage 3 (GetTypeMasks)}
      
      var n_nativ_par_ts := new string[all_ovr_types[0].Count];
      foreach var n_ovr in all_ovr_types do
      begin
        var ovr := new List<par_data>;
        
        for var i := 0 to n_ovr.Count-1 do
        begin
          var is_ret := f and (i=n_ovr.Count-1);
          var pname := nativ_par_ts[i].pname;
          if pname<>nil then if n_ovr[i].ToLower.EndsWith(' '+pname.ToLower) or (n_ovr[i].ToLower=pname.ToLower) then pname := '_'+pname;
          
          var pdata := GetTypeMasks(n_ovr[i], pname, nativ_par_ts[i].pspec_t, is_ret,i+1);
          ovr += pdata;
          if pdata=nil then break;
          
          n_nativ_par_ts[i] := n_ovr[i];
          
          if    not is_ret
            and not (nativ_par_ts[i].pspec_t[1]='^')
            and not n_ovr[i].StartsWith('array of ')
            and not (n_ovr[i]='&Array')
            and not n_ovr[i].EndsWith('Name')
            and not (n_ovr[i] in ['pointer','IntPtr', 'Int32','UInt32','boolean'])
            and all_ovr_types.Any(l->l[i] in ['Int32', 'UInt32'])
          then
          begin
            pdata.par_call += '.val';
            n_nativ_par_ts[i] := 'UInt32';
          end else
          
          if Arr('glGetInteger','glGetFloat','glGetDouble','glGetBoolean','glGetPointer').Any&<string>(full_name.StartsWith) and (i=0) and (n_ovr[i]<>'GLGetQueries') then
          begin
            pdata.par_call := $'new GLGetQueries({pdata.par_call}.val)';
            n_nativ_par_ts[i] := 'GLGetQueries';
          end;
          
        end;
        
        if not ovr.Contains(nil) then par_masks += ovr;
      end;
      
      for var i := 0 to nativ_par_ts.Count-1 do
      begin
        var pname := nativ_par_ts[i].pname;
        var ptype := n_nativ_par_ts[i];
        
        if pname=ptype then pname := '_'+pname;
        
        self.nativ_par += f and (i=nativ_par_ts.Count-1) ? ptype : $'{pname}: {ptype}';
      end;
      
      {$endregion Stage 3 (GetTypeMasks)}
      
    end;
    
    public function ContructCode(use_external: boolean; params comments: array of string): string;
    begin
      if
        (lib_name='gdi32.dll') or
        (full_name in ['wglCreateContext', 'wglMakeCurrent'])
      then use_external := true;
      
      var sb := new StringBuilder;
      var has_par := nativ_par.Count-integer(f) <> 0;
      var only_nativ_par := f?nativ_par.SkipLast:nativ_par;
      
      sb += #10;
      
//      if full_name='glGetBooleanv' then
//      begin
//        full_name := full_name;
//      end;
      
      
      
      if use_external then
      begin
        
        sb += '    private static ';
        sb += f?'function':'procedure';
        sb += ' _';
        sb += name.TrimStart('&');
        
        if has_par then
        begin
          sb += '(';
          sb += only_nativ_par.JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += nativ_par[nativ_par.Count-1];
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
        
        if f and not has_par then
        begin
          sb += ': ';
          sb += f?'function':'procedure';
          if has_par then
          begin
            sb += '(';
            sb += only_nativ_par.JoinIntoString('; ');
            sb += ')';
          end;
          if f then
          begin
            sb += ': ';
            sb += nativ_par[nativ_par.Count-1];
          end;
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
        
        sb += ' := GetGLFuncOrNil&<';
        sb += f?'function':'procedure';
        if has_par then
        begin
          sb += '(';
          sb += only_nativ_par.JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += nativ_par[nativ_par.Count-1];
        end;
        sb += '>(''';
        sb += full_name;
        sb += ''');'#10;
        
      end;
      
      
      
//      writeln(full_name);
      for var i := 0 to par_masks.Count-1 do
      begin
        var par_combo := par_masks[i];
//        par_combo.Println;
        var only_par := f?par_combo.SkipLast:par_combo;
        
        sb += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
        if lib_name='gdi32.dll' then sb += 'static ';
        sb += f?'function':'procedure';
        sb += ' ';
        
        var fn_mask := f ? par_combo[par_combo.Count-1].fn_mask : nil;
        var cfname := fn_mask=nil ? name : Format(fn_mask, name.TrimStart('&'));
        if cfname.ToLower in keywords then cfname := '&'+cfname;
        sb += cfname;
        
        var generic := par_combo.ConvertAll(pd->pd.gen_par);
        generic.RemoveAll(s->s=nil);
        if generic.Count<>0 then
        begin
          sb += '<';
          sb += generic.JoinIntoString(', ');
          sb += '>';
        end;
        
        if has_par then
        begin
          sb += '(';
          sb += only_par.Select(pd->pd.par_def).JoinIntoString('; ');
          sb += ')';
        end;
        if f then
        begin
          sb += ': ';
          sb += par_combo[par_combo.Count-1].par_def;
        end;
        
        var need_block := only_par.Any(pd->pd.func_call_mask<>nil) or (generic.Count<>0);
        
        if need_block then
        begin
          sb += '; ';
          if generic.Count<>0 then
          begin
            sb += 'where ';
            sb += generic.JoinIntoString(', ');
            sb += ': record; ';
          end;
          sb += 'begin ';
        end else
          sb += ' := ';
        
        var call_sb := new StringBuilder;
        if i=par_masks.Count-1 then
        begin
          call_sb += 'z_';
          call_sb += name.TrimStart('&');
        end else
          call_sb += name;
        if has_par then
        begin
          call_sb += '(';
          call_sb += only_par.Select(pd->pd.par_call).JoinIntoString(', ');
          call_sb += ')';
        end;
        var call_str := call_sb.ToString;
        
        if f then
        begin
          var func_call_mask := par_combo[par_combo.Count-1].func_call_mask;
          if func_call_mask<>nil then call_str := Format(func_call_mask, call_str);
          if need_block then call_str := 'Result := '+call_str;
        end;
        call_str += ';';
        
        if need_block then
          foreach var pd in only_par do
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
  
  FuncDefEqComp = sealed class(System.Collections.Generic.IEqualityComparer<FuncDef>)
    
    constructor :=
    inherited Create;
    
    public function Equals(x, y: FuncDef): boolean :=
    x.full_name=y.full_name;
    
    public function GetHashCode(obj: FuncDef): integer :=
    obj.full_name.GetHashCode;
    
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
  .Where(fd->fd.lib_name<>nil)
;

end.