uses PackingUtils in '..\PackingUtils.pas';
uses CoreFuncData in '..\..\SpecFormating\GL\CoreFuncData.pas';
uses BinSpecData in '..\..\SpecFormating\GLExt\BinSpecData.pas';
uses FuncFormatData in '..\..\Text converters\FuncFormatData.pas';

{$region Misc types}

type
  ListSeqEqualityComparer<T> = class(IEqualityComparer<List<T>>)
    public constructor := exit;
    public static val := new ListSeqEqualityComparer<T>;
    
    public function Equals(x, y: List<T>): boolean :=
    x.SequenceEqual(y);
    
    public function GetHashCode(obj: List<T>): integer :=
    obj.Count=0?0:obj[0].GetHashCode;
    
  end;
  
  IntListComparer = class(Comparer<List<integer>>)
    public constructor := exit;
    public static val: Comparer<List<integer>> := new IntListComparer;
    
    public function Compare(x, y: List<integer>): integer; override;
    begin
      
      foreach var t in x.ZipTuple(y) do
      begin
        Result := t[0] - t[1];
        if Result<>0 then exit;
      end;
      
      Result := x.Count-y.Count;
    end;
    
  end;
  
  GLCoreVersion = sealed class
    data: array of integer;
    constructor(s: string) :=
    self.data := s.ToWords('.').ConvertAll(s->s.ToInteger);
    
    static function LoadAll: sequence of GLCoreVersion :=
      ReadLines('SpecFormating\GL\versions order.dat')
      .Where(l->l.Contains('='))
      .Reverse
      .Select(l-> new GLCoreVersion(l.Split('=')[0].TrimEnd(#9)) )
    ;
    
    function LoadFuncs: List<CoreFuncDef>;
    begin
      var br := new System.IO.BinaryReader(System.IO.File.OpenRead($'SpecFormating\GL\{self} funcs.bin'));
      Result := new List<CoreFuncDef>(br.ReadInt32);
      loop Result.Capacity do Result += CoreFuncDef.Load(br);
      br.Close;
    end;
    
    public function ToString: string; override :=
    data.JoinIntoString('.');
    
  end;
  
  EmptyList<T> = class
    
    static val := new List<T>;
    
  end;
  
{$endregion Misc types}

{$region var}

var ext_types := new List<string>;

var unused_core_funcs := new HashSet<CoreFuncDef>(new CoreFuncEqComp);
var core_funcs := new List<(GLCoreVersion,List<CoreFuncDef>)>;
var core_func_version_table := new Dictionary<CoreFuncDef,GLCoreVersion>(new CoreFuncEqComp);
var func_name_core_func_table := new Dictionary<string,CoreFuncDef>;

var incomplete_funcs := new HashSet<string>;
var func_name_ext_name_table := new Dictionary<string, List<string>>;
var ext_name_func_name_table := new Dictionary<List<string>, HashSet<string>>(ListSeqEqualityComparer&<string>.val);

var h_funcs := new List<FuncDef>;

// class name => ext names (or string[0]) => funcs
var funcs_sorted := new Dictionary<string, Dictionary<List<string>,List<FuncDef>> >;

{$endregion var}

{$region Main body procs}

procedure LoadMisc;
begin
  Otp('Misc loading');
  
  foreach var dir in System.IO.Directory.EnumerateDirectories('Reps\OpenGL-Registry\extensions') do
    ext_types += dir.Substring(dir.LastIndexOf('\')+1);
  
  LoadOverloadControlFolder('Text converters\FuncOverloadControl\GL');
  
end;

procedure LoadCoreFuncs;
begin
  Otp('Loading core funcs');
  
  foreach var v in GLCoreVersion.LoadAll do
  begin
    var funcs := v.LoadFuncs;
    core_funcs += (v, funcs);
    foreach var fd in funcs do
      if not unused_core_funcs.Contains(fd) then
      begin
        unused_core_funcs += fd;
        core_func_version_table.Add(fd, v);
        func_name_core_func_table.Add(fd.name, fd);
      end;
  end;
  
//  func_name_core_func_table.Keys.Sorted.PrintLines;
//  halt;
  
//  unused_core_funcs.PrintLines(fd->fd.name);
//  halt;
end;

procedure LoadExtFuncs;
begin
  Otp('Loading ext funcs');
  
  var ext_spec_db := BinSpecDB.LoadFromFile('SpecFormating\GLExt\ext spec.bin');
  
  // функции из расширений которые покалечены
  func_name_ext_name_table['glBlendFuncSeparateINGR'] := Lst('GL_INGR_blend_func_separate');
  
  foreach var ext in ext_spec_db.exts do
    if ext.NewFuncs<>nil then
      foreach var func in ext.NewFuncs.funcs.Select(t->t[0]) do
        if ext.is_complete then
        begin
          incomplete_funcs.Remove(func);
          if not func_name_ext_name_table.ContainsKey(func) then
            func_name_ext_name_table[func] := new List<string>;
          func_name_ext_name_table[func].AddRange(ext.ExtNames.names);
        end else
        if not func_name_ext_name_table.ContainsKey(func) and not func_name_core_func_table.ContainsKey(func) then
          incomplete_funcs += func;
  
//  func_name_ext_name_table.Keys.Sorted.PrintLines;
//  halt;
  
//  incomplete_funcs.PrintLines;
//  halt;
  
  foreach var key in func_name_ext_name_table.Keys do
  begin
    var val := func_name_ext_name_table[key];
    if not ext_name_func_name_table.ContainsKey(val) then
      ext_name_func_name_table[val] := new HashSet<string>;
    ext_name_func_name_table[val].Add(key);
  end;
  ext_name_func_name_table.Add(new List<string>, new HashSet<string>);
  
end;

procedure ReadHFuncs;
begin
  Otp('Read funcs from .h''s');
  
  var all_header_files :=
    System.IO.Directory.EnumerateFiles('Reps\OpenGL-Registry',  '*.h', System.IO.SearchOption.AllDirectories) +
    System.IO.Directory.EnumerateFiles('Reps\GLBrokenSource',   '*.h', System.IO.SearchOption.AllDirectories)
  ;
  
  var prev := new HashSet<string>;
  foreach var fname in all_header_files do
  begin
    
    foreach var fd in ReadGLFuncs(ReadAllText(fname, new System.Text.UTF8Encoding(true))) do
      if not incomplete_funcs.Contains(fd.full_name) then
        if prev.Add(fd.full_name) then
          h_funcs += fd;
    
//    Otp($'done reading funcs from "{fname}"');
  end;
  
  h_funcs.Sort((fd1,fd2)->fd1.name.TrimStart('&').CompareTo(fd2.name.TrimStart('&')));
  
//  h_funcs.PrintLines(fd->fd.full_name);
//  halt;
  
  foreach var cn in GetUnusedOverloadControllers do
    Otp($'WARNING: OverloadController for func {cn} wasn''t used');
end;

procedure SortFuncs;
begin
  Otp('Sort funcs');
  
  var unused_exts := new HashSet<List<string>>(func_name_ext_name_table.Values, ListSeqEqualityComparer&<string>.val);
  
  funcs_sorted['gl'] := new Dictionary<List<string>, List<FuncDef>>(ListSeqEqualityComparer&<string>.val);
  funcs_sorted['gl'][EmptyList&<string>.val] := new List<FuncDef>;
  
  funcs_sorted['glD'] := new Dictionary<List<string>, List<FuncDef>>(ListSeqEqualityComparer&<string>.val);
  funcs_sorted['glD'][EmptyList&<string>.val] := new List<FuncDef>;
  
  funcs_sorted['wgl'] := new Dictionary<List<string>, List<FuncDef>>(ListSeqEqualityComparer&<string>.val);
  funcs_sorted['wgl'][EmptyList&<string>.val] := new List<FuncDef>;
  
  funcs_sorted['gdi'] := new Dictionary<List<string>, List<FuncDef>>(ListSeqEqualityComparer&<string>.val);
  funcs_sorted['gdi'][EmptyList&<string>.val] := new List<FuncDef>;
  
  for var i := h_funcs.Count-1 downto 0 do
  begin
    var fd: CoreFuncDef;
    
    if func_name_core_func_table.TryGetValue(h_funcs[i].full_name, fd) then
    begin
      if not unused_core_funcs.Remove(fd) then continue;
      
      funcs_sorted[
        core_func_version_table[fd] = core_funcs[0][0] ?
        'gl' : 'glD'
      ][EmptyList&<string>.val].Add( h_funcs[i] );
      
      h_funcs.RemoveAt(i);
    end;
    
  end;
  
//  func_name_ext_name_table.Keys.Sorted.PrintLines;
//  halt;
  
  while h_funcs.Count <> 0 do
  begin
    var ext_names: List<string>;
    if not func_name_ext_name_table.TryGetValue(h_funcs[0].full_name, ext_names) then
      if h_funcs[0].full_name.StartsWith('wgl') then
      begin
        funcs_sorted['wgl'][EmptyList&<string>.val].Add( h_funcs[0] );
        h_funcs.RemoveAt(0);
        continue;
      end else
      if h_funcs[0].lib_name='gdi32.dll' then
      begin
        funcs_sorted['gdi'][EmptyList&<string>.val].Add( h_funcs[0] );
        h_funcs.RemoveAt(0);
        continue;
      end else
      begin
        
        if not (h_funcs[0].full_name in [
          'glAlphaFuncx',
          'glClearColorx',
          'glClearDepthx',
          'glBlendBarrier',
          'glXChooseFBConfig'
        ]) then Otp($'WARNING: func "{h_funcs[0].full_name}" not found in core nor in exts');
        
        h_funcs.RemoveAt(0);
        continue;
      end;
      
    unused_exts.Remove(ext_names);
    var fs := new List<FuncDef>;
    
    foreach var fn in ext_name_func_name_table[ext_names] do
    begin
      var ind := h_funcs.FindIndex(f->f.full_name=fn);
      if ind <> -1 then
      begin
        fs += h_funcs[ind];
        h_funcs.RemoveAt(ind);
      end else
      if not func_name_core_func_table.ContainsKey(fn) then
        Otp($'WARNING: [{ext_names.JoinIntoString}]: can''t find func "{fn}"');
    end;
    
    var fs_cnames :=
      fs.ConvertAll(fd->
      begin
        case fd.name_header of
          'wgl':  Result := 'wgl';
          'egl':  Result := 'egl';
          'glu':  Result := 'glu';
          'glX':  Result := 'glX';
          '':     Result := 'gdi';
          else    Result := '';
        end;
      end)
    ;
    if fs_cnames.All(pnh->pnh='') then
    begin
      var ext_ts := fs.Select(fd->
      begin
        var ext_ts := ext_types.Where(ext_t->fd.name.EndsWith(ext_t)).ToList;
        if ext_ts.Count>1 then raise new System.ArgumentException($'func {fd.full_name} had multiple ext types: [{ext_ts.JoinIntoString}]');
        Result := ext_ts.Count=0?'ARB':ext_ts[0];
      end).Distinct.ToList;
      
      if ext_ts.Count=0 then
        raise new System.InvalidOperationException($'funcs of exts [{ext_names.JoinIntoString}] had no ext types') else
      if ext_ts.Count=1 then
        fs_cnames.Fill(i-> 'gl_'+ext_ts[0] ) else
      if ext_ts.Contains('EXT') then
        fs_cnames.Fill(i-> 'gl_EXT' ) else
        fs_cnames.Fill(i-> 'gl_ARB' );
      
    end;
    
    foreach var cname in fs_cnames.Where(cname->cname<>'').Distinct do
    begin
      var cfs := fs.ToList;
      for var i := fs_cnames.Count-1 downto 0 do
        if (fs_cnames[i]<>'') and (fs_cnames[i]<>cname) then
          cfs.RemoveAt(i);
      
      if not funcs_sorted.ContainsKey(cname) then
        funcs_sorted[cname] := new Dictionary<List<string>, List<FuncDef>>(ListSeqEqualityComparer&<string>.val);
      
      if funcs_sorted[cname].ContainsKey(ext_names) then
        raise new System.InvalidOperationException($'key = [{ext_names.JoinIntoString}], val1 = [{funcs_sorted[cname][ext_names].Select(fd->fd.full_name).JoinIntoString}], val2 = [{cfs.Select(fd->fd.full_name).JoinIntoString}]') else
        funcs_sorted[cname].Add(ext_names, cfs);
      
    end;
    
  end;
  
  foreach var f in unused_core_funcs do Otp( $'WARNING: core func "{f.name}" not found' );
  
  foreach var ext in unused_exts do
  begin
    var fs := ext_name_func_name_table[ext].ToList;
    if fs.Count=0 then continue;
    Otp($'WARNING: [{ext.JoinIntoString}]: funcs [{fs.JoinIntoString}] wasn''t found');
  end;
  
end;

procedure ConstructFuncsCode;
begin
  Otp($'Construct funcs code');
  var sw := new System.IO.StreamWriter(
    System.IO.File.Create(GetFullPath('..\Funcs.template',GetEXEFileName)),
    new System.Text.UTF8Encoding(true)
  );
  
  var min_core_funcs: HashSet<string> := core_funcs.Single(t->t[0].ToString='1.1')[1].Select(fd->fd.name).ToHashSet;
  
  {$region for each class}
  
  foreach var cname: string in funcs_sorted.Keys.OrderBy(cname->
  begin
    case cname of
      'gl':             Result := 00;
      'glD':            Result := 01;
      'wgl':            Result := 02;
      'egl':            Result := 03;
      'glu':            Result := 04;
      'glX':            Result := 05;
      'gl_ARB':         Result := 06;
      'gl_EXT':         Result := 07;
      
      'gdi':            Result := 21;
      
      else              Result := 10;
    end;
  end).ThenBy(cname->cname) do
  begin
    sw.WriteLine;
    sw.WriteLine($'  {cname} = sealed class');
    sw.WriteLine('    private static function _GetGLFuncAdr(lpszProc: IntPtr): IntPtr;'#10'    external ''opengl32.dll'' name ''wglGetProcAddress'';');
    sw.WriteLine('    public static GetGLFuncAdr := _GetGLFuncAdr;');
    sw.WriteLine('    public static function GetGLFuncOrNil<T>(fn: string): T;');
    sw.WriteLine('    begin');
    sw.WriteLine('      var str_ptr := Marshal.StringToHGlobalAnsi(fn);');
    sw.WriteLine('      var ptr := GetGLFuncAdr(str_ptr);');
    sw.WriteLine('      Marshal.FreeHGlobal(str_ptr);');
    sw.WriteLine('      Result := ptr=IntPtr.Zero ? default(T) : Marshal.GetDelegateForFunctionPointer&<T>(ptr);');
    sw.WriteLine('    end;');
    sw.Write('    ');
    
    {$region for each ext name list}
    
    foreach var ext_names in funcs_sorted[cname].Keys do
    begin
      var chap_st := new List<(integer,string)>;
      
      if ext_names.Count<>0 then
      begin
        sw.WriteLine;
        sw.WriteLine($'    {{$region {ext_names.JoinIntoString}}}');
        sw.Write('    ');
      end;
      
      {$region for each spec chapter}
      
      foreach var g in
        funcs_sorted[cname][ext_names]
        .GroupBy(
          fd->
          begin
            var cfd: CoreFuncDef;
            if func_name_core_func_table.TryGetValue(fd.full_name, cfd) then
              Result := cfd.chapter else
              Result := EmptyList&<(integer,string)>.val;
          end,
          ListSeqEqualityComparer&<(integer,string)>.val
        ).OrderBy(
          g->g.Key.ConvertAll(t->t[0]),
          IntListComparer.val
        ) do
      begin
        var curr_chap: List<(integer,string)> := g.Key;
        
        for var i := chap_st.Count-1 downto 0 do
        begin
          if (i<curr_chap.Count) and (curr_chap[i]=chap_st[i]) then break;
          sw.WriteLine;
          sw.WriteLine($'    {{$endregion {chap_st.Select(t->t[0]).JoinIntoString(''.'')} - {chap_st[i][1]}}}');
          sw.Write('    ');
          chap_st.RemoveLast;
        end;
        
        for var i := chap_st.Count to curr_chap.Count-1 do
        begin
          sw.WriteLine;
          sw.WriteLine($'    {{$region {curr_chap.Take(i+1).Select(t->t[0]).JoinIntoString(''.'')} - {curr_chap[i][1]}}}');
          sw.Write('    ');
          chap_st += curr_chap[i];
        end;
        
        foreach var fd in g do
          sw.Write(fd.ContructCode(
            min_core_funcs.Contains(fd.full_name),
            (cname<>'glD') or (curr_chap.Count=0)?nil:   $'OpenGL {core_func_version_table[func_name_core_func_table[fd.full_name]]}'
          ));
        
      end;
      
      {$endregion for each spec chapter}
      
      for var i := chap_st.Count-1 downto 0 do
      begin
        sw.WriteLine;
        sw.WriteLine($'    {{$endregion {chap_st.Select(t->t[0]).JoinIntoString(''.'')} - {chap_st[i][1]}}}');
        sw.Write('    ');
      end;
      
      if ext_names.Count<>0 then
      begin
        sw.WriteLine;
        sw.WriteLine($'    {{$endregion {ext_names.JoinIntoString}}}');
        sw.Write('    ');
      end;
      
    end;
    
    {$endregion for each ext name list}
    
    sw.WriteLine;
    sw.WriteLine($'  end;');
    sw.Write('  ');
  end;
  
  {$endregion for each class}
  
  sw.Close;
end;

{$endregion Main body procs}

begin
  try
    LoadMisc;
    
    LoadCoreFuncs;
    LoadExtFuncs;
    ReadHFuncs;
    
    SortFuncs;
    
    ConstructFuncsCode;
    
    Otp('done');
  except
    on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
    on e: Exception do ErrOtp(e);
  end;
end.