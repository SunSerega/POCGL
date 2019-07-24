program prog;

procedure ExecNoShell(fname: string; args: string := ''; is_async: boolean := true);
begin
  var p := new System.Diagnostics.Process;
  p.StartInfo.FileName := fname;
  p.StartInfo.Arguments := args;
  p.StartInfo.UseShellExecute := false;
  if is_async then p.StartInfo.RedirectStandardOutput := true;
  p.StartInfo.RedirectStandardInput := true;
  p.Start;
  p.WaitForExit;
  if is_async then write($'{System.IO.Path.GetFileName(fname)}[{args}] : {p.StandardOutput.ReadToEnd}');
end;

procedure Compile(fname: string) := ExecNoShell(
  'C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe',
  $'"{System.IO.Path.GetFullPath(fname)}"'
);

begin
  try
    
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '.pcu').ForEach(System.IO.File.Delete);
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '.pdb').ForEach(System.IO.File.Delete);
    
    // ====================================================
    
    System.Threading.Tasks.Parallel.Invoke(
      ()->Compile('OpenCLABC.pas'),
      ()->Compile('OpenGLABC.pas'),
      ()->Compile('Tests\Tester.pas')
    );
    
    // ====================================================
    
    var wd := System.Environment.CurrentDirectory;
    System.Environment.CurrentDirectory += '\Tests';
    
    ExecNoShell('Tests\Tester.exe', '', false);
    
    System.Environment.CurrentDirectory := wd;
    
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
      fname.EndsWith('.cl')
    ).ForEach(fname->System.IO.File.Copy(fname, 'Release\Installer'+fname));
    
    // ====================================================
    
    writeln('done packing');
    readln;
    
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.