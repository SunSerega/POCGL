program prog;

uses System.Threading.Tasks;
uses Pack_Utils in 'Packing\Pack_Utils.pas';

begin
  try
    
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.pcu', System.IO.SearchOption.AllDirectories).ForEach(System.IO.File.Delete);
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.pdb', System.IO.SearchOption.AllDirectories).Where(fname->not fname.EndsWith('PackAll.pdb')).ForEach(System.IO.File.Delete);
    
    // ====================================================
    
    (
      CompTask('..\OpenCLABC.pas') *
      (
        ExecTask('Pack Template.pas', 'Template[0OpenGL]', 'fname=0OpenGL.template', 'GenPas') +
        new Task(()->System.IO.File.Delete('OpenGL.pas')) +
        new Task(()->System.IO.File.Move('Packing\0OpenGL.pas', 'OpenGL.pas')) +
        new Task(()->WriteAllText('OpenGL.pas', ReadAllText('OpenGL.pas', new System.Text.UTF8Encoding(true)).Replace(#10,#13#10), new System.Text.UTF8Encoding(true))) +
//        new Task(()->System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.templateres').ForEach(System.IO.File.Delete)) +
        CompTask('..\OpenGLABC.pas')
      ) *
      CompTask('..\Tests\Tester.pas')
      
      + ExecTask('..\Tests\Tester.exe', 'Tester')
    ).RunSynchronously;
    
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
      writeln($'Packing sample "Release\Installer{fname}"');
      System.IO.File.Copy(fname, 'Release\Installer'+fname);
    end);
    
    // ====================================================
    
    writeln('done packing');
    if not CommandLineArgs.Contains('SecondaryProc') then Readln;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.