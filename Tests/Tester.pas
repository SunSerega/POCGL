uses POCGL_Utils in '..\POCGL_Utils';

uses AOtp         in '..\Utils\AOtp';
uses ATask        in '..\Utils\ATask';
uses CLArgs       in '..\Utils\CLArgs';
uses SubExecuters in '..\Utils\SubExecuters';

{$string_nullbased+}

{$reference System.Windows.Forms.dll}
type MessageBox               = System.Windows.Forms.MessageBox;
type MessageBoxButtons        = System.Windows.Forms.MessageBoxButtons;
type MessageBoxIcon           = System.Windows.Forms.MessageBoxIcon;
type MessageBoxDefaultButton  = System.Windows.Forms.MessageBoxDefaultButton;
type DialogResult             = System.Windows.Forms.DialogResult;

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
    
    static valid_modules := HSet('OpenCL','OpenCLABC', 'OpenGL','OpenGLABC');
    static allowed_modules := new HashSet<string>(valid_modules.Count);
    
    static auto_update := false;
    
    static all_loaded := new List<TestInfo>;
    static unused_test_files := new HashSet<string>;
    
    {$endregion global testing info}
    
    {$region core test info}
    
    pas_fname, test_dir, td_fname: string;
    stop_test := false;
    
    {$endregion core test info}
    
    {$region raw settings}
    
    all_settings := new Dictionary<string, string>;
    used_settings := new List<string>;
    resave_settings := false;
    
    {$endregion raw settings}
    
    {$region typed settings}
    
    test_mode: HashSet<string>;
    req_modules: IList<string>;
    expected_comp_err: ExpectedText;
    expected_otp: ExpectedText;
    expected_exec_err: ExpectedText;
    wait_for_tests: array of string;
    
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
      
      System.IO.Directory.CreateDirectory('Tests\DebugPCU');
      var used_units := allowed_modules.ToHashSet;
      used_units.UnionWith(valid_modules.Where(u->u+'ABC' in allowed_modules));
      
      foreach var mn in used_units do
        System.IO.File.Copy($'Modules.Packed\{mn}.pas', $'Tests\DebugPCU\{mn}.pas', true);
      used_units
        .Where(mn->not used_units.Contains(mn+'ABC'))
        .Select(mn->CompTask($'Tests\DebugPCU\{mn}.pas', false, '/Debug:1 /Define:ForceMaxDebug'))
        .CombineAsyncTask
      .SyncExec;
      foreach var mn in used_units do
        System.IO.File.Delete($'Tests\DebugPCU\{mn}.pas');
      
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
    
    static procedure LoadAll(path: string; exp_mode: HashSet<string>);
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
          var mark_skip: Action0 := ()->
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
        if (t.req_modules=nil) or t.req_modules.Any(mn->not valid_modules.Contains(mn)) then t.FindReqModules;
        if not t.req_modules.All(m->allowed_modules.Contains(m)) then continue;
        
        all_loaded += t;
        
        t.test_mode := t.ExtractSettingStr('#TestMode', nil)?.ToWords('+').ToHashSet ?? exp_mode;
        
        if t.test_mode.Contains('Comp') then
        begin
          
          t.expected_comp_err := new ExpectedText( t.ExtractSettingStr('#ExpErr') );
          
        end;
        
        if t.test_mode.Contains('Exec') then
        begin
          
          t.expected_otp      := new ExpectedText( t.ExtractSettingStr('#ExpOtp') );
          t.expected_exec_err := new ExpectedText( t.ExtractSettingStr('#ExpExecErr') );
          t.wait_for_tests    := t.ExtractSettingStr('#WaitForTests')?.Split(#10).ConvertAll(fname->GetFullPath(fname, t.test_dir));
          
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
      all_loaded.Where(t->(t.req_modules<>nil) and t.test_mode.Contains('Comp'))
      .Select(t->ProcTask(()->
      try
        var fwoe := System.IO.Path.ChangeExtension(t.pas_fname, nil).Replace('error','errоr');
        
        var comp_err: string := nil;
        CompilePasFile(t.pas_fname,
          l->Otp(l.ConvStr(s->s.Replace('error','errоr'))),
          err->(comp_err := err),
          false, '/Debug:1', GetFullPath('Tests\DebugPCU')
        );
        
        if comp_err<>nil then
        begin
          
          if t.expected_comp_err.parts=nil then
            case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe":{#10*2}{comp_err}{#10*2}Add this to expected errors?', 'Unexpected error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings['#ExpErr'] := comp_err;
                t.used_settings += '#ExpErr';
                t.resave_settings := true;
                Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end else
            
          if not t.expected_comp_err.Matches(comp_err) then
            case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_comp_err}{#10*2}Current error:{#10*2}{comp_err}{#10*2}Replace expected error?', 'Wrong error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings['#ExpErr'] := comp_err;
                t.used_settings += '#ExpErr';
                t.resave_settings := true;
                Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end;
          
          t.stop_test := true;
        end else
        begin
          
          if t.expected_comp_err.parts<>nil then
            case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_comp_err}{#10*2}Remove error from expected?', 'Missing error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                if not t.all_settings.Remove('#ExpErr') then raise new System.InvalidOperationException;
                t.resave_settings := true;
                Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end;
          
        end;
        
      except
        on TestCanceledException do ;
      end))
      .CombineAsyncTask
      .SyncExec;
      
    end;
    
    {$endregion Comp}
    
    {$region Exec}
    
    ///Result = (res, err)
    static function ExecuteTestExe(fname, nick: string): (string, string);
    const MaxExecTime = 15000;
    begin
      nick := nick.Replace('error', 'errоr');
      var dom := System.AppDomain.CreateDomain('Domain of '+nick);
      dom.SetData('fname', fname);
      
      var otp_l: OtpLine := $'Executing {nick}';
      Otp(otp_l);
      
      dom.DoCallBack(()->
      try
        var dom := System.AppDomain.CurrentDomain;
        var fname := dom.GetData('fname') as string;
        
        var ep := System.Reflection.Assembly.LoadFile(fname).EntryPoint;
        if ep=nil then raise new System.EntryPointNotFoundException;
        
        var res := new System.IO.StringWriter;
        Console.SetOut(res);
        
        var prev_path := System.Environment.CurrentDirectory;
        var thr := new System.Threading.Thread(()->
        try
          var sw := System.Diagnostics.Stopwatch.StartNew;
          try
            try
              System.Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(fname);
              ep.Invoke(nil, new object[0]);
            finally
              System.Environment.CurrentDirectory := prev_path;
            end;
          except
            on e: Exception do dom.SetData('Err', e.InnerException.ToString);
          end;
          sw.Stop;
          dom.SetData('exec_time', sw.ElapsedTicks);
        except
          on e: Exception do dom.SetData('fatal_err', e.ToString);
        end);
        thr.Start;
        
        if not thr.Join(MaxExecTime) then
        begin
          thr.Abort;
          System.Environment.CurrentDirectory := prev_path;
          dom.SetData('exec_time', MaxExecTime*System.TimeSpan.TicksPerMillisecond);
          dom.SetData('fatal_err', $'ERROR: Execution took too long for "{GetFullPathRTA(fname)}"');
        end else
          dom.SetData('Result', res.ToString);
        
      except
        on e: Exception do System.AppDomain.CurrentDomain.SetData('fatal_err', e.ToString);
      end);
      
      if dom.GetData('fatal_err') is string(var fatal_err) then
        raise new Exception(fatal_err);
      
      otp_l.s := $'Done executing';
      otp_l.t += int64(dom.GetData('exec_time'));
      Otp(otp_l);
      
      Result := (
        dom.GetData('Result') as string,
        dom.GetData('Err') as string
      );
      try
        Sleep(50); //TODO Конечно костыль - но надо запускать отдельный .exe, а не домен, иначе не исправить
        System.AppDomain.Unload(dom);
      except
        on e: System.CannotUnloadAppDomainException do
        begin
          Otp($'Error unloading domain of {nick}: {e}');
          Readln;
        end;
      end;
    end;
    
    static function TryExecWaitTest(td_fname: string; all_executed: HashSet<TestInfo>): boolean;
    begin
      var tests := all_loaded.ToList;
      tests.RemoveAll(t->t.td_fname<>td_fname);
      
      if tests.Count=0 then exit;
      if tests.Count<>1 then Otp($'WARNING: Multiple test with id [{GetRelativePath(td_fname)}]');
      
      foreach var t in tests do
        t.Execute(all_executed);
      
      Result := true;
    end;
    static function TryExecWaitExeFile(exe_fname: string): boolean;
    begin
      if not FileExists(exe_fname) then exit;
      
      RunFile(exe_fname, $'Test waited exe[{GetRelativePath(exe_fname)}]');
      
      Result := true;
    end;
    static function TryExecWaitPasFile(pas_fname: string): boolean;
    begin
      if not FileExists(pas_fname) then exit;
      
      CompilePasFile(pas_fname, false);
      
      Result := true;
    end;
    
    procedure RaiseWaitNotFound(wait_test, file_type: string) :=
    raise new MessageException($'ERROR: Wait {file_type} [{GetRelativePath(wait_test)}] of test [{GetRelativePath(self.td_fname)}] wasn''t found');
    
    internal static pocgl_base_dir := System.IO.Path.GetDirectoryName(GetCurrentDir);
    static function InsertAnyTextParts(text: string): string;
    begin
      var res := new StringBuilder;
      
      var anon_names := |
        '<>local_variables_class_', '<>lambda',
        'cl_command_queue[',
        'Platform[', 'Device[', 'Context[', 'MemorySegment[', 'MemorySubSegment[', 'ProgramCode[',
        ':строка ', ':line '
      |;
      var inds := new integer[anon_names.Length];
      var in_anon_name := false;
      foreach var ch in text do
      begin
        if in_anon_name then
        begin
          if ch.IsDigit then continue;
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
    
    procedure Execute(all_executed: HashSet<TestInfo>) :=
    try
      if not all_executed.Add(self) then exit;
      if wait_for_tests<>nil then
        foreach var wait_test in wait_for_tests do
          case System.IO.Path.GetExtension(wait_test) of
            
            '.td':  if not TryExecWaitTest(wait_test, all_executed) then  RaiseWaitNotFound(wait_test, 'test');
            '.exe': if not TryExecWaitExeFile(wait_test) then             RaiseWaitNotFound(wait_test, '.exe');
            '.pas': if not TryExecWaitPasFile(wait_test) then             RaiseWaitNotFound(wait_test, '.pas');
            
            '':
            if TryExecWaitTest    (wait_test+'.td', all_executed) then else
            if TryExecWaitExeFile (wait_test+'.exe') then else
            if TryExecWaitPasFile (wait_test+'.pas') then else
              RaiseWaitNotFound(wait_test, 'file');
            
            else raise new MessageException($'ERROR: Invalid wait test extension [{System.IO.Path.GetExtension(wait_test)}]');
          end;
      
      var fwoe := System.IO.Path.ChangeExtension(pas_fname, nil);
      
      if stop_test then
      begin
        Otp($'WARNING: Test[{fwoe}] wasn''t executed because of prior errоrs');
        exit;
      end;
      
      if not FileExists(fwoe+'.exe') then
      begin
        Otp($'ERROR: File {fwoe}.exe not found');
        exit;
      end;
      
      var (res, err) := ExecuteTestExe(GetFullPath(fwoe+'.exe'), $'Test[{GetRelativePath(fwoe)}]');
      res := res?.Remove(#13).Trim(#10);
      err := err?.Remove(#13).Trim(#10);
      
      fwoe := fwoe.Replace('error','errоr');
      if err<>nil then
      begin
        
        if expected_exec_err.parts=nil then
          case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe":{#10*2}{err}{#10*2}Add this to expected errors?', 'Unexpected exec error', MessageBoxButtons.YesNoCancel) of
            
            DialogResult.Yes:
            begin
              all_settings['#ExpExecErr'] := InsertAnyTextParts(err);
              used_settings += '#ExpExecErr';
              resave_settings := true;
              Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
            end;
            
            DialogResult.No: ;
            
            DialogResult.Cancel: Halt(-1);
          end else
          
        if not expected_exec_err.Matches(err) then
          case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{expected_exec_err}{#10*2}Current error:{#10*2}{err}{#10*2}Replace expected error?', 'Wrong exec error', MessageBoxButtons.YesNoCancel) of
            
            DialogResult.Yes:
            begin
              all_settings['#ExpExecErr'] := InsertAnyTextParts(err);
              used_settings += '#ExpExecErr';
              resave_settings := true;
              Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
            end;
            
            DialogResult.No: ;
            
            DialogResult.Cancel: Halt(-1);
          end;
        
        if expected_otp.parts<>nil then
        begin
          if not all_settings.Remove('#ExpOtp') then raise new System.InvalidOperationException;
          resave_settings := true;
        end;
        
      end else
      begin
        
        if expected_exec_err.parts<>nil then
          case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{expected_exec_err}{#10*2}Remove error from expected?', 'Missing exec error', MessageBoxButtons.YesNoCancel) of
            
            DialogResult.Yes:
            begin
              if not all_settings.Remove('#ExpExecErr') then raise new System.InvalidOperationException;
              resave_settings := true;
              Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
            end;
            
            DialogResult.No: ;
            
            DialogResult.Cancel: Halt(-1);
          end;
        
        if expected_otp.parts=nil then
        begin
          all_settings['#ExpOtp'] := InsertAnyTextParts(res);
          used_settings += '#ExpOtp';
          resave_settings := true;
          Otp(new OtpLine($'WARNING: Settings updated for "{fwoe}.td"', true));
        end else
        if not expected_otp.Matches(res) then
        begin
          
          case auto_update ? DialogResult.Yes : MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{expected_otp}{#10*2}Current output:{#10*2}{res}{#10*2}Replace expected output?', 'Wrong output', MessageBoxButtons.YesNoCancel) of
            
            DialogResult.Yes:
            begin
              all_settings['#ExpOtp'] := InsertAnyTextParts(res);
              used_settings += '#ExpOtp';
              resave_settings := true;
              Otp(new OtpLine($'%WARNING: Settings updated for "{fwoe}.td"', true));
            end;
            
            DialogResult.No: ;
            
            DialogResult.Cancel: Halt(-1);
            
          end;
        end;
        
      end;
      
    except
      on TestCanceledException do exit;
    end;
    
    static procedure ExecAll;
    begin
      var all_executed := new HashSet<TestInfo>(all_loaded.Count);
      
      foreach var t in all_loaded do
        if (t.req_modules<>nil) and t.test_mode.Contains('Exec') then
          t.Execute(all_executed);
      
    end;
    
    {$endregion Exec}
    
    {$region Cleanup}
    
    static procedure Cleanup;
    begin
      Otp('Cleanup');
      if System.IO.Directory.Exists('Tests\DebugPCU') then
        System.IO.Directory.Delete('Tests\DebugPCU', true);
      
      foreach var t in all_loaded do
        if t.resave_settings then
        begin
          var sw := new System.IO.StreamWriter(System.IO.File.Create(t.td_fname), enc);
          sw.WriteLine;
          sw.WriteLine;
          
          var used_settings := t.used_settings.ToHashSet;
          foreach var key in t.all_settings.Keys do
            if not used_settings.Contains(key) then
              Otp(new OtpLine($'WARNING: Setting {key} was deleted from "{t.td_fname}"', true)) else
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
          Otp(new OtpLine($'WARNING: File "{t.td_fname}" updated', true));
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
    (**)
    TestInfo.LoadCLA;
    TestInfo.MakeDebugPCU;
    
    TestInfo.LoadAll('Tests\Comp',  HSet('Comp'));
    TestInfo.LoadAll('Samples',     HSet('Comp'));
    TestInfo.LoadAll('Tests\Exec',  HSet('Comp','Exec'));
    (*)
//    TestInfo.auto_update := true;
    TestInfo.allowed_modules += 'OpenCLABC';
    TestInfo.MakeDebugPCU;
    TestInfo.LoadAll('C:\0Prog\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle',  HSet('Comp','Exec'));
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