program prog;

uses System.Threading.Tasks;
uses MiscUtils in 'Utils\MiscUtils.pas';

begin
  try
    log_file := 'LastPack.log';
    System.IO.File.Delete(log_file);
    
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.pcu', System.IO.SearchOption.AllDirectories).ForEach(System.IO.File.Delete);
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.pdb', System.IO.SearchOption.AllDirectories).Where(fname->not fname.EndsWith('PackAll.pdb')).ForEach(System.IO.File.Delete);
    
    // ====================================================
    
    (
      (
        ExecTask('Packing\Pack Template.pas', 'Template[OpenGL]', 'fname=Packing\0OpenGL.template', 'GenPas') +
        ProcTask(()->System.IO.File.Delete('OpenGL.pas')) +
        ProcTask(()->System.IO.File.Move('Packing\0OpenGL.pas', 'OpenGL.pas')) +
        ProcTask(()->WriteAllText('OpenGL.pas', ReadAllText('OpenGL.pas', new System.Text.UTF8Encoding(true)).Replace(#10,#13#10), new System.Text.UTF8Encoding(true))) +
//        ProcTask(()->System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.templateres').ForEach(System.IO.File.Delete)) +
        CompTask('OpenGLABC.pas')
      ) *
      CompTask('OpenCLABC.pas') *
      CompTask('Tests\Tester.pas')
      
      + ExecTask('Tests\Tester.exe', 'Tester')
    ).SyncExec;
    
    // ====================================================
    
    if System.IO.Directory.Exists('Release') then
      System.IO.Directory.Delete('Release', true);
    System.IO.Directory.CreateDirectory('Release');
    
    System.IO.Directory.CreateDirectory('Release\bin\Lib');
    System.IO.File.Copy( 'OpenCL.pas',    'Release\bin\Lib\OpenCL.pas'    );
    System.IO.File.Copy( 'OpenCLABC.pas', 'Release\bin\Lib\OpenCLABC.pas' );
    System.IO.File.Copy( 'OpenGL.pas',    'Release\bin\Lib\OpenGL.pas'    );
    System.IO.File.Copy( 'OpenGLABC.pas', 'Release\bin\Lib\OpenGLABC.pas' );
    
    System.IO.Directory.CreateDirectory('Release\InstallerSamples');
    
    foreach var dir in System.IO.Directory.EnumerateDirectories('Samples', '*.*', System.IO.SearchOption.AllDirectories) do
      System.IO.Directory.CreateDirectory('Release\Installer'+dir);
    
    System.IO.Directory.EnumerateFiles('Samples', '*.*', System.IO.SearchOption.AllDirectories)
    .Where(fname->
      fname.EndsWith('.pas') or
      fname.EndsWith('.cl') or
      fname.EndsWith('.txt')
    ).Where(fname->not (
      fname.EndsWith('OpenCL.pas') or
      fname.EndsWith('OpenCLABC.pas') or
      fname.EndsWith('OpenGL.pas') or
      fname.EndsWith('OpenGLABC.pas')
    ))
    .ForEach(fname->
    begin
      Otp($'Packing sample "Release\Installer{fname}"');
      System.IO.File.Copy(fname, 'Release\Installer'+fname);
    end);
    
    // ====================================================
    
    Otp('done packing');
    if not CommandLineArgs.Contains('SecondaryProc') then Readln;
    
  except
    on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
    on e: Exception do ErrOtp(e);
  end;
end.