program prog;

uses System.Threading;
uses System.Threading.Tasks;
uses System.IO;
uses MiscUtils in 'Utils\MiscUtils.pas';

// АРГУМЕНТЫ КОМАНДНОЙ СТРОКИ:
// 
// - "SecondaryProc" | что то вроде тихого режима:
//   - Readln в конце НЕТУ
//   - Halt возвращает код исключения, при ошибке
//   - Данные о замерах времени в конце не выводятся
// 
// - "StagesOnly=...+...+..." | запускает только указанные стадии упаковки
//   - "FirstPack"  - Датаскрапинг спецификаций и исходников. Следует проводить только 1 раз, единственная по-умолчанию выключенная стадия
//   - "Spec"       - Упаковка справок
//   - "CL"         - Упаковка "OpenCL.pas"
//   - "CLABC"      - Упаковка "OpenCLABC.pas"
//   - "GL"         - Упаковка "OpenGL.pas"
//   - "GLABC"      - Упаковка "OpenGLABC.pas"
//   - "Test"       - Тестирование (вообще можно запускать тестер напрямую)
//   - "Release"    - Создание и наполнение папки Release, а так же копирование чего надо в ProgramFiles
// === к примеру: "StagesOnly=CLABC+Test+Release"
// === лишние пробелы по краям имён стадий допускаются, но "StagesOnly=" должно быть слитно и без пробелов в начале
// 

function AllModules := Lst('OpenCL','OpenCLABC','OpenGL','OpenGLABC');

function TitleTask(title: string; decor: char := '='): SecThrProc;
begin
  var c := 80-title.Length;
  var c2 := c div 2;
  var c1 := c-c2;
  
  var sb := new StringBuilder;
  sb.Append(decor,c1);
  sb += ' ';
  sb += title;
  sb += ' ';
  sb.Append(decor,c2);
  title := sb.ToString;
  
  Result := ProcTask(()->Otp(title));
end;

begin
  try
    
    {$region Load}
    
    log_file := 'LastPack.log';
    timed_log_file := 'LastPack (timed).log';
    System.IO.File.Delete(log_file);
    System.IO.File.Delete(timed_log_file);
    
    var enc := new System.Text.UTF8Encoding(true);
    
    // ====================================================
    
    var stages: HashSet<string>;
    begin
      var arg := CommandLineArgs.SingleOrDefault(arg->arg.StartsWith('StagesOnly='));
      
      if arg=nil then
      begin
        stages := HSet('Spec', 'CL', 'CLABC', 'GL', 'GLABC', 'Test', 'Release');
        Otp($'Executing default stages:');
      end else
      begin
        stages := arg.Remove(0,'StagesOnly='.Length).Split('+').Select(st->st.Trim).ToHashSet;
        Otp($'Executing only stages:');
      end;
      
      Otp(stages.JoinIntoString(' + '));
    end;
    
    {$endregion Load}
    
    {$region MiscClear}
    
    var T_MiscClear :=
      ProcTask(()->
      begin
        var c := 0;
        var skip_pcu := AllModules;
        skip_pcu.RemoveAll(mn->stages.Contains(mn.SubString(4)));
        skip_pcu.Transform(mn->mn+'.pcu');
        
        foreach var fname in Arr('*.pcu','*.pdb').SelectMany(p->Directory.EnumerateFiles(GetCurrentDir, p, SearchOption.AllDirectories)) do
        begin
          if skip_pcu.Contains(Path.GetFileName(fname)) then continue;
          try
            System.IO.File.Delete(fname);
          except end;
          c += 1;
        end;
        
//        if c<>0 then Otp($'Cleared {c} files');
      end)
    ;
    
    {$endregion MiscClear}
    
    {$region MiscInit}
    var T_MiscInit: SecThrProc;
    
    var E_Tester          := new ManualResetEvent(false);
    var E_DocPacker       := new ManualResetEvent(false);
    var E_TemplatePacker  := new ManualResetEvent(false);
    
    begin
      
      {$region Tester}
      
      var T_Tester := not stages.Contains('Test') ? EmptyTask :
        CompTask('Tests\Tester.pas') +
        SetEvTask(E_Tester)
      ;
      
      {$endregion Tester}
      
      {$region DocPacker}
      
      var T_DocPacker := not Arr('CLABC').Any(st->stages.Contains(st)) ? EmptyTask :
        CompTask('Packing\Doc\PackComments.pas') +
        SetEvTask(E_DocPacker)
      ;
      
      {$endregion DocPacker}
      
      {$region TemplatePacker}
      
      var T_TemplatePacker := not Arr('GL').Any(st->stages.Contains(st)) ? EmptyTask :
        CompTask('Packing\Template\Pack Template.pas') +
        SetEvTask(E_TemplatePacker)
      ;
      
      {$endregion TemplatePacker}
      
      T_MiscInit :=
        TitleTask('Pre Init')
        +
        
        T_Tester *
        T_DocPacker *
        T_TemplatePacker
        
        +
        EmptyTask()
      ;
    end;
    {$endregion MiscInit}
    
    {$region FirstPack}
    var T_FirstPack: SecThrProc;
    if not stages.Contains('FirstPack') then
      T_FirstPack := EmptyTask else
    begin
      
      {$region UpdateReps}
      
      var T_UpdateReps :=
        TitleTask('Update Reps', '~')
        +
        
        ExecTask('DataScraping\Reps\0BrokenSource\GL\GenerateCoreSource.pas', 'GL BrokenSource') *
        ExecTask('DataScraping\Reps\PullReps.pas',                            'GLRep Update')
        
      ;
      
      {$endregion UpdateReps}
      
      {$region ParseSpec}
      
      var T_ParseSpec_GL_Core :=
        TitleTask('Parse Spec | GL | Core', '~') +
        
        ExecTask('DataScraping\SpecFormating\GL\Get1.1 Funcs.pas',      'SpecFormater[GL,1.1]') *
        ExecTask('DataScraping\SpecFormating\GL\GetPDF Funcs.pas',      'SpecFormater[GL]', AddTimeMarksStr) *
        CompTask('DataScraping\SpecFormating\GL\DebugChapVerView.pas') *
        CompTask('DataScraping\SpecFormating\GL\DebugVerDifView.pas')
        +
        ExecTask('DataScraping\SpecFormating\GL\DebugChapVerView.exe',  'DebugView[CoreSpecs]') *
        ExecTask('DataScraping\SpecFormating\GL\DebugVerDifView.exe',   'DebugView[CoreSpecDifs]')
        
      ;
      
      var T_ParseSpec_GL_Ext :=
        TitleTask('Parse Spec | GL | Ext', '~') +
        
        ExecTask('DataScraping\SpecFormating\GLExt\Format ext spec text.pas', 'SpecReader[GLExt]') +
        ExecTask('DataScraping\SpecFormating\GLExt\Format ext spec bin.pas',  'SpecFormater[GLExt]')
        
      ;
      
      {$endregion ParseSpec}
      
      T_FirstPack :=
        TitleTask('First Pack') +
        T_UpdateReps
        +
        
        T_ParseSpec_GL_Ext *
        T_ParseSpec_GL_Core
        
        +
        EmptyTask
      ;
    end;
    {$endregion FirstPack}
    
    {$region Spec}
    
    var T_Spec := not stages.Contains('Spec') ? EmptyTask :
      TitleTask('Specs') +
      ExecTask('Packing\Spec\SpecPacker.pas', 'SpecPacker')
    ;
    
    {$endregion Spec}
    
    {$region CL}
    
    var T_CL := not stages.Contains('CL') ? EmptyTask :
      TitleTask('OpenCL') +
      EmptyTask // ToDo
    ;
    
    var T_CLABC := not stages.Contains('CLABC') ? EmptyTask :
      TitleTask('OpenCLABC') +
      CompTask('OpenCLABC.pas') +
      EventTask(E_DocPacker) +
      ExecTask('Packing\Doc\PackComments.exe', 'Comments[OpenCLABC]', 'fname=OpenCLABC')
    ;
    
    {$endregion CL}
    
    {$region GL}
    
    var T_GL := not stages.Contains('GL') ? EmptyTask :
      TitleTask('OpenGL') +
      EventTask(E_TemplatePacker) +
      ExecTask('Packing\Template\Pack Template.exe', 'Template[OpenGL]', 'fname=Packing\Template\GL\0OpenGL.template', 'GenPas') +
      ProcTask(()->System.IO.File.Delete('OpenGL.pas')) +
      ProcTask(()->System.IO.File.Move('Packing\Template\GL\0OpenGL.pas', 'OpenGL.pas')) +
      ProcTask(()->WriteAllText('OpenGL.pas', ReadAllText('OpenGL.pas', enc).Replace(#10,#13#10), enc))
    ;
    
    var T_GLABC := not stages.Contains('GLABC') ? EmptyTask :
      TitleTask('OpenGLABC') +
      CompTask('OpenGLABC.pas')
    ;
    
    {$endregion GL}
    
    {$region Test}
    
    var T_Test := not stages.Contains('Test') ? EmptyTask :
      TitleTask('Testing') +
      EventTask(E_Tester) +
      ExecTask('Tests\Tester.exe', 'Tester', AddTimeMarksStr)
    ;
    
    {$endregion Test}
    
    {$region Release}
    var T_Release: SecThrProc;
    if not stages.Contains('Release') then
      T_Release := EmptyTask else
    begin
      
      {$region Clear}
      
      var T_Clear :=
        ProcTask(()->
        begin
          if System.IO.Directory.Exists('Release') then
            System.IO.Directory.Delete('Release', true);
        end)
      ;
      
      {$endregion Clear}
      
      {$region CopyModules}
      
      var T_CopyModules :=
        ProcTask(()->
        begin
          System.IO.Directory.CreateDirectory('Release\bin\Lib');
          var mns := AllModules;
          mns.RemoveAll(mn->not stages.Contains(mn.SubString(4)));
          
          var pf_dir := 'C:\Program Files (x86)\PascalABC.NET';
          var copy_to_pf := Directory.Exists(pf_dir);
          if not copy_to_pf then Otp($'WARNING: Dir "{pf_dir}" not found, skiping pf release copy');
          
          foreach var mn in mns do
          begin
            var fname := $'{mn}.pas';
            if not FileExists(fname) then raise new MessageException($'ERROR: {fname} not found!');
            
            var rel_fname := $'Packing\Doc\{mn}.res.pas';
            
            if FileExists(rel_fname) then
              Otp($'Packing {fname} with doc') else
            begin
              rel_fname := fname;
              Otp($'Packing {fname}');
            end;
            
            System.IO.File.Copy( fname, $'Release\bin\Lib\{fname}' );
            if copy_to_pf then System.IO.File.Copy( fname, $'{pf_dir}\LibSource\{fname}', true );
          end;
          
          if copy_to_pf then
            foreach var mn in mns do
            begin
              var fname := $'{mn}.pcu';
              
              if FileExists(fname) then
                System.IO.File.Copy( fname, $'{pf_dir}\Lib\{mn}.pcu', true ) else
                Otp($'WARNING: {fname} not found!');
              
            end;
          
          Otp($'Done copying release modules');
        end)
      ;
      
      {$endregion CopyModules}
      
      {$region CopySamples}
      
      var T_CopySamples :=
        ProcTask(()->
        begin
          var c := 0;
          
          System.IO.Directory.EnumerateFiles('Samples', '*.*', System.IO.SearchOption.AllDirectories)
          .Where(fname->Path.GetExtension(fname) in ['.pas', '.cl'])
          .Where(fname->not (Path.GetFileNameWithoutExtension(fname) in [
            'OpenCL', 'OpenCLABC',
            'OpenGL', 'OpenGLABC'
          ]))
          .ForEach(fname->
          begin
            Otp($'Packing sample "{fname}"');
            var res_f_name := 'Release\InstallerSamples\OpenCL и OpenGL'+fname.Substring('Samples'.Length);
            System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(res_f_name));
            System.IO.File.Copy(fname, res_f_name);
            c += 1;
          end);
          
          Otp($'Packed {c} samples');
        end)
      ;
      
      {$endregion CopySamples}
      
      {$region CopySpec}
      
      var T_CopySpec :=
        ProcTask(()->
        begin
          var c := 0;
          System.IO.Directory.CreateDirectory('Release\InstallerSamples\OpenCL и OpenGL');
          
          foreach var spec in Arr('Справка OpenGLABC', 'Справка OpenCLABC', 'Гайд по использованию OpenCL и OpenGL') do
          begin
            var fname := $'Packing\Spec\{spec}.html';
            if FileExists(fname) then
            begin
              Otp($'Packing spec "{fname}"');
              System.IO.File.Copy( fname, $'Release\InstallerSamples\OpenCL и OpenGL\{spec}.html' );
              c += 1;
            end else
              Otp($'WARNING: spec file {fname} not found!');
            
          end;
          
          Otp($'Packed {c} spec files');
        end)
      ;
      
      {$endregion CopySpec}
      
      T_Release :=
        TitleTask('Release') +
        T_Clear
        +
        
        T_CopyModules *
        T_CopySamples *
        T_CopySpec
        
        +
        EmptyTask()
      ;
    end;
    {$endregion Release}
    
    {$region ExecAll}
    
    (
      T_MiscClear +
      T_FirstPack
      +
      
      T_Spec *
      ( T_CL + T_CLABC ) *
      ( T_GL + T_GLABC ) *
      
      T_MiscInit
      
      +
      ( T_Test + T_Release )
    ).SyncExec;
    
    Otp('done packing');
    if not CommandLineArgs.Contains('SecondaryProc') then
    begin
      Timers.LogAll;
      Readln;
    end;
    
    {$endregion ExecAll}
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.