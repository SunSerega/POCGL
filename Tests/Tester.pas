program Tester;

{$string_nullbased+}

uses System;

uses '../POCGL_Utils';

uses '../Utils/AOtp';
uses '../Utils/ATask';
uses '../Utils/CLArgs';
uses '../Utils/Timers';
uses '../Utils/SubExecuters';
uses '../Utils/Testing/Testing';

{$reference System.Windows.Forms.dll}
type MessageBox               = System.Windows.Forms.MessageBox;
type MessageBoxButtons        = System.Windows.Forms.MessageBoxButtons;
type MessageBoxIcon           = System.Windows.Forms.MessageBoxIcon;
type MessageBoxDefaultButton  = System.Windows.Forms.MessageBoxDefaultButton;
type DialogResult             = System.Windows.Forms.DialogResult;

const MaxExecTime = 15000;

var valid_modules := HSet('Dummy', 'OpenCL','OpenCLABC', 'OpenGL','OpenGLABC');
var allowed_modules := new HashSet<string>(valid_modules.Count);

var auto_update := false;

type
  TestCanceledException = sealed class(Exception) end;
  
  //TODO Replace with MergedString
  {$region ExpectedText}
  
  ExpectedTextPart = sealed class
    s: string;
    constructor(s: string) := self.s := s;
    
    function NextInds(text: string; ind: integer): sequence of integer?;
    begin
      
      while ind+s.Length <= text.Length do
      begin
        ind := text.IndexOf(s, ind);
        if ind=-1 then exit;
        yield ind+s.Length;
        ind += 1;
      end;
      
    end;
    
  end;
  
  ExpectedText = sealed class
    parts: List<ExpectedTextPart>;
    
    constructor(text: string);
    begin
      if text=nil then exit;
      parts := new List<ExpectedTextPart>;
      var ind1 := 0;
      while true do
      begin
        var ind2 := text.IndexOf('*', ind1);
        if ind2=-1 then break;
        parts += new ExpectedTextPart(text.SubString(ind1, ind2-ind1));
        ind1 := ind2;
        while (ind1<text.Length) and (text[ind1] = '*') do
          ind1 += 1;
      end;
      parts += new ExpectedTextPart(text.Remove(0, ind1));
    end;
    
    function Matches(text: string): boolean;
    begin
      if text=nil then
      begin
        Result := parts=nil;
        exit;
      end;
      Result := false;
      if parts=nil then exit;
      
      case parts.Count of
        0: Result := text.Length=0;
        1: Result := text=parts[0].s;
        else
        begin
          if not text.StartsWith(parts[0].s) then exit;
          var min_ind := parts[0].s.Length;
          
          for var i := 1 to parts.Count-2 do
          begin
            var next_min_ind := parts[i].NextInds(text, min_ind).FirstOrDefault;
            if next_min_ind=nil then exit;
            min_ind := next_min_ind.Value;
          end;
          
          Result := text.Length = parts[parts.Count-1].NextInds(text, min_ind).LastOrDefault;
        end;
      end;
      
    end;
    
    public function ToString: string; override := parts?.Select(part->part.s).JoinToString('*');
    
  end;
  
  {$endregion ExpectedText}
  
  {$region DelegateCounter}
  
  DelegateCounter = static class
    
    private static procedure FindDelegatesInBin :=
    try
      var dom := System.AppDomain.CurrentDomain;
      var fname := string( dom.GetData('fname') );
      
      if not FileExists(fname) then
        raise new System.IO.FileNotFoundException(
          GetCurrentDir+#10+fname
        );
      var dir := System.IO.Path.GetDirectoryName(fname);
      
      var loaded := new Dictionary<string,System.Reflection.Assembly>;
      var load: (string,string)->System.Reflection.Assembly;
      load := (full_name, name)->
      begin
        if loaded.TryGetValue(name, Result) then exit;
        if full_name<>nil then
        try
          Result := System.Reflection.Assembly.ReflectionOnlyLoad(full_name);
        except
        end;
        if Result=nil then
          Result := System.Reflection.Assembly.ReflectionOnlyLoadFrom(System.IO.Path.Combine(dir,name));
        loaded.Add(name, Result);
        foreach var a in Result.GetReferencedAssemblies do
          load(a.FullName, a.Name+'.dll');
      end;
      
      var a := load(nil,fname);
      try
        
        var all_delegates := new List<string>;
        foreach var t: System.Type in a.GetTypes do
        begin
          if t.Namespace in |'PABCSystem','PABCExtensions'| then continue;
          if not t.IsSubclassOf(typeof(System.Delegate)) then continue;
          var res := new StringBuilder;
          res += t.Namespace;
          res += '.';
          if t.DeclaringType<>nil then
          begin
            res += TypeToTypeName(t.DeclaringType);
            res += '+';
          end;
          begin
            var name := t.Name;
            begin
              var ind := name.IndexOf('`');
              if ind<>-1 then name := name.Remove(ind);
            end;
            var anon_name := '$delegate';
            if name.StartsWith(anon_name) and name.Substring(anon_name.Length).All(char.IsDigit) then
              name := anon_name+'?';
            res += name;
          end;
          if t.IsGenericType then
          begin
            res += '<';
            res += t.GetGenericArguments.Select(TypeToTypeName).JoinToString(', ');
            res += '>';
          end;
          var mi := t.GetMethod('Invoke');
          res += ' = ';
          var is_func := mi.ReturnType<>typeof(System.Void);
          res += if is_func then 'function' else 'procedure';
          var pars := mi.GetParameters;
          if pars.Length<>0 then
          begin
            res += '(';
            foreach var par in pars index i do
            begin
              if i<>0 then res += '; ';
              var par_t := par.ParameterType;
              if par_t.IsByRef then
              begin
                res += 'var ';
                par_t := par_t.GetElementType;
              end;
              res += par.Name;
              res += ': ';
              res += TypeToTypeName(par_t);
            end;
            res += ')';
          end;
          if is_func then
          begin
            res += ': ';
            res += TypeToTypeName(mi.ReturnType);
          end;
          all_delegates += res.ToString;
        end;
        
        dom.SetData('delegates', all_delegates.Order.JoinToString(#10));
      except
        on e: System.Reflection.ReflectionTypeLoadException do
          dom.SetData('err', e.LoaderExceptions.Select(e->#10+e.ToString).JoinToString(''));
      end;
      
    except
      on e: Exception do System.AppDomain.CurrentDomain.SetData('err', e.ToString);
    end;
    
  end;
  
  {$endregion DelegateCounter}
  
  {$region Timers}
  
  TestingItemTimer = sealed class(Timer)
    comp := default(SimpleTimer);
    exec := new List<SimpleTimer>;
    
    public procedure AddComp(t: SimpleTimer);
    begin
      if comp<>nil then raise new System.InvalidOperationException;
      self.comp := t;
    end;
    public procedure AddExec(t: SimpleTimer) :=
      self.exec += t;
    
    protected function OuterTime: TimeSpan; override;
    begin
      Result := TimeSpan.Zero;
      if comp<>nil then
        Result := Result + comp.OuterTime;
      foreach var t in exec do
        Result := Result + t.OuterTime;
    end;
    
    //TODO #2197
    private static function TimeToText(t: TimeSpan) := inherited TimeToText(t);
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override;
    begin
      
      case Ord(comp<>nil)+exec.Count of
        0: exit;
        1:
        begin
          var t := (comp+exec.AsEnumerable).Single(t->t<>nil);
          var name := if t=comp then 'Comp' else 'Exec';
          yield (lvl, $'{header} ({name})', TimeToText(self.OuterTime));
        end;
        else
        begin
          
          yield (lvl, header, TimeToText(self.OuterTime));
          
          if comp<>nil then
            yield comp.MakeLogLines(lvl+1, 'Comp').Single;
          
          if exec.Count=1 then
            yield exec.Single.MakeLogLines(lvl+1, 'Exec').Single else
          foreach var t in exec index exec_i do
            yield t.MakeLogLines(lvl+1, $'Exec[{exec_i+1}]').Single;
          
        end;
      end;
      
    end;
    
  end;
  
  TestingFolderTimer = sealed class(Timer)
    private sub_dirs := new List<(string,TestingFolderTimer)>;
    private files := new List<(string,TestingItemTimer)>;
    
    public constructor := exit;
    public constructor(name: string; parent: TestingFolderTimer) :=
      parent.sub_dirs += (name, self);
    
    public function TotalCompExecTime: ValueTuple<TimeSpan,TimeSpan>;
    begin
      var total_comp_time := TimeSpan.Zero;
      var total_exec_time := TimeSpan.Zero;
      foreach var (name,t) in sub_dirs do
      begin
        var (dir_comp_time, dir_exec_time) := t.TotalCompExecTime;
        total_comp_time := total_comp_time + dir_comp_time;
        total_exec_time := total_exec_time + dir_exec_time;
      end;
      foreach var (name,t) in files do
      begin
        if t.comp<>nil then
          total_comp_time := total_comp_time + t.comp.OuterTime;
        foreach var exec_t in t.exec do
          total_exec_time := total_exec_time + exec_t.OuterTime;
      end;
      Result := ValueTuple.Create(total_comp_time, total_exec_time);
    end;
    
    private outer_time_cache := default(TimeSpan?);
    protected function OuterTime: TimeSpan; override;
    begin
      if outer_time_cache<>nil then
      begin
        Result := outer_time_cache.Value;
        exit;
      end;
      Result := TimeSpan.Zero;
      foreach var (name,t) in sub_dirs do
        Result := Result + t.OuterTime;
      foreach var (name,t) in files do
        Result := Result + t.OuterTime;
      outer_time_cache := Result;
    end;
    
    //TODO #2197
    private static function TimeToText(t: TimeSpan) := inherited TimeToText(t);
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override;
    begin
      yield (lvl, header, TimeToText(self.OuterTime));
      foreach var (name,t) in sub_dirs do
        yield sequence t.MakeLogLines(lvl+1, name);
      foreach var (name,t) in files do
        yield sequence t.MakeLogLines(lvl+1, name);
    end;
    
  end;
  
  TestingCoreTimer = sealed class(Timer)
    
    private total_debug_pcu_time: TimeSpan;
    private debug_pcu := new List<(string, SimpleTimer)>;
    
    private cl_context_gen_time: TimeSpan;
    private cl_context_gen_comp: SimpleTimer;
    private cl_context_gen_exec: SimpleTimer;
    private function get_cl_context_gen_time_sum := cl_context_gen_comp.OuterTime+cl_context_gen_exec.OuterTime;
    
    private actual_comp_time: TimeSpan;
    private body := new TestingFolderTimer;
    
    public constructor;
    begin
      if not(Timer.main is ExeTimer) then
        raise new InvalidOperationException(TypeName(Timer.main));
      Timer.main := self;
    end;
    
    protected function OuterTime: TimeSpan; override;
    begin
      raise new InvalidOperationException;
    end;
    
    //TODO #2197
    private static function TimeToText(t: TimeSpan) := inherited TimeToText(t);
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override;
    begin
      yield (lvl, header, TimeToText(OtpLine.TotalTime));
      
      yield (lvl+1, 'Debug PCU', TimeToText(total_debug_pcu_time));
      foreach var (name,t) in debug_pcu do
        yield t.MakeLogLines(lvl+2, name).Single;
      
      if 'OpenCLABC' in allowed_modules then
      begin
        yield (lvl+1, 'CLContext', $'{cl_context_gen_time} ({TimeToText(get_cl_context_gen_time_sum)})');
        yield cl_context_gen_comp.MakeLogLines(lvl+2, 'Comp').Single;
        yield cl_context_gen_exec.MakeLogLines(lvl+2, 'Exec').Single;
      end;
      
      var (total_comp_time, total_exec_time) := body.TotalCompExecTime;
      yield (lvl+1, 'All comp', $'{TimeToText(total_comp_time)} ({actual_comp_time.TotalSeconds:N4})');
      yield (lvl+1, 'All exec', TimeToText(total_exec_time));
      
      yield sequence body.MakeLogLines(lvl+1, 'All tests');
      
    end;
    
  end;
  
  {$endregion Timers}
  
  TestInfo = sealed class
    
    {$region global testing info}
    
    static lk_console_only := new OtpKind('console only');
    static lk_pack_stage_unspecific := new OtpKind('pack stage unspecific');
    
    static cl_contexts: array of string := nil;
    
    static all_loaded := new List<TestInfo>;
    static unused_test_files := new HashSet<string>;
    
    static core_timer := new TestingCoreTimer;
    
    {$endregion global testing info}
    
    {$region core test info}
    
    own_timer: TestingItemTimer;
    pas_fname, test_dir, td_fname: string;
    stop_test := false;
    loaded_tests: array of ExecutingTest := nil;
    first_test_exec := true;
    
    multitest_prop_ids := new List<object>;
    multitest_prop_sizes := new Dictionary<object, integer>;
    multitest_prop_values := new Dictionary<object, integer>;
    
    {$endregion core test info}
    
    {$region raw settings}
    
    all_settings := new Dictionary<string, string>;
    used_settings := new List<string>;
    resave_settings := false;
    
    {$endregion raw settings}
    
    {$region typed settings}
    
    test_comp: boolean;
    
    static exec_multitest_id := new object;
    test_exec: integer;
    
    req_modules: IList<string>;
    comp_expected: ExpectedText;
    exec_expected: array of record
      otp: ExpectedText;
      err: ExpectedText;
    end;
    delete_before_exec: array of string;
    
    {$endregion typed settings}
    
    {$region Multitest}
    
    procedure DefineMultitestProp(id: object; size: integer);
    begin
      if loaded_tests<>nil then raise new InvalidOperationException;
      if multitest_prop_values.Any then raise new InvalidOperationException;
      
      multitest_prop_ids += id;
      multitest_prop_sizes.Add(id, size);
      
    end;
    
    procedure RunWithMultitestValue(id: object; v: integer; act: Action);
    begin
      if id not in multitest_prop_sizes then raise new InvalidOperationException;
      multitest_prop_values.Add(id, v);
      
      act();
      
      if not multitest_prop_values.Remove(id) then
        raise new InvalidOperationException;
    end;
    
    function TakeOutMultitestExecution: ExecutingTest;
    begin
      if multitest_prop_values.Count <> multitest_prop_ids.Count then raise new InvalidOperationException;
      
      var i := 0;
      foreach var id in multitest_prop_ids do
      begin
        i *= multitest_prop_sizes[id];
        i += multitest_prop_values[id];
      end;
      
      Result := loaded_tests[i];
      if Result=nil then raise new InvalidOperationException;
      loaded_tests[i] := nil;
    end;
    
    {$endregion Multitest}
    
    {$region Load}
    
    static procedure LoadCLA;
    const modules_def = 'Modules';
    const auto_update_def = 'AutoUpdate';
    begin
      
      foreach var w in CLArgs.GetArgs(modules_def).SelectMany(val->val.ToWords('+').Select(w->w.Trim)) do
        if w in valid_modules then
          allowed_modules += w else
          Otp($'WARNING: Invalid module [{w}]');
      if allowed_modules.Count=0 then
      begin
        allowed_modules := valid_modules;
        Otp($'Testing all modules:');
      end else
        Otp($'Testing selected modules:');
      Otp(allowed_modules.JoinToString(' + '));
      
      foreach var val in CLArgs.GetArgs(auto_update_def) do
        auto_update := boolean.Parse(val);
      
    end;
    static procedure MakeDebugPCU;
    begin
      var sw := Stopwatch.StartNew;
      
      System.IO.Directory.CreateDirectory('Tests/DebugPCU');
      var used_units := allowed_modules.ToHashSet;
      used_units += valid_modules.Where(u->u+'ABC' in allowed_modules);
      
      foreach var mn in used_units do
        System.IO.File.Copy($'Modules.Packed/{mn}.pas', $'Tests/DebugPCU/{mn}.pas', true);
      used_units
        .Where(mn->mn+'ABC' not in used_units)
        .TaskForEach(mn->
          CompilePasFile($'Tests/DebugPCU/{mn}.pas',
            new_timer->(core_timer.debug_pcu += (mn, new_timer)),
            nil, nil, OtpKind.Empty,
            '/Debug:1 /Define:ForceMaxDebug'
          )
        )
      .SyncExec;
      foreach var mn in used_units do
        System.IO.File.Delete($'Tests/DebugPCU/{mn}.pas');
      
      core_timer.total_debug_pcu_time := sw.Elapsed;
    end;
    static procedure GenCLContext;
    begin
      if 'OpenCLABC' not in allowed_modules then exit;
      
      var sw := Stopwatch.StartNew;
      CompilePasFile('Tests/CLContextGen.pas',
        new_timer->(core_timer.cl_context_gen_comp := new_timer),
        nil, nil,
        OtpKind.Empty, '/Debug:1', GetFullPath('Tests/DebugPCU')
      );
      Otp($'Running Tests/CLContextGen.exe');
      RunFile('Tests/CLContextGen.exe', nil,
        new_timer->(core_timer.cl_context_gen_exec := SimpleTimer(new_timer)),
        l->Otp($'CLContextGen: {l}', lk_console_only), nil
      );
      Otp($'Finished running Tests/CLContextGen.exe');
      
      cl_contexts := EnumerateFiles('Tests/CLContext').ToArray;
      if cl_contexts.Count=0 then
        Otp($'WARNING: Valid OpenCLABC context was not found in system', lk_console_only);
      
      core_timer.cl_context_gen_time := sw.Elapsed;
    end;
    
    procedure LoadSettingsDict;
    begin
      all_settings := new Dictionary<string, string>;
      
      var lns := ReadAllLines(td_fname, enc);
      
      var i := -1;
      while true do
      begin
        i += 1;
        if i >= lns.Length then break;
        var s := lns[i];
        if not s.StartsWith('#') then continue;
        
        var sb := new StringBuilder;
        var key := s;
        while true do
        begin
          i += 1;
          if i = lns.Length then break;
          s := lns[i];
          
          if s.StartsWith('#') then
          begin
            i -= 1;
            break;
          end;
          
          sb += s;
          sb += #10;
          
        end;
        
        all_settings.Add(key, sb.ToString.TrimEnd(#10).Replace('\#','#'));
      end;
      
    end;
    procedure FindReqModules;
    begin
      req_modules := new List<string>;
      foreach var l in ReadLines(pas_fname).Select(l->l.TrimStart('#').TrimStart) do
        if l.StartsWith('uses') then
          foreach var m in l.Substring('uses'.Length).ToWords(',',' ',';') do
            if m in valid_modules then
              req_modules.Add(m);
      all_settings['#ReqModules'] := req_modules.JoinToString('+');
      used_settings += '#ReqModules';
      resave_settings := true;
    end;
    
    function ExtractSettingStr(name: string; def: string := nil): string;
    begin
      if all_settings.TryGetValue(name, Result) then
        used_settings += name else
        Result := def;
    end;
    
    static procedure LoadAll(dir_path: string; params test_modes: array of string) :=
      LoadAll(GetFullPath(dir_path), core_timer.body, test_modes);
    static procedure LoadAll(dir_path: string; dir_timer: TestingFolderTimer; test_modes: array of string);
    begin
      if not System.IO.Directory.Exists(dir_path) then
      begin
        Otp($'WARNING: Dir [{GetRelativePathRTA(dir_path)}] does not exist', lk_pack_stage_unspecific);
        exit;
      end;
      
      unused_test_files += EnumerateAllFiles(dir_path, '*.td').Select(td_fname->td_fname.Replace('\','/'));
      
      foreach var pas_fname in EnumerateFiles(dir_path, '*.pas').Select(pas_fname->pas_fname.Replace('\','/')) do
      try
        var t := new TestInfo;
        t.pas_fname := pas_fname;
        t.test_dir := dir_path;
        t.td_fname := System.IO.Path.ChangeExtension(pas_fname, '.td');
        if unused_test_files.Remove(t.td_fname) then
          t.LoadSettingsDict else
        begin
          var mark_skip := procedure->
          begin
            WriteAllText(t.td_fname, #10#10#10'#SkipTest'#10#10#10, enc);
            raise new TestCanceledException;
          end;
          
          if ReadAllText(t.pas_fname, enc).Contains('unit') then
            mark_skip();
          
          case auto_update ? DialogResult.No : MessageBox.Show($'File {GetRelativePath(t.td_fname)} not found'+#10'Mark .pas file as test-ignored?', 'New .pas file', MessageBoxButtons.YesNoCancel, MessageBoxIcon.Exclamation, MessageBoxDefaultButton.Button2) of
            
            DialogResult.Yes: mark_skip();
            
            DialogResult.No: t.resave_settings := true;
            
            DialogResult.Cancel: Halt(-1);
            
          end;
          
        end;
        
        {$region Settings}
        
        if t.all_settings.ContainsKey('#SkipTest') then continue;
        
        t.req_modules := t.ExtractSettingStr('#ReqModules', nil)?.ToWords('+');
        if (t.req_modules=nil) or t.req_modules.Any(mn->mn not in valid_modules) then t.FindReqModules;
        if not t.req_modules.All(m->m in allowed_modules) then continue;
        
        all_loaded += t;
        begin
          var t_timer := new TestingItemTimer;
          dir_timer.files += (System.IO.Path.GetFileNameWithoutExtension(pas_fname).Replace('error','errоr'), t_timer);
          t.own_timer := t_timer;
        end;
        
        foreach var tm in t.ExtractSettingStr('#TestMode', nil)?.ToWords('+') ?? test_modes index i do
          case tm of
            
            'Comp':
            begin
              if i<>0 then raise new System.InvalidOperationException;
              t.test_comp := true;
            end;
            
            'Exec': t.test_exec += 1;
            
            else raise new System.InvalidOperationException(tm);
          end;
        
        if t.test_comp then
        begin
          
          t.comp_expected := new ExpectedText( t.ExtractSettingStr('#ExpErr') );
          
        end;
        
        if t.test_exec<>0 then
        begin
          SetLength(t.exec_expected, t.test_exec);
          
          for var i := 0 to t.test_exec-1 do
          begin
            var sn := '';
            if t.test_exec<>1 then sn += i;
            t.exec_expected[i].otp := new ExpectedText( t.ExtractSettingStr('#ExpExecOtp'+sn) );
            t.exec_expected[i].err := new ExpectedText( t.ExtractSettingStr('#ExpExecErr'+sn) );
          end;
          
          t.delete_before_exec := t.ExtractSettingStr('#DeleteBeforeExec', '').ToWords(#10).ConvertAll(fname->GetFullPath(fname, t.test_dir));
          t.DefineMultitestProp(exec_multitest_id, t.test_exec);
        end;
        
        if cl_contexts<>nil then
          t.DefineMultitestProp(cl_contexts, cl_contexts.Count);
        
        {$endregion Settings}
        
      except
        on TestCanceledException do ;
      end;
      
      foreach var sub_dir_path in EnumerateDirectories(dir_path) do
        LoadAll(sub_dir_path, new TestingFolderTimer('/'+System.IO.Path.GetFileName(sub_dir_path), dir_timer), test_modes);
      
    end;
    
    {$endregion Load}
    
    {$region Comp}
    
    static procedure CompAll;
    begin
      var sw := Stopwatch.StartNew;
      
      all_loaded.Where(t->t.test_comp)
      .TaskForEach(t->
      try
        var fwoe := GetRelativePath(
          System.IO.Path.ChangeExtension(t.pas_fname, nil).Replace('error','errоr').Replace('\','/')
        );
        
        var comp_err: string := nil;
        CompilePasFile(t.pas_fname,
          t.own_timer.AddComp,
          l->Otp(l.ConvStr(s->s.Replace('error','errоr'))),
          err->(comp_err := err),
          OtpKind.Empty, '/Debug:1', GetFullPath('Tests/DebugPCU')
        );
        
        if comp_err<>nil then
        begin
          
          if t.comp_expected.parts=nil then
            case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe":{#10*2}{comp_err}{#10*2}Add this to expected errors?', 'Unexpected error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings['#ExpErr'] := comp_err;
                t.used_settings += '#ExpErr';
                t.resave_settings := true;
                Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end else
            
          if not t.comp_expected.Matches(comp_err) then
            case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.comp_expected}{#10*2}Current error:{#10*2}{comp_err}{#10*2}Replace expected error?', 'Wrong error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings['#ExpErr'] := comp_err;
                t.used_settings += '#ExpErr';
                t.resave_settings := true;
                Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end;
          
          t.stop_test := true;
        end else
        begin
          
          if t.comp_expected.parts<>nil then
            case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.comp_expected}{#10*2}Remove error from expected?', 'Missing error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                if not t.all_settings.Remove('#ExpErr') then raise new System.InvalidOperationException;
                t.resave_settings := true;
                Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end;
          
          begin
            
            var dom := System.AppDomain.CreateDomain($'Getting delegate count of {fwoe}');
            dom.SetData('fname', System.IO.Path.ChangeExtension(t.pas_fname, '.exe'));
            dom.DoCallBack(DelegateCounter.FindDelegatesInBin);
            if dom.GetData('err') is string(var e) then
              raise new Exception(e);
            var delegates := string( dom.GetData('delegates') );
            System.AppDomain.Unload(dom);
            
            var settings_key := '#Delegates';
            if delegates='' then
            begin
              
              if t.all_settings.ContainsKey(settings_key) then
              begin
                t.all_settings.Remove(settings_key);
                t.resave_settings := true;
              end;
              
            end else
            begin
              
              if t.all_settings.Get(settings_key) <> delegates then
              begin
                t.all_settings[settings_key] := delegates;
                t.resave_settings := true;
              end;
              
              t.used_settings += settings_key;
            end;
            
          end;
          
        end;
        
      except
        on TestCanceledException do ;
      end)
      .SyncExec;
      
      core_timer.actual_comp_time := sw.Elapsed;
    end;
    
    {$endregion Comp}
    
    {$region Exec}
    
    procedure RaiseWaitNotFound(wait_test, file_type: string) :=
    raise new MessageException($'ERROR: Wait {file_type} [{GetRelativePath(wait_test)}] of test [{GetRelativePath(self.td_fname)}] wasn''t found');
    
    internal static pocgl_base_dir := System.IO.Path.GetDirectoryName(GetCurrentDir);
    static function InsertAnyTextParts(text: string): string;
    begin
      var res := new StringBuilder;
      
      var anon_names := |
        '<>local_variables_class_', '<>lambda',
        'cl_command_queue[', 'cl_mem[', 'cl_kernel[',
        'CLPlatform[', 'CLDevice[', 'CLContext[', 'CLProgramCode[', 'NativeMemory:$', 'CLMemory[', 'CLMemorySubSegment[', 'CLValue<byte>[', 'CLArray<byte>[',
        ':строка ', ':line '
      |;
      var inds := new integer[anon_names.Length];
      var in_anon_name := false;
      foreach var ch in text do
      begin
        if in_anon_name then
        begin
          if (ch in '0'..'9') or (ch in 'A'..'F') then continue;
          in_anon_name := false;
          res += '*';
        end;
        
        for var i := 0 to inds.Length-1 do
        begin
          if anon_names[i][inds[i]] = ch then
          begin
            inds[i] += 1;
            if inds[i] = anon_names[i].Length then
            begin
              in_anon_name := true;
              inds.Fill(0);
              break;
            end;
          end else
            inds[i] := 0;
        end;
        
        res += ch;
      end;
      if in_anon_name then
        res += '*';
      
      Result := res.ToString.Replace(pocgl_base_dir, '*').Replace(pocgl_base_dir.ToLower, '*');
    end;
    
    procedure Execute :=
    try
      var fwoe := GetRelativePath(
        System.IO.Path.ChangeExtension(pas_fname, nil).Replace('error','errоr').Replace('\','/')
      );
      
      if stop_test then
      begin
        Otp($'WARNING: Test[{fwoe}] wasn''t executed because of prior errоrs or changes to .td');
        exit;
      end;
      
      var exec_lk := if first_test_exec then
        OtpKind.Empty else
        lk_pack_stage_unspecific;
      first_test_exec := false;
      
      foreach var fname in delete_before_exec do
        if FileExists(fname) then
          System.IO.File.Delete(fname) else
          Otp($'WARNING: [{GetRelativePath(fname)}] did not exist, but Test[{GetRelativePath(fwoe)}] asked to delete it', lk_console_only);
      
      for var test_i := 0 to self.test_exec-1 do
        self.RunWithMultitestValue(exec_multitest_id, test_i, ()->
        begin
          
          Otp($'Executing Test[{GetRelativePath(fwoe)}]', exec_lk);
          var res, err: string;
          own_timer.AddExec(new SimpleTimer(()->
          begin
            (res, err) := self.TakeOutMultitestExecution.FinishExecution;
          end));
          Otp($'Done executing', exec_lk);
          
          var sn := '';
          if self.test_exec<>1 then sn += test_i;
          
          if not string.IsNullOrWhiteSpace(err) then
          begin
            if exec_expected[test_i].err.parts=nil then
            begin
              case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe":{#10*2}{err}{#10*2}Add this to expected errors?', 'Unexpected exec error', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  all_settings['#ExpExecErr'+sn] := InsertAnyTextParts(err);
                  used_settings += '#ExpExecErr'+sn;
                  resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
              end;
              stop_test := true;
            end else
              
            if not exec_expected[test_i].err.Matches(err) then
            begin
              case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{exec_expected[test_i].err}{#10*2}Current error:{#10*2}{err}{#10*2}Replace expected error?', 'Wrong exec error', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  all_settings['#ExpExecErr'+sn] := InsertAnyTextParts(err);
                  used_settings += '#ExpExecErr'+sn;
                  resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
              end;
              stop_test := true;
            end;
            
            if exec_expected[test_i].otp.parts<>nil then
            begin
              if not all_settings.Remove('#ExpExecOtp'+sn) then raise new System.InvalidOperationException;
              resave_settings := true;
            end;
            
          end else
          begin
            
            if exec_expected[test_i].err.parts<>nil then
            begin
              case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{exec_expected[test_i].err}{#10*2}Remove error from expected?', 'Missing exec error', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  if not all_settings.Remove('#ExpExecErr'+sn) then raise new System.InvalidOperationException;
                  resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
              end;
              stop_test := true;
            end;
            
            if exec_expected[test_i].otp.parts=nil then
            begin
              all_settings['#ExpExecOtp'+sn] := InsertAnyTextParts(res);
              used_settings += '#ExpExecOtp'+sn;
              resave_settings := true;
              Otp($'WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
              stop_test := true;
            end else
            if not exec_expected[test_i].otp.Matches(res) then
            begin
              case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{exec_expected[test_i].otp}{#10*2}Current output:{#10*2}{res}{#10*2}Replace expected output?', 'Wrong output', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  all_settings['#ExpExecOtp'+sn] := InsertAnyTextParts(res);
                  used_settings += '#ExpExecOtp'+sn;
                  resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
                
              end;
              stop_test := true;
            end;
            
          end;
          
        end);
      
    except
      on e: FatalTestingException do
        Otp(e.ToString);
    end;
    
    static procedure ExecAll;
    begin
      var to_exec := all_loaded.ToList;
      to_exec.RemoveAll(t->t.test_exec=0);
      
      foreach var t in to_exec do
      begin
        var exe_fname := System.IO.Path.ChangeExtension(t.pas_fname, '.exe');
        t.loaded_tests := ArrGen(t.multitest_prop_sizes.Values.Product, i->
          new ExecutingTest(exe_fname, MaxExecTime, true)
        );
      end;
      
      if cl_contexts=nil then
      begin
        foreach var t in to_exec do
          t.Execute;
      end else
      foreach var c_fname in cl_contexts index cl_context_i do
      begin
        var test_context_fname := 'TestContext.dat';
        System.IO.File.Copy(c_fname, test_context_fname, true);
        
        var br := new System.IO.BinaryReader(System.IO.File.OpenRead(test_context_fname));
        try
          var pl_name := br.ReadString.Trim;
          var dvc_count := br.ReadInt32;
          Otp($'Switched to platform "{pl_name}" and using {dvc_count} devices', lk_pack_stage_unspecific);
          loop dvc_count do
          begin
            var dvc_name := br.ReadString.Trim;
            Otp($'Device "{dvc_name}"', lk_console_only);
          end;
        finally
          br.Close;
        end;
        
        foreach var t in to_exec do
          t.RunWithMultitestValue(cl_contexts, cl_context_i, t.Execute);
        
        System.IO.File.Delete(test_context_fname);
      end;
      
    end;
    
    {$endregion Exec}
    
    {$region Cleanup}
    
    static procedure Cleanup;
    begin
      Otp('Cleanup');
      if System.IO.Directory.Exists('Tests/DebugPCU') then
        System.IO.Directory.Delete('Tests/DebugPCU', true);
      
      if all_loaded.Any(t->(t.loaded_tests<>nil) and t.loaded_tests.Any(t->t<>nil)) then
        Otp($'WARNING: Not all loaded tests were executed');
      
      foreach var t in all_loaded do
        if t.resave_settings then
        begin
          var sw := new System.IO.StreamWriter(System.IO.File.Create(t.td_fname), enc);
          sw.WriteLine;
          sw.WriteLine;
          
          var used_settings := t.used_settings.ToHashSet;
          foreach var key in t.all_settings.Keys.Order do
            if key not in used_settings then
              Otp($'WARNING: Setting {key} was deleted from "{t.td_fname}"', lk_pack_stage_unspecific) else
            begin
              var val := t.all_settings[key];
              sw.WriteLine;
              sw.WriteLine(key);
              if not string.IsNullOrWhiteSpace(val) then
                sw.WriteLine(val);
            end;
          
          sw.WriteLine;
          sw.WriteLine;
          sw.Close;
          Otp($'WARNING: File "{GetRelativePath(t.td_fname)}" updated', lk_pack_stage_unspecific);
        end;
      
      foreach var td_fname in unused_test_files do
        case MessageBox.Show($'File "{GetRelativePath(td_fname)}" wasn''t used in any test{#10}Delete it?', 'Unused TestData file', MessageBoxButtons.YesNo) of
          
          DialogResult.Yes: System.IO.File.Delete(td_fname);
          
          DialogResult.No: ;
          
        end;
      
    end;
    
    {$endregion Cleanup}
    
  end;
  
begin
  try
//    TestInfo.auto_update := true;
    
    (**)
    TestInfo.LoadCLA;
    TestInfo.MakeDebugPCU;
    TestInfo.GenCLContext;
    
//    TestInfo.LoadAll('Tests/Comp',  'Comp');
    TestInfo.LoadAll('Tests/Exec',  'Comp','Exec');
    TestInfo.LoadAll('Samples',     'Comp');
    (*)
    TestInfo.allowed_modules += 'OpenCLABC';
    TestInfo.MakeDebugPCU;
    TestInfo.LoadAll('Samples', 'Comp');
    (**)
    
    try
      TestInfo.CompAll;
      TestInfo.ExecAll;
    finally
      TestInfo.Cleanup;
    end;
    
    Otp('Done testing');
  except
    on e: Exception do ErrOtp(e);
  end;
end.