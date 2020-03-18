uses MiscUtils in '..\Utils\MiscUtils.pas';

{$reference System.Windows.Forms.dll}
type MessageBox               = System.Windows.Forms.MessageBox;
type MessageBoxButtons        = System.Windows.Forms.MessageBoxButtons;
type MessageBoxIcon           = System.Windows.Forms.MessageBoxIcon;
type MessageBoxDefaultButton  = System.Windows.Forms.MessageBoxDefaultButton;
type DialogResult             = System.Windows.Forms.DialogResult;

const
  MaxExecTime = 5000;
  
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
      Otp($'ERROR: Execution took too long for "{fname}"');
    end else
      dom.SetData('Result', res.ToString);
    
  except
    on e: Exception do System.AppDomain.CurrentDomain.SetData('fatal_err', e.ToString);
  end);
  
  if dom.GetData('fatal_err') is string(var fatal_err) then
    ErrOtp(new MessageException(fatal_err));
  
  otp_l.s := $'Done executing {nick}';
  otp_l.t += int64(dom.GetData('exec_time'));
  Otp(otp_l);
  
  Result := (
    dom.GetData('Result') as string,
    dom.GetData('Err') as string
  );
  System.AppDomain.Unload(dom);
end;

type
  TestCanceledException = class(Exception) end;
  
  TestInfo = sealed class
    pas_fname, td_fname: string;
    
    all_settings := new Dictionary<string, string>;
    used_settings := new List<string>;
    resave_settings := false;
    
    test_mode: HashSet<string>;
    req_modules: IList<string>;
    expected_comp_err: string;
    expected_otp: string;
    expected_exec_err: string;
    
    static valid_modules := HSet('CL','CLABC', 'GL','GLABC');
    static allowed_modules := new HashSet<string>(valid_modules.Count);
    
    static all_loaded := new List<TestInfo>;
    static test_folders := new List<string>;
    
    {$region Load}
    
    static procedure LoadCLA;
    const modules_def = 'Modules=';
    begin
      var arg := CommandLineArgs.FirstOrDefault(arg->arg.StartsWith(modules_def));
      if arg<>nil then
        foreach var w in arg.Remove(0,modules_def.Length).ToWords('+') do
          allowed_modules += w;
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
          foreach var _m in l.Substring('uses'.Length).ToWords(',',' ',';') do
          begin
            var m := _m;
            if m.StartsWith('Open') then m := m.Substring('Open'.Length);
            if m in valid_modules then
              req_modules.Add(m);
          end;
      all_settings.Add('#ReqModules', req_modules.JoinToString('+'));
      used_settings += '#ReqModules';
      resave_settings := true;
    end;
    
    function ExtractSettingStr(name: string; def: string := nil): string;
    begin
      if all_settings.TryGetValue(name, Result) then
        used_settings += name else
        Result := def;
    end;
    
    static procedure LoadAll(path: string; exp_mode: string);
    begin
      if not System.IO.Directory.Exists(path) then exit;
      
      foreach var dir in System.IO.Directory.EnumerateDirectories(path, '*.*', System.IO.SearchOption.AllDirectories).Prepend(path) do
      begin
        test_folders += dir;
        System.IO.File.Copy( 'OpenCL.pcu',    dir+'\OpenCL.pcu',    true );
        System.IO.File.Copy( 'OpenCLABC.pcu', dir+'\OpenCLABC.pcu', true );
        System.IO.File.Copy( 'OpenGL.pcu',    dir+'\OpenGL.pcu',    true );
        System.IO.File.Copy( 'OpenGLABC.pcu', dir+'\OpenGLABC.pcu', true );
      end;
      
      foreach var pas_fname in System.IO.Directory.EnumerateFiles(path, '*.pas', System.IO.SearchOption.AllDirectories) do
      try
        var t := new TestInfo;
        t.pas_fname := pas_fname;
        t.td_fname := pas_fname.Remove(pas_fname.LastIndexOf('.'))+'.td';
        
        {$region Settings}
        t.LoadSettingsDict;
        
        if t.all_settings.ContainsKey('#SkipTest') then continue;
        all_loaded += t;
        
        t.req_modules := t.ExtractSettingStr('#ReqModules', nil)?.ToWords('+');
        if t.req_modules=nil then t.FindReqModules;
        if not t.req_modules.All(m->allowed_modules.Contains(m)) then
        begin
          t.req_modules := nil;
          continue;
        end;
        
        t.test_mode := t.ExtractSettingStr('#TestMode', exp_mode).ToWords('+').ToHashSet;
        
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
      
      all_loaded.Where(t->(t.req_modules<>nil) and t.test_mode.Contains('Comp'))
      .Select(t->ProcTask(()->
      try
        var fwoe := t.pas_fname.Remove(t.pas_fname.LastIndexOf('.'));
        
        var comp_err: string := nil;
        CompilePasFile(t.pas_fname, Otp, err->begin comp_err := err end);
        
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
      begin
        System.IO.File.Delete( dir+'\OpenCL.pcu'    );
        System.IO.File.Delete( dir+'\OpenCLABC.pcu' );
        System.IO.File.Delete( dir+'\OpenGL.pcu'    );
        System.IO.File.Delete( dir+'\OpenGLABC.pcu' );
      end;
      
    end;
    
  end;
  
begin
  try
    TestInfo.LoadCLA;
    
    TestInfo.LoadAll('Tests\Comp',  'Comp');
    TestInfo.LoadAll('Samples',     'Comp');
    TestInfo.LoadAll('Tests\Exec',  'Comp+Exec');
    
    TestInfo.CompAll;
    TestInfo.ExecAll;
    
    TestInfo.Cleanup;
    
    Otp('Done testing');
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('Press Enter to exit');
  except
    on e: Exception do ErrOtp(e);
  end;
end.