uses MiscUtils in '..\Utils\MiscUtils.pas';

{$reference System.Windows.Forms.dll}
type MessageBox               = System.Windows.Forms.MessageBox;
type MessageBoxButtons        = System.Windows.Forms.MessageBoxButtons;
type MessageBoxIcon           = System.Windows.Forms.MessageBoxIcon;
type MessageBoxDefaultButton  = System.Windows.Forms.MessageBoxDefaultButton;
type DialogResult             = System.Windows.Forms.DialogResult;

const
  MaxExecTime = 5000;
  
var domain_unload_otps := new List<ThrProcOtp>;

///Result = (res, err)
function ExecuteTestExe(fname, nick: string): (string, string);
begin
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
    
    var thr := new System.Threading.Thread(()->
    try
      var sw := System.Diagnostics.Stopwatch.StartNew;
      try
        var prev_path := System.Environment.CurrentDirectory;
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
      dom.SetData('exec_time', MaxExecTime*System.TimeSpan.TicksPerMillisecond);
      dom.SetData('fatal_err', $'ERROR: Execution took too long for "{GetFullPathRTE(fname)}"');
    end else
      dom.SetData('Result', res.ToString);
    
  except
    on e: Exception do System.AppDomain.CurrentDomain.SetData('fatal_err', e.ToString);
  end);
  
  if dom.GetData('fatal_err') is string(var fatal_err) then
    raise new MessageException(fatal_err);
  
  otp_l.s := $'Done executing {nick}';
  otp_l.t += int64(dom.GetData('exec_time'));
  Otp(otp_l);
  
  Result := (
    dom.GetData('Result') as string,
    dom.GetData('Err') as string
  );
  StartBgThread(()->
  try
    var du_otp := new ThrProcOtp;
    lock domain_unload_otps do domain_unload_otps += du_otp;
    try
      System.AppDomain.Unload(dom);
    except
      on e: System.CannotUnloadAppDomainException do
        du_otp.Enq($'Error unloading domain of {nick}: {e}');
    end;
    du_otp.Finish;
  except
    on e: Exception do ErrOtp(e);
  end);
end;

type
  TestCanceledException = class(Exception) end;
  
  TestInfo = sealed class
    pas_fname, td_fname: string;
    stop_test := false;
    
    all_settings := new Dictionary<string, string>;
    used_settings := new List<string>;
    resave_settings := false;
    
    test_mode: HashSet<string>;
    req_modules: IList<string>;
    expected_comp_err: string;
    expected_otp: string;
    expected_exec_err: string;
    
    static valid_modules := HSet('OpenCL','OpenCLABC', 'OpenGL','OpenGLABC');
    static allowed_modules := new HashSet<string>(valid_modules.Count);
    
    static all_loaded := new List<TestInfo>;
    static test_folders := new List<string>;
    
    {$region Load}
    
    static procedure LoadCLA;
    const modules_def = 'Modules=';
    begin
      var arg := CommandLineArgs.FirstOrDefault(arg->arg.StartsWith(modules_def));
      if arg<>nil then
        foreach var w in arg.Remove(0,modules_def.Length).ToWords('+').Select(w->w.Trim) do
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
    end;
    
    procedure LoadSettingsDict;
    begin
      all_settings := new Dictionary<string, string>;
      
      if not System.IO.File.Exists(td_fname) then
      begin
        var mark_skip: Action0 := ()->
        begin
          WriteAllText(td_fname, #10#10#10'#SkipTest'#10#10#10, enc);
          raise new TestCanceledException;
        end;
        
        if ReadAllText(pas_fname, enc).Contains('unit') then
          mark_skip();
        
        case MessageBox.Show($'File {td_fname} not found'+#10'Mark .pas file as test-ignored?', 'New .pas file', MessageBoxButtons.YesNoCancel, MessageBoxIcon.Exclamation, MessageBoxDefaultButton.Button2) of
          
          DialogResult.Yes: mark_skip();
          
          DialogResult.No:
          begin
            resave_settings := true;
            exit;
          end;
          
          DialogResult.Cancel: Halt(-1);
          
        end;
        
      end;
      
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
      foreach var l in ReadLines(pas_fname) do
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
      
      foreach var pas_fname in System.IO.Directory.EnumerateFiles(path, '*.pas', System.IO.SearchOption.AllDirectories) do
      try
        var t := new TestInfo;
        t.pas_fname := pas_fname;
        t.td_fname := pas_fname.Remove(pas_fname.LastIndexOf('.'))+'.td';
        
        {$region Settings}
        t.LoadSettingsDict;
        
        if t.all_settings.ContainsKey('#SkipTest') then continue;
        
        t.req_modules := t.ExtractSettingStr('#ReqModules', nil)?.ToWords('+');
        if (t.req_modules=nil) or t.req_modules.Any(mn->not valid_modules.Contains(mn)) then t.FindReqModules;
        if not t.req_modules.All(m->allowed_modules.Contains(m)) then continue;
        
        all_loaded += t;
        
        t.test_mode := t.ExtractSettingStr('#TestMode', nil)?.ToWords('+').ToHashSet ?? exp_mode;
        
        if t.test_mode.Contains('Comp') then
        begin
          
          t.expected_comp_err := t.ExtractSettingStr('#ExpErr');
          
        end;
        
        if t.test_mode.Contains('Exec') then
        begin
          
          t.expected_otp      := t.ExtractSettingStr('#ExpOtp');
          t.expected_exec_err := t.ExtractSettingStr('#ExpExecErr');
          
        end;
        
        {$endregion Settings}
        
      except
        on TestCanceledException do ;
      end;
      
    end;
    
    {$endregion Load}
    
    static procedure CompAll;
    begin
      
      // req_modules становится nil если не подошло
      all_loaded.Where(t->(t.req_modules<>nil) and t.test_mode.Contains('Comp'))
      .Select(t->ProcTask(()->
      try
        var fwoe := t.pas_fname.Remove(t.pas_fname.LastIndexOf('.'));
        
        var comp_err: string := nil;
        CompilePasFile(t.pas_fname, Otp, err->begin comp_err := err end, GetFullPath('Modules.Packed'));
        
        if comp_err<>nil then
        begin
          Otp('Finished compiling: ERRОR');
          
          if t.expected_comp_err=nil then
            case MessageBox.Show($'In "{fwoe}.exe":{#10*2}{comp_err}{#10*2}Add this to expected errors?', 'Unexpected error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings['#ExpErr'] := comp_err;
                t.used_settings += '#ExpErr';
                t.resave_settings := true;
                Otp($'%WARNING: Settings updated for "{fwoe}.td"');
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end else
            
          if t.expected_comp_err<>comp_err then
            case MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_comp_err}{#10*2}Current error:{#10*2}{comp_err}{#10*2}Replace expected error?', 'Wrong error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings['#ExpErr'] := comp_err;
                t.resave_settings := true;
                Otp($'%WARNING: Settings updated for "{fwoe}.td"');
              end;
              
              DialogResult.No: ;
              
              DialogResult.Cancel: Halt(-1);
            end;
          
          t.stop_test := true;
        end else
        begin
          
          if t.expected_comp_err<>nil then
            case MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_comp_err}{#10*2}Remove error from expected?', 'Missing error', MessageBoxButtons.YesNoCancel) of
              
              DialogResult.Yes:
              begin
                t.all_settings.Remove('#ExpErr');
                t.resave_settings := true;
                Otp($'%WARNING: Settings updated for "{fwoe}.td"');
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
    
    static procedure ExecAll;
    begin
      
      foreach var t in all_loaded do
        if (t.req_modules<>nil) and t.test_mode.Contains('Exec') then
        try
          var fwoe := t.pas_fname.Remove(t.pas_fname.LastIndexOf('.'));
          
          if t.stop_test then
          begin
            Otp($'WARNING: Test[{fwoe}] wasn''t executed because of prior errors');
            continue;
          end;
          
          if not FileExists(fwoe+'.exe') then
          begin
            Otp($'ERROR: File {fwoe}.exe not found');
            continue;
          end;
          
          var (res, err) := ExecuteTestExe(GetFullPath(fwoe+'.exe'), $'Test[{fwoe}]');
          res := res?.Remove(#13)?.Trim(#10);
          err := err?.Remove(#13)?.Trim(#10);
          
          if err<>nil then
          begin
            
            if t.expected_exec_err=nil then
              case MessageBox.Show($'In "{fwoe}.exe":{#10*2}{err}{#10*2}Add this to expected errors?', 'Unexpected exec error', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  t.all_settings['#ExpExecErr'] := err;
                  t.used_settings += '#ExpExecErr';
                  t.resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"');
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
              end else
              
            if t.expected_exec_err<>err then
              case MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_exec_err}{#10*2}Current error:{#10*2}{err}{#10*2}Replace expected error?', 'Wrong exec error', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  t.all_settings['#ExpExecErr'] := err;
                  t.resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"');
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
              end;
            
            if t.expected_otp<>nil then
            begin
              t.all_settings.Remove('#ExpOtp');
              t.resave_settings := true;
            end;
            
          end else
          begin
            
            if t.expected_exec_err<>nil then
              case MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_exec_err}{#10*2}Remove error from expected?', 'Missing exec error', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  t.all_settings.Remove('#ExpErr');
                  t.resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"');
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
              end;
            
            if t.expected_otp=nil then
            begin
              t.all_settings['#ExpOtp'] := res;
              t.used_settings += '#ExpOtp';
              t.resave_settings := true;
              Otp($'WARNING: Settings updated for "{fwoe}.td"');
            end else
            if t.expected_otp<>res then
            begin
              
              case MessageBox.Show($'In "{fwoe}.exe"{#10}Expected:{#10*2}{t.expected_otp}{#10*2}Current output:{#10*2}{res}{#10*2}Replace expected output?', 'Wrong output', MessageBoxButtons.YesNoCancel) of
                
                DialogResult.Yes:
                begin
                  t.all_settings['#ExpOtp'] := res;
                  t.used_settings += '#ExpOtp';
                  t.resave_settings := true;
                  Otp($'%WARNING: Settings updated for "{fwoe}.td"');
                end;
                
                DialogResult.No: ;
                
                DialogResult.Cancel: Halt(-1);
                
              end;
            end;
            
          end;
          
        except
          on TestCanceledException do ;
        end;
      
    end;
    
    static procedure Cleanup;
    begin
      Otp('Cleanup');
      
      foreach var t in all_loaded do
        if t.resave_settings then
        begin
          var sw := new System.IO.StreamWriter(System.IO.File.Create(t.td_fname), enc);
          sw.WriteLine;
          sw.WriteLine;
          
          var used_settings := t.used_settings.ToHashSet;
          foreach var key in t.all_settings.Keys do
            if not used_settings.Contains(key) then
              Otp($'WARNING: Setting {key} was deleted from "{t.td_fname}"') else
            begin
              sw.WriteLine;
              sw.WriteLine(key);
              sw.WriteLine(t.all_settings[key]);
            end;
          
          sw.WriteLine;
          sw.WriteLine;
          sw.Close;
          Otp($'WARNING: File "{t.td_fname}" updated');
        end;
      
      foreach var dir in test_folders do
        foreach var mn in allowed_modules do
        begin
          System.IO.File.Delete($'{dir}\{mn}.pcu');
          if mn.EndsWith('ABC') then
            System.IO.File.Delete($'{dir}\{mn}Base.pcu');
        end;
      
      foreach var du_otp in domain_unload_otps do
        foreach var l in du_otp do
          Otp(l);
      
    end;
    
  end;
  
begin
  try
    TestInfo.LoadCLA;
    
    TestInfo.LoadAll('Tests\Comp',  HSet('Comp'));
    TestInfo.LoadAll('Samples',     HSet('Comp'));
    TestInfo.LoadAll('Tests\Exec',  HSet('Comp','Exec'));
    
    try
      TestInfo.CompAll;
      TestInfo.ExecAll;
    finally
      TestInfo.Cleanup;
    end;
    
    Otp('Done testing');
    if not is_secondary_proc then Otp('Press Enter to exit');
  except
    on e: Exception do ErrOtp(e);
  end;
end.