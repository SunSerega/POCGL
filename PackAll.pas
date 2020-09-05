program prog;

uses System.Threading;
uses System.Threading.Tasks;
uses System.IO;
uses MiscUtils in 'Utils\MiscUtils';

// АРГУМЕНТЫ КОМАНДНОЙ СТРОКИ:
// 
// - "OutputPipeId=123 456" | что то вроде тихого режима:
//   - Readln в конце НЕТУ
//   - Halt возвращает код исключения, при ошибке
//   - Данные о замерах времени в конце не выводятся
//   - Вместо 123 должен быть дескриптор анонимного пайпа-сервера в режиме "In". Туда будет направлен вывод
//   - Вместо 456 должен быть дескриптор анонимного пайпа-сервера в режиме "Out". Туда можно отправить byte(1) чтоб аварийно завершить процесс
// 
// - "Stages=...+...+..." | запускает только указанные стадии упаковки
//   - "FirstPack"  - Датаскрапинг спецификаций и исходников. Следует проводить только 1 раз, единственная по-умолчанию выключенная стадия
//   - "Spec"       - Упаковка справок
//   - "OpenCL"     - Упаковка модуля OpenCL.pas
//   - "OpenCLABC"  - Упаковка модуля OpenCLABC.pas
//   - "OpenGL"     - Упаковка модуля OpenGL.pas
//   - "OpenGLABC"  - Упаковка модуля OpenGLABC.pas
//   - "Compile"    - Компиляция всех упакованных модулей
//   - "Test"       - Тестирование (вообще можно запускать тестер напрямую, через его .exe)
//   - "Release"    - Создание и наполнение папки Release, а так же копирование чего надо в ProgramFiles
// === К примеру: "Stages= OpenCLABC + Compile + Test + Release"
// === Лишние пробелы по краям имён стадий допускаются, но "Stages=" должно быть слитно и без пробелов в начале
// 

{$region SpecialNames}

const FirstPackStr  = 'FirstPack';
const SpecStr       = 'Spec';
const OpenCLStr     = 'OpenCL';
const OpenCLABCStr  = 'OpenCLABC';
const OpenGLStr     = 'OpenGL';
const OpenGLABCStr  = 'OpenGLABC';
const CompileStr    = 'Compile';
const TestStr       = 'Test';
const ReleaseStr    = 'Release';

var AllLLModules := HSet(
  OpenCLStr,OpenGLStr
);
var AllModules := HSet(
  OpenCLStr,OpenCLABCStr,
  OpenGLStr,OpenGLABCStr
);
var AllStages := HSet(
  FirstPackStr,
  SpecStr,
  OpenCLStr,OpenCLABCStr,
  OpenGLStr,OpenGLABCStr,
  CompileStr,
  TestStr,
  ReleaseStr
);

{$endregion SpecialNames}

{$region Utils}

function IncludeBaseModules(self: sequence of string); extensionmethod :=
self.SelectMany(mn->
  mn.EndsWith('ABC') ? Seq(
    mn, $'{mn}Base'
  ) : Seq(
    mn
  )
);

{$endregion Utils}

{$region PackStage} type
  
  {$region Base}
  
  PackingStage = abstract class
    id, description, log_name: string;
    log: FileLogger;
    
    static CurrentStages: HashSet<string>;
    static function ModuleStages := AllModules.Intersect(CurrentStages);
    static function IsPackingAllModules := ModuleStages.Count in |0,AllModules.Count|;
    
    static function TitleTask(title: string; decor: char := '='): SecThrProc;
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
      var full_title := sb.ToString;
      
      Result := ProcTask(()->Otp(full_title));
    end;
    
    constructor(name: string);
    begin
      self.id := name;
      self.description := name;
      self.log_name := name;
    end;
    constructor := raise new System.InvalidOperationException;
    
    function MakeTask: SecThrProc;
    begin
      if (id<>nil) and not CurrentStages.Contains(id) then exit;
      Result := MakeCoreTask;
      
      if self.log_name<>nil then
      begin
        self.log := new FileLogger($'Log\{log_name}.log');
        Result := new SecThrProcHandled(Result, self.log.Otp) + ProcTask(self.log.Close);
      end;
      
      if self.description<>nil then
        Result := TitleTask(self.description) + Result;
      
    end;
    function MakeCoreTask: SecThrProc; abstract;
    
  end;
  
  {$endregion Base}
  
  {$region FirstPack}
  
  FirstPackStage = sealed class(PackingStage)
    
    constructor;
    begin
      inherited Create(FirstPackStr);
      self.description := 'First Pack';
    end;
    
    function MakeCoreTask: SecThrProc; override;
    begin
      
      {$region UpdateReps}
      
      var T_UpdateReps :=
        TitleTask('Update Reps', '~')
        +
        
//        ExecTask('DataScraping\Reps\0BrokenSource\GL\GenerateCoreSource.pas', 'GL BrokenSource') *
        ExecTask('DataScraping\Reps\PullReps.pas', 'SubReps Update')
        
      ;
      
      {$endregion UpdateReps}
      
      {$region ParseSpec}
      
      var T_ScrapXML :=
        TitleTask('Scrap XML', '~') +
        
        ExecTask('DataScraping\XML\CL\ScrapXML.pas', 'ScrapXML[CL]') *
        ExecTask('DataScraping\XML\GL\ScrapXML.pas', 'ScrapXML[GL]')
        
      ;
      
      {$endregion ParseSpec}
      
      Result :=
        T_UpdateReps +
        T_ScrapXML
      ;
    end;
    
  end;
  
  {$endregion FirstPack}
  
  {$region Spec}
  
  SpecStage = sealed class(PackingStage)
    
    constructor;
    begin
      inherited Create(SpecStr);
      self.description := 'Specs';
    end;
    
    function MakeCoreTask: SecThrProc; override :=
    ExecTask('Packing\Spec\SpecPacker.pas', 'SpecPacker');
    
  end;
  
  {$endregion Spec}
  
  {$region Modules}
  
  ModulePackingStage = abstract class(PackingStage)
    
    static module_pack_evs := new Dictionary<string, ManualResetEvent>;
    static function GetModulePackEv(module_name: string): ManualResetEvent;
    begin
      lock module_pack_evs do
        if not module_pack_evs.TryGetValue(module_name, Result) then
        begin
          Result := new ManualResetEvent(false);
          module_pack_evs[module_name] := Result;
        end;
    end;
    
    constructor(module_name: string) :=
    inherited Create(module_name);
    
    function MakeCoreTask: SecThrProc; override :=
      MakeModuleTask +
      SetEvTask(GetModulePackEv(self.id));
    function MakeModuleTask: SecThrProc; abstract;
    
  end;
  LLModuleStage = sealed class(ModulePackingStage)
    
    function MakeModuleTask: SecThrProc; override :=
      ExecTask('Packing\Template\Pack Template.pas', $'Template[{id}]', $'nick={id}', $'"inp_fname=Modules\Template\{id}.pas"', $'"otp_fname=Modules\{id}.pas"') +
      ProcTask(()->
      begin
        Directory.CreateDirectory('Modules.Packed');
        System.IO.File.Copy($'Modules\{id}.pas', $'Modules.Packed\{id}.pas', true);
      end)
    ;
    
  end;
  HLModuleStage = sealed class(ModulePackingStage)
    
    function MakeModuleTask: SecThrProc; override :=
      ProcTask(()->Directory.CreateDirectory('Modules.Packed\Internal'))
      +
      
      ExecTask('Packing\Template\Pack Template.pas', $'Template[{id}]',     $'nick={id}', $'"inp_fname=Modules\{id}.pas"',              $'"otp_fname=Modules.Packed\{id}.pas"') *
      ExecTask('Packing\Template\Pack Template.pas', $'Template[{id}Base]', $'nick={id}', $'"inp_fname=Modules\Internal\{id}Base.pas"', $'"otp_fname=Modules.Packed\Internal\{id}Base.pas"')
      
      +
      ExecTask('Packing\Doc\PackComments.pas', $'Comments[{id}]', $'nick={id}', $'"fname=Modules.Packed\{id}.pas"', $'"fname=Modules.Packed\Internal\{id}Base.pas"')
    ;
    
  end;
  
  {$endregion Modules}
  
  {$region Compile}
  
  CompileStage = sealed class(PackingStage)
    
    constructor;
    begin
      inherited Create(CompileStr);
      self.description := 'Compiling';
      if not IsPackingAllModules then log_name := nil;
    end;
    
    function MakeModuleCompileTask(mn: string): SecThrProc;
    begin
      if CurrentStages.Contains(mn      ) then Result += EventTask(ModulePackingStage.GetModulePackEv(mn));
      if CurrentStages.Contains(mn+'ABC') then Result += EventTask(ModulePackingStage.GetModulePackEv(mn+'ABC'));
      
      if CurrentStages.Contains(mn+'ABC') then
      begin
        if not CurrentStages.Contains(mn) then System.IO.File.Copy($'Modules\{mn}.pas', $'Modules.Packed\{mn}.pas', true);
        Result += CompTask($'Modules.Packed\{mn}ABC.pas');
      end else
      if CurrentStages.Contains(mn) then
        Result += CompTask($'Modules.Packed\{mn}.pas');
      
    end;
    
    function MakeCoreTask: SecThrProc; override :=
    AllLLModules.Select(MakeModuleCompileTask).CombineAsyncTask;
    
  end;
  
  {$endregion Compile}
  
  {$region Test}
  
  TestStage = sealed class(PackingStage)
    module_stages_str := ModuleStages.JoinToString(' + ');
    
    constructor;
    begin
      inherited Create(TestStr);
      self.description := 'Testing';
      if not IsPackingAllModules then log_name := nil;
    end;
    
    function MakeCoreTask: SecThrProc; override :=
    ExecTask('Tests\Tester.pas', 'Tester', $'"Modules={module_stages_str}"');
    
  end;
  
  {$endregion Test}
  
  {$region Release}
  
  ReleaseStage = sealed class(PackingStage)
    
    constructor;
    begin
      inherited Create(ReleaseStr);
      if not IsPackingAllModules then log_name := nil;
    end;
    
    function MakeCoreTask: SecThrProc; override;
    begin
      
      {$region Clear}
      
      var T_Clear :=
        ProcTask(()->
          if System.IO.Directory.Exists('Release') then
            System.IO.Directory.Delete('Release', true)
        )
      ;
      
      {$endregion Clear}
      
      {$region CopyModules}
      
      var T_CopyModules :=
        TitleTask('Copying modules', '~') +
        ProcTask(()->
        begin
          var mns := ModuleStages.IncludeBaseModules.ToHashSet;
          var all_modules := mns.Count=0;
          if all_modules then mns := AllModules.IncludeBaseModules.ToHashSet;
          
          var pf_dir := 'C:\Program Files (x86)\PascalABC.NET';
          var copy_to_pf := Directory.Exists(pf_dir);
          if not copy_to_pf then Otp($'WARNING: Dir [{pf_dir}] not found, skiping pf release copy');
          
          foreach var mn in mns do
          begin
            var mn_path := mn.EndsWith('ABCBase') ? $'Internal\{mn}' : mn;
            var org_fname :=      $'Modules.Packed\{mn_path}.pas';
            var release_fname :=  $'Release\bin\Lib\{mn_path}.pas';
            var pf_fname :=       $'{pf_dir}\LibSource\{mn_path}.pas';
            Otp($'Packing {org_fname}');
            
            System.IO.Directory.CreateDirectory(Path.GetDirectoryName(release_fname));
            System.IO.File.Copy( org_fname, release_fname );
            if copy_to_pf then
            try
              foreach var old_fname in EnumerateAllFiles($'{pf_dir}\LibSource', $'{mn}.pas') do
                System.IO.File.Delete(old_fname);
              System.IO.Directory.CreateDirectory(Path.GetDirectoryName(pf_fname));
              System.IO.File.Copy( org_fname, pf_fname, true );
            except
              on System.UnauthorizedAccessException do
                Otp($'WARNING: Not enough rights to copy [{org_fname}] to [{pf_dir}\LibSource]');
            end;
          end;
          
          if copy_to_pf and (PackingStage.CurrentStages.Contains(CompileStr) or all_modules) then
            foreach var mn in mns do
            begin
              var mn_path := mn.EndsWith('ABCBase') ? $'Internal\{mn}' : mn;
              var org_fname := $'Modules.Packed\{mn_path}.pcu';
              var pf_fname := $'{pf_dir}\Lib\{mn_path}.pcu';
              
              if FileExists(org_fname) then
              try
                foreach var old_fname in EnumerateAllFiles($'{pf_dir}\Lib', $'{mn}.pcu') do
                  System.IO.File.Delete(old_fname);
                System.IO.Directory.CreateDirectory(Path.GetDirectoryName(pf_fname));
                System.IO.File.Copy( org_fname, pf_fname, true );
              except
                on System.UnauthorizedAccessException do
                  Otp($'WARNING: Not enough rights to copy [{org_fname}] to [{pf_dir}\Lib]');
              end else
                Otp($'WARNING: {org_fname} not found!');
              
            end;
          
          Otp($'Done copying release modules');
        end)
      ;
      
      {$endregion CopyModules}
      
      {$region CopySamples}
      
      var T_CopySamples :=
        TitleTask('Copying samples', '~') +
        ProcTask(()->
        begin
          var c := 0;
          var AllowedExtensions := HSet('.pas', '.cl', '.glsl');
          
          System.IO.Directory.EnumerateFiles('Samples', '*.*', System.IO.SearchOption.AllDirectories)
          .Where(fname->Path.GetExtension(fname) in AllowedExtensions)
          .Where(fname->not AllModules.Contains(Path.GetFileNameWithoutExtension(fname)))
          .ForEach(fname->
          begin
            Otp($'Packing sample "{fname}"');
            var res_fname := GetFullPath(GetRelativePath(fname, 'Samples'), 'Release\InstallerSamples\OpenGL и OpenCL');
            System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(res_fname));
            System.IO.File.Copy(fname, res_fname);
            c += 1;
          end);
          
          Otp($'Packed {c} sample files');
        end)
      ;
      
      {$endregion CopySamples}
      
      {$region CopySpec}
      
      var T_CopySpec :=
        TitleTask('Copying spec', '~') +
        ProcTask(()->
        begin
          var c := 0;
          
          foreach var fname in System.IO.Directory.EnumerateFiles('Packing\Spec', '*.html') do
          begin
            var spec := System.IO.Path.GetFileName(fname);
            Otp($'Packing spec [{spec}]');
            System.IO.Directory.CreateDirectory('Release\InstallerSamples\OpenGL и OpenCL');
            System.IO.File.Copy( fname, $'Release\InstallerSamples\OpenGL и OpenCL\{spec}' );
            c += 1;
          end;
          
          Otp($'Packed {c} spec files');
        end)
      ;
      
      {$endregion CopySpec}
      
      Result :=
        T_Clear
        +
        
        T_CopyModules *
        T_CopySamples *
        T_CopySpec
        
        +
        EmptyTask
      ;
    end;
    
  end;
  
  {$endregion Release}
  
{$endregion PackStage}

begin
  try
    
    {$region Load}
    
    Logger.main_log += new FileLogger('LastPack.log');
    Logger.main_log += new FileLogger('LastPack (Timed).log', true);
    
    // ====================================================
    
    begin
      var arg := CommandLineArgs.SingleOrDefault(arg->arg.StartsWith('Stages='));
      
      if arg=nil then
      begin
        PackingStage.CurrentStages := AllStages.ToHashSet;
        PackingStage.CurrentStages.ExceptWith(|FirstPackStr|);
        Otp($'Executing default stages:');
      end else
      begin
        PackingStage.CurrentStages := arg.Remove(0,'Stages='.Length).Split('+').Select(st->st.Trim).ToHashSet;
        PackingStage.CurrentStages.RemoveWhere(stage->
        begin
          if stage in AllStages then exit;
          Otp($'WARNING: Invalid pack stage [{stage}]');
          Result := true;
        end);
        Otp($'Executing selected stages:');
      end;
//      stages := HSet(OpenGLABCStr);
      
      Otp(PackingStage.CurrentStages.JoinIntoString(' + '));
    end;
    
    {$endregion Load}
    
    {$region MiscClear}
    
    var c := 0;
    var skip_pcu := AllModules.Except(PackingStage.CurrentStages).IncludeBaseModules.ToHashSet;
    
    foreach var fname in Arr('*.pcu','*.pdb').SelectMany(p->Directory.EnumerateFiles(GetCurrentDir, p, SearchOption.AllDirectories)) do
    begin
      if skip_pcu.Contains(Path.GetFileNameWithoutExtension(fname)) then continue;
      try
        System.IO.File.Delete(fname);
      except
        Otp($'WARNING: Failed to clear file {GetRelativePath(fname)}');
      end;
      c += 1;
    end;
    
    {$endregion MiscClear}
    
    var T_FirstPack := FirstPackStage.Create.MakeTask;
    var T_Spec      := SpecStage.Create.MakeTask;
    var T_OpenCL    := LLModuleStage.Create(OpenCLStr).MakeTask;
    var T_OpenCLABC := HLModuleStage.Create(OpenCLABCStr).MakeTask;
    var T_OpenGL    := LLModuleStage.Create(OpenGLStr).MakeTask;
    var T_OpenGLABC := HLModuleStage.Create(OpenGLABCStr).MakeTask;
    var T_Compile   := CompileStage.Create.MakeTask;
    var T_Test      := TestStage.Create.MakeTask;
    var T_Release   := ReleaseStage.Create.MakeTask;
    
    Otp('Start packing');
    
    (
      T_FirstPack +
      
      T_Spec *
      T_OpenCL * T_OpenCLABC *
      T_OpenGL * T_OpenGLABC *
      T_Compile
      
      + T_Test
      + T_Release
    ).SyncExec;
    
    Otp('Done packing');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.