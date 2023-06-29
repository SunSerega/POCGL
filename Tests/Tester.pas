﻿uses '../POCGL_Utils';

uses '../Utils/AOtp';
uses '../Utils/ATask';
uses '../Utils/CLArgs';
uses '../Utils/SubExecuters';
uses '../Utils/Testing/Testing';

{$string_nullbased+}

{$reference System.Windows.Forms.dll}
type MessageBox               = System.Windows.Forms.MessageBox;
type MessageBoxButtons        = System.Windows.Forms.MessageBoxButtons;
type MessageBoxIcon           = System.Windows.Forms.MessageBoxIcon;
type MessageBoxDefaultButton  = System.Windows.Forms.MessageBoxDefaultButton;
type DialogResult             = System.Windows.Forms.DialogResult;

const MaxExecTime = 15000;

type
  {$region Helper types}
  
  TestCanceledException = sealed class(Exception) end;
  
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
  
  {$endregion Helper types}
  
  TestInfo = sealed class
    
    {$region global testing info}
    
    static lk_pack_stage_unspecific := new OtpKind('pack stage unspecific');
    
    static valid_modules := HSet('Dummy', 'OpenCL','OpenCLABC', 'OpenGL','OpenGLABC');
    static allowed_modules := new HashSet<string>(valid_modules.Count);
    
    static auto_update := false;
    
    static all_loaded := new List<TestInfo>;
    static unused_test_files := new HashSet<string>;
    
    {$endregion global testing info}
    
    {$region core test info}
    
    pas_fname, test_dir, td_fname: string;
    stop_test := false;
    loaded_test: ExecutingTest;
    
    {$endregion core test info}
    
    {$region raw settings}
    
    all_settings := new Dictionary<string, string>;
    used_settings := new List<string>;
    resave_settings := false;
    
    {$endregion raw settings}
    
    {$region typed settings}
    
    test_comp: boolean;
    test_exec: integer;
    
    req_modules: IList<string>;
    comp_expected: ExpectedText;
    exec_expected: array of record
      otp: ExpectedText;
      err: ExpectedText;
    end;
    delete_before_exec: array of string;
    
    {$endregion typed settings}
    
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
      
      System.IO.Directory.CreateDirectory('Tests/DebugPCU');
      var used_units := allowed_modules.ToHashSet;
      used_units.UnionWith(valid_modules.Where(u->u+'ABC' in allowed_modules));
      
      foreach var mn in used_units do
        System.IO.File.Copy($'Modules.Packed/{mn}.pas', $'Tests/DebugPCU/{mn}.pas', true);
      used_units
        .Where(mn->mn+'ABC' not in used_units)
        .Select(mn->CompTask($'Tests/DebugPCU/{mn}.pas', nil, '/Debug:1 /Define:ForceMaxDebug'))
        .CombineAsyncTask
      .SyncExec;
      foreach var mn in used_units do
        System.IO.File.Delete($'Tests/DebugPCU/{mn}.pas');
      
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
    
    static procedure LoadAll(path: string; params exp_mode: array of string);
    begin
      if not System.IO.Directory.Exists(path) then exit;
      path := GetFullPath(path);
      
      foreach var td_fname in System.IO.Directory.EnumerateFiles(path, '*.td', System.IO.SearchOption.AllDirectories) do
        unused_test_files.Add(td_fname);
      
      foreach var pas_fname in System.IO.Directory.EnumerateFiles(path, '*.pas', System.IO.SearchOption.AllDirectories) do
      try
        var t := new TestInfo;
        t.pas_fname := pas_fname;
        t.test_dir := System.IO.Path.GetDirectoryName(t.pas_fname);
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
        
        foreach var tm in t.ExtractSettingStr('#TestMode', nil)?.ToWords('+') ?? exp_mode index i do
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
        end;
        
        {$endregion Settings}
        
      except
        on TestCanceledException do ;
      end;
      
    end;
    
    {$endregion Load}
    
    {$region Comp}
    
    static procedure CompAll;
    begin
      
      // req_modules становится nil если не подошло
      all_loaded.Where(t->(t.req_modules<>nil) and t.test_comp)
      .Select(t->ProcTask(()->
      try
        var fwoe := GetRelativePath(
          System.IO.Path.ChangeExtension(t.pas_fname, nil).Replace('error','errоr').Replace('\','/')
        );
        
        var comp_err: string := nil;
        CompilePasFile(t.pas_fname,
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
            dom.DoCallBack(FindDelegatesInBin);
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
          
          if t.test_exec<>0 then
            t.loaded_test := new ExecutingTest(System.IO.Path.ChangeExtension(t.pas_fname, '.exe'), MaxExecTime, true);
        end;
        
      except
        on TestCanceledException do ;
      end))
      .CombineAsyncTask
      .SyncExec;
      
    end;
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
        Otp($'WARNING: Test[{fwoe}] wasn''t executed because of prior errоrs');
        exit;
      end;
      
      foreach var fname in delete_before_exec do
        if FileExists(fname) then
          System.IO.File.Delete(fname) else
          Otp($'WARNING: [{GetRelativePath(fname)}] did not exist, but Test[{GetRelativePath(fwoe)}] asked to delete it', |'console only'|);
      
      for var test_i := 0 to self.test_exec-1 do
      begin
        
        Otp($'Executing Test[{GetRelativePath(fwoe)}]');
        var (res, err) := loaded_test.FinishExecution;
        if test_i<>self.test_exec-1 then loaded_test := new ExecutingTest(loaded_test);
        Otp($'Done executing');
        
        var sn := '';
        if self.test_exec<>1 then sn += test_i;
        
        if not string.IsNullOrWhiteSpace(err) then
        begin
          
          if exec_expected[test_i].err.parts=nil then
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
            end else
            
          if not exec_expected[test_i].err.Matches(err) then
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
          
          if exec_expected[test_i].otp.parts<>nil then
          begin
            if not all_settings.Remove('#ExpExecOtp'+sn) then raise new System.InvalidOperationException;
            resave_settings := true;
          end;
          
        end else
        begin
          
          if exec_expected[test_i].err.parts<>nil then
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
          
          if exec_expected[test_i].otp.parts=nil then
          begin
            all_settings['#ExpExecOtp'+sn] := InsertAnyTextParts(res);
            used_settings += '#ExpExecOtp'+sn;
            resave_settings := true;
            Otp($'WARNING: Settings updated for "{fwoe}.td"', lk_pack_stage_unspecific);
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
          end;
          
        end;
        
      end;
      
    except
      on e: FatalTestingException do
        Otp(e.ToString);
    end;
    
    static procedure ExecAll :=
    foreach var t in all_loaded do
      if (t.req_modules<>nil) and (t.test_exec<>0) then
        t.Execute;
    
    {$endregion Exec}
    
    {$region Cleanup}
    
    static procedure Cleanup;
    begin
      Otp('Cleanup');
      if System.IO.Directory.Exists('Tests/DebugPCU') then
        System.IO.Directory.Delete('Tests/DebugPCU', true);
      
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
    
    TestInfo.LoadAll('Tests/Comp',  'Comp');
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