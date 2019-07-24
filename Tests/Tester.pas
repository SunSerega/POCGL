
{$reference System.Windows.Forms.dll}
type MessageBox = System.Windows.Forms.MessageBox;
type MessageBoxButtons = System.Windows.Forms.MessageBoxButtons;
type MessageBoxIcon = System.Windows.Forms.MessageBoxIcon;
type MessageBoxDefaultButton = System.Windows.Forms.MessageBoxDefaultButton;
type DialogResult = System.Windows.Forms.DialogResult;

{ $define SingleThread}
{ $define WriteDone}

const
  PasCompiler = 'C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe';
  
var
  MainFolder := System.IO.Path.GetDirectoryName(GetCurrentDir);
  
///Result=True когда времени не хватило
function TimedExecute(p: procedure; t: integer): boolean;
begin
  {$ifndef SingleThread}
  var res := false;
  var err: Exception;
  
  var exec_thr := new System.Threading.Thread(()->
    try
      p;
    except
      on e: System.Threading.ThreadAbortException do ;
      on e2: Exception do err := e2; // ToDo #1900
    end);
  var stop_thr := new System.Threading.Thread(()->
    begin
      Sleep(t);
      exec_thr.Abort;
      res := true;
    end);
  
  exec_thr.Start;
  stop_thr.Start;
  exec_thr.Join;
  stop_thr.Abort;
  
  if err<>nil then raise new Exception('',err);
  Result := res;
  {$else}
  p;
  Result := false;
  {$endif}
end;

type
  TestCanceledException = class(Exception) end;
  
  CompTester = class
    expected_comp_err: string;
    
    settings := new Dictionary<string, string>;
    used_settings := new HashSet<string>;
    static write_lock := new object;
    
    constructor;
    begin
      used_settings += '#SkipTest';
      used_settings += '#ExpErr';
    end;
    
    procedure LoadSettings(pas_fname, td_fname: string); virtual;
    begin
      
      if not System.IO.File.Exists(td_fname) then
      begin
        if ReadLines(pas_fname).First.StartsWith('unit') then
        begin
          WriteAllText(td_fname, '#SkipTest', System.Text.Encoding.UTF8);
          raise new TestCanceledException;
        end;
        
        case MessageBox.Show($'File {td_fname} not found'+#10'Mark .pas file as test-ignored?', 'New .pas file', MessageBoxButtons.YesNoCancel, MessageBoxIcon.Exclamation, MessageBoxDefaultButton.Button2) of
          
          DialogResult.Yes:
          begin
            WriteAllText(td_fname, '#SkipTest', System.Text.Encoding.UTF8);
            raise new TestCanceledException;
          end;
          
          DialogResult.No: WriteAllText(td_fname, '', System.Text.Encoding.UTF8);
          
          DialogResult.Cancel: Halt;
        end;
        
      end;
      
      var lns := ReadAllLines(td_fname);
      
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
        
        settings.Add(key, sb.ToString.TrimEnd(#10).Replace('\#','#'));
      end;
      
      if settings.ContainsKey('#SkipTest') then raise new TestCanceledException;
      
      if not settings.TryGetValue('#ExpErr', expected_comp_err) then expected_comp_err := nil;
      
    end;
    
    procedure Test(pas_fname, td_fname: string); virtual;
    begin
//      $'"{System.IO.Path.GetFullPath(pas_fname)}" cd="{MainFolder}" OutDir="{System.IO.Path.GetFullPath(System.IO.Path.GetDirectoryName(pas_fname))}"'.Println;
      
      var psi := new System.Diagnostics.ProcessStartInfo(PasCompiler, $'"{System.IO.Path.GetFullPath(pas_fname)}"');
      psi.UseShellExecute := false;
      psi.RedirectStandardInput := true;
      psi.RedirectStandardOutput := true;
      psi.RedirectStandardError := true;
      
      var comp := System.Diagnostics.Process.Start(psi);
      comp.StandardInput.WriteLine;
      comp.WaitForExit;
      
      var otp := comp.StandardOutput.ReadToEnd.Remove(#13).Trim(#10);
//      otp.Println;
      if otp.ToLower.Contains('error') then
      begin
        
        if expected_comp_err=nil then
          case MessageBox.Show($'In "{pas_fname}":{#10*2}{otp}{#10*2}Add this to expected errors?', 'Unexpected error', MessageBoxButtons.YesNoCancel) of
            
            DialogResult.Yes:
            begin
              settings['#ExpErr'] := otp;
              lock write_lock do Writeln($'%WARNING: settings updated for "{pas_fname}"');
            end;
            
            DialogResult.Cancel: Halt;
          end else
          if expected_comp_err<>otp then
          case MessageBox.Show($'In "{pas_fname}"{#10}Expected:{#10*2}{expected_comp_err}{#10*2}Current error:{#10*2}{otp}{#10*2}Replace expected error?', 'Wrong error', MessageBoxButtons.YesNoCancel) of
            
            DialogResult.Yes:
            begin
              settings['#ExpErr'] := otp;
              lock write_lock do Writeln($'%WARNING: settings updated for "{pas_fname}"');
            end;
            
            DialogResult.Cancel: Halt;
          end;
        
      end else
      if expected_comp_err<>nil then
        case MessageBox.Show($'In "{pas_fname}"{#10}Expected:{#10*2}{expected_comp_err}{#10*2}Remove error from expected?', 'Error expected', MessageBoxButtons.YesNoCancel) of
          
          DialogResult.Yes:
          begin
            settings.Remove('#ExpErr');
            lock write_lock do Writeln($'%WARNING: settings updated for "{pas_fname}"');
          end;
          
          DialogResult.Cancel: Halt;
        end;
      
    end;
    
    procedure SaveSettings(fname: string);
    begin
      var res := new StringBuilder;
      res += #10;
      
      foreach var kvp in settings do
        if used_settings.Contains(kvp.Key) then
        begin
          res += kvp.Key;
          res += #10;
          res += kvp.Value.Replace('#','\#');
          res += #10;
        end else
          lock write_lock do Writeln($'WARNING: setting {kvp.Key} was deleted from "{fname}"');
      
      var st := res.ToString;
      if ReadAllText(fname, System.Text.Encoding.UTF8) <> st then
      begin
        WriteAllText(fname, st, System.Text.Encoding.UTF8);
        lock write_lock do Writeln($'WARNING: settings were resaved in "{fname}"');
      end;
    end;
    
    
    
    static procedure TestAll(path: string; get_tester: ()->CompTester);
    begin
      
      foreach var fname in System.IO.Directory.EnumerateDirectories(path, '*.*', System.IO.SearchOption.AllDirectories).Prepend(path) do
      begin
        System.IO.File.Copy( MainFolder+'\OpenCL.pcu',    fname+'\OpenCL.pcu',    true );
        System.IO.File.Copy( MainFolder+'\OpenCLABC.pcu', fname+'\OpenCLABC.pcu', true );
        System.IO.File.Copy( MainFolder+'\OpenGL.pcu',    fname+'\OpenGL.pcu',    true );
        System.IO.File.Copy( MainFolder+'\OpenGLABC.pcu', fname+'\OpenGLABC.pcu', true );
      end;
      
      var procs :=
        System.IO.Directory.EnumerateFiles(
          path, '*.pas', System.IO.SearchOption.AllDirectories
        ).Select&<string,()->()>(pas_fname->()->
        try
          if pas_fname.EndsWith('OpenCL.pas') then exit;
          if pas_fname.EndsWith('OpenCLABC.pas') then exit;
          if pas_fname.EndsWith('OpenGL.pas') then exit;
          if pas_fname.EndsWith('OpenGLABC.pas') then exit;
          
          {$ifdef WriteDone}
          lock write_lock do Writeln($'STARTED: "{pas_fname}"');
          {$endif WriteDone}
          
          var tester: CompTester := get_tester();
          var td_fname := pas_fname.Remove(pas_fname.LastIndexOf('.')) + '.td';
          
          tester.LoadSettings(pas_fname, td_fname);
          tester.Test(pas_fname, td_fname);
          
          tester.SaveSettings(td_fname);
          
          {$ifdef WriteDone}
          lock write_lock do Writeln($'DONE: "{pas_fname}"');
//          Readln;
          {$endif WriteDone}
          
        except
          on e: TestCanceledException do;
          on e: Exception do lock write_lock do
          begin
            Writeln($'ERROR: "{pas_fname}"');
            Writeln(e);
          end;
        end)
        .ToArray
      ;
      
      {$ifdef SingleThread}
      foreach var proc in procs do proc;
      {$else SingleThread}
      System.Threading.Tasks.Parallel.Invoke(procs);
      {$endif SingleThread}
      
      foreach var fname in System.IO.Directory.EnumerateDirectories(path, '*.*', System.IO.SearchOption.AllDirectories).Prepend(path) do
      begin
        System.IO.File.Delete(fname+'\OpenCL.pcu');
        System.IO.File.Delete(fname+'\OpenCLABC.pcu');
        System.IO.File.Delete(fname+'\OpenGL.pcu');
        System.IO.File.Delete(fname+'\OpenGLABC.pcu');
      end;
      
    end;
    
    static procedure TestAll :=
    TestAll('Comp', ()->new CompTester);
    
    static procedure TestExamples :=
    TestAll(MainFolder + '\Samples', ()->new CompTester);
    
  end;
  
  ExecTester = class(CompTester)
    expected_otp: string;
    
    constructor;
    begin
      used_settings += '#ExpOtp';
    end;
    
    procedure LoadSettings(pas_fname, td_fname: string); override;
    begin
      inherited LoadSettings(pas_fname, td_fname);
      
      if expected_comp_err<>nil then lock write_lock do Writeln($'WARNING: compile error is expected in Exec test "{pas_fname}"');
      
      if not settings.TryGetValue('#ExpOtp', expected_otp) then expected_otp := nil;
      
    end;
    
    procedure Test(pas_fname, td_fname: string); override;
    begin
      inherited Test(pas_fname, td_fname);
      
      var psi := new System.Diagnostics.ProcessStartInfo(pas_fname.Remove(pas_fname.LastIndexOf('.')) + '.exe');
      psi.UseShellExecute := false;
      psi.RedirectStandardOutput := true;
      
      var p := System.Diagnostics.Process.Start(psi);
      if TimedExecute(p.WaitForExit, 5000) then
      begin
        p.Kill;
        lock write_lock do Writeln($'ERROR: execution took too long for "{pas_fname}"');
      end;
      
      var otp := p.StandardOutput.ReadToEnd.Remove(#13).Trim(#10);
      if expected_otp=nil then
      begin
        settings['#ExpOtp'] := otp;
        lock write_lock do Writeln($'WARNING: settings updated for "{pas_fname}"');
      end else
      if expected_otp<>otp then
      begin
        writeln($'{expected_otp.Length} : {otp.Length}');
        expected_otp.ZipTuple(otp)
        .Select(t->(word(t[0]), word(t[1])))
        .PrintLines;
        halt;
        
        case MessageBox.Show($'In "{pas_fname}"{#10}Expected:{#10*2}{expected_otp}{#10*2}Current output:{#10*2}{otp}{#10*2}Replace expected output?', 'Wrong output', MessageBoxButtons.YesNoCancel) of
          
          DialogResult.Yes:
          begin
            settings['#ExpOtp'] := otp;
            lock write_lock do Writeln($'%WARNING: settings updated for "{pas_fname}"');
          end;
          
          DialogResult.Cancel: Halt;
        end;
      end;
      
    end;
    
    
    
    static procedure TestAll :=
    TestAll('Exec', ()->new ExecTester);
    
  end;

begin
  
  try
    
    {$ifdef SingleThread}
    CompTester.TestExamples;
    CompTester.TestAll;
    ExecTester.TestAll;
    {$else SingleThread}
    System.Threading.Tasks.Parallel.Invoke(
      CompTester.TestExamples,
      CompTester.TestAll,
      ExecTester.TestAll
    );
    {$endif SingleThread}
    
    Writeln('Done testing');
    
  except
    on e: Exception do
    begin
      Writeln(e);
      readln;
    end;
  end;
  
  if not (System.Console.IsOutputRedirected or System.Console.IsInputRedirected or System.Console.IsErrorRedirected) then ReadlnString('Press Enter to exit');
end.