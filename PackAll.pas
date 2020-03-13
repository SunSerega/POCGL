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
// - "Stages=...+...+..." | запускает только указанные стадии упаковки
//   - "FirstPack"  - Датаскрапинг спецификаций и исходников. Следует проводить только 1 раз, единственная по-умолчанию выключенная стадия
//   - "Spec"       - Упаковка справок
//   - "CL"         - Упаковка "OpenCL.pas"
//   - "CLABC"      - Упаковка "OpenCLABC.pas"
//   - "GL"         - Упаковка "OpenGL.pas"
//   - "GLABC"      - Упаковка "OpenGLABC.pas"
//   - "Test"       - Тестирование (вообще можно запускать тестер напрямую)
//   - "Release"    - Создание и наполнение папки Release, а так же копирование чего надо в ProgramFiles
// === к примеру: "Stages= CLABC + Test + Release"
// === лишние пробелы по краям имён стадий допускаются, но "Stages=" должно быть слитно и без пробелов в начале
// 

function AllModules := Lst('OpenCL','OpenCLABC','OpenGL','OpenGLABC');
function AllModulesShort := AllModules.Select(m->m.SubString(4));

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
    
    otp_main += new FileLogger('LastPack.log');
    otp_main += new FileLogger('LastPack (Timed).log', true);
    
    // ====================================================
    
    var stages: HashSet<string>;
    begin
      var arg := CommandLineArgs.SingleOrDefault(arg->arg.StartsWith('Stages='));
      
      if arg=nil then
      begin
        stages := HSet('Spec', 'CL', 'CLABC', 'GL', 'GLABC', 'Test', 'Release');
        otp_main += new FileLogger('LastPack (Default).log');
        Otp($'Executing default stages:');
      end else
      begin
        stages := arg.Remove(0,'Stages='.Length).Split('+').Select(st->st.Trim).ToHashSet;
        Otp($'Executing selected stages:');
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
      
      var T_TemplatePacker := not Arr('CL','GL').Any(st->stages.Contains(st)) ? EmptyTask :
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
        
//        ExecTask('DataScraping\Reps\0BrokenSource\GL\GenerateCoreSource.pas', 'GL BrokenSource') *
        ExecTask('DataScraping\Reps\PullReps.pas', 'SubReps Update', ConsoleLogger.AddTimeMarksStr)
        
      ;
      
      {$endregion UpdateReps}
      
      {$region CompForward}
      
      var T_CompForward :=
        TitleTask('CompForward', '~')
        +
        
        CompTask('DataScraping\XML\CL\ScrapXML.pas') *
        CompTask('DataScraping\XML\GL\ScrapXML.pas')
        
      ;
      
      {$endregion CompForward}
      
      {$region ParseSpec}
      
      var T_ScrapXML :=
        TitleTask('Scrap XML', '~') +
        
        ExecTask('DataScraping\XML\CL\ScrapXML.exe',      'ScrapXML[CL]') *
        ExecTask('DataScraping\XML\GL\ScrapXML.exe',      'ScrapXML[GL]')
        
      ;
      
      {$endregion ParseSpec}
      
      T_FirstPack :=
        TitleTask('First Pack') +
        T_UpdateReps *
        T_CompForward
        +
        
        T_ScrapXML
        
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
      EventTask(E_TemplatePacker) +
      ExecTask('Packing\Template\Pack Template.exe', 'Template[OpenCL]', 'fname=Packing\Template\CL\0OpenCL.template', 'GenPas', ConsoleLogger.AddTimeMarksStr) +
      ProcTask(()->WriteAllText('OpenCL.pas', ReadAllText('Packing\Template\CL\0OpenCL.pas').Replace(#10,#13#10))) +
      ProcTask(()->System.IO.File.Delete('Packing\Template\CL\0OpenCL.pas'))
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
      ExecTask('Packing\Template\Pack Template.exe', 'Template[OpenGL]', 'fname=Packing\Template\GL\0OpenGL.template', 'GenPas', ConsoleLogger.AddTimeMarksStr) +
      ProcTask(()->WriteAllText('OpenGL.pas', ReadAllText('Packing\Template\GL\0OpenGL.pas').Replace(#10,#13#10))) +
      ProcTask(()->System.IO.File.Delete('Packing\Template\GL\0OpenGL.pas'))
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
      ExecTask('Tests\Tester.exe', 'Tester', ConsoleLogger.AddTimeMarksStr, $'Modules={stages.Intersect(AllModulesShort).JoinToString(''+'')}')
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
          if mns.Count=0 then mns := AllModules;
          
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
            if copy_to_pf then
            try
              System.IO.File.Copy( fname, $'{pf_dir}\LibSource\{fname}', true );
            except
              on System.UnauthorizedAccessException do
                Otp($'WARNING: Not enough rights to copy [{fname}] to [Program Files]');
            end;
          end;
          
          if copy_to_pf then
            foreach var mn in mns do
            begin
              var fname := $'{mn}.pcu';
              
              if FileExists(fname) then
              try
                System.IO.File.Copy( fname, $'{pf_dir}\Lib\{mn}.pcu', true );
              except
                on System.UnauthorizedAccessException do
                  Otp($'WARNING: Not enough rights to copy [{fname}] to [Program Files]');
              end else
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
            var res_f_name := 'Release\InstallerSamples\OpenGL и OpenCL'+fname.Substring('Samples'.Length);
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
          System.IO.Directory.CreateDirectory('Release\InstallerSamples\OpenGL и OpenCL');
          
          foreach var spec in Arr('Справка OpenGLABC', 'Справка OpenCLABC', 'Гайд по использованию OpenGL и OpenCL') do
          begin
            var fname := $'Packing\Spec\{spec}.html';
            if FileExists(fname) then
            begin
              Otp($'Packing spec "{fname}"');
              System.IO.File.Copy( fname, $'Release\InstallerSamples\OpenGL и OpenCL\{spec}.html' );
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