program prog;

uses System.Threading.Tasks;
uses MiscUtils in 'Utils\MiscUtils.pas';

begin
  try
    log_file := 'LastPack.log';
    timed_log_file := 'LastPack (timed).log';
    System.IO.File.Delete(log_file);
    System.IO.File.Delete(timed_log_file);
    
    var enc := new System.Text.UTF8Encoding(true);
    
    // ====================================================
    
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.pcu', System.IO.SearchOption.AllDirectories).ForEach(System.IO.File.Delete);
    System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.pdb', System.IO.SearchOption.AllDirectories).Where(fname->not fname.EndsWith('PackAll.pdb')).ForEach(System.IO.File.Delete);
    
    // ====================================================
    
    var T_GL :=
      ExecTask('Packing\Template\Pack Template.pas', 'Template[OpenGL]', 'fname=Packing\Template\GL\0OpenGL.template', 'GenPas') +
      ProcTask(()->System.IO.File.Delete('OpenGL.pas')) +
      ProcTask(()->System.IO.File.Move('Packing\Template\GL\0OpenGL.pas', 'OpenGL.pas')) +
      ProcTask(()->WriteAllText('OpenGL.pas', ReadAllText('OpenGL.pas', enc).Replace(#10,#13#10), enc))
    ;
    
    var T_GLABC := CompTask('OpenGLABC.pas');
    
//    var T_CL := //ToDo
    
    var T_CLABC :=
      CompTask('OpenCLABC.pas') +
      ExecTask('Packing\Doc\PackComments.pas', 'Comments[OpenCLABC]', 'fname=OpenCLABC')
    ;
    
    (
      
      ExecTask('Packing\Spec\SpecPacker.pas', 'SpecPacker') *
      (T_GL + T_GLABC) *
      (       T_CLABC) *
      CompTask('Tests\Tester.pas')
      
      + ExecTask('Tests\Tester.exe', 'Tester')
    ).SyncExec;
    
    // ====================================================
    
    if System.IO.Directory.Exists('Release') then
      System.IO.Directory.Delete('Release', true);
    
    System.IO.Directory.CreateDirectory('Release\bin\Lib');
    System.IO.File.Copy(             'OpenCL.pas',        'Release\bin\Lib\OpenCL.pas'    );
    System.IO.File.Copy( 'Packing\Doc\OpenCLABC.res.pas', 'Release\bin\Lib\OpenCLABC.pas' );
    System.IO.File.Copy(             'OpenGL.pas',        'Release\bin\Lib\OpenGL.pas'    );
    System.IO.File.Copy(             'OpenGLABC.pas',     'Release\bin\Lib\OpenGLABC.pas' );
    
    System.IO.Directory.EnumerateFiles('Samples', '*.*', System.IO.SearchOption.AllDirectories)
    .Where(fname->
      fname.EndsWith('.pas') or
      fname.EndsWith('.cl') or
      fname.EndsWith('.txt')
    ).Where(fname->not (System.IO.Path.GetFileNameWithoutExtension(fname) in [
      'OpenCL', 'OpenCLABC',
      'OpenGL', 'OpenGLABC'
    ]))
    .ForEach(fname->
    begin
      Otp($'Packing sample "{fname}"');
      var res_f_name := 'Release\InstallerSamples\OpenCL и OpenGL'+fname.Substring('Samples'.Length);
      System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(res_f_name));
      System.IO.File.Copy(fname, res_f_name);
    end);
    
    System.IO.File.Copy( 'Packing\Spec\Справка OpenCLABC.html',                     'Release\InstallerSamples\OpenCL и OpenGL\Справка OpenCLABC.html' );
    System.IO.File.Copy( 'Packing\Spec\Справка OpenGLABC.html',                     'Release\InstallerSamples\OpenCL и OpenGL\Справка OpenGLABC.html' );
    System.IO.File.Copy( 'Packing\Spec\Гайд по использованию OpenCL и OpenGL.html', 'Release\InstallerSamples\OpenCL и OpenGL\Гайд по использованию OpenCL и OpenGL.html' );
    
    // ====================================================
    
    Otp('done packing');
    if not CommandLineArgs.Contains('SecondaryProc') then Readln;
    
  except
    on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
    on e: Exception do ErrOtp(e);
  end;
end.