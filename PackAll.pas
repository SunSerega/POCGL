
// АРГУМЕНТЫ КОМАНДНОЙ СТРОКИ:
// 
// - "PasCompPath=path\PABCNETC\pabcnetcclear.exe"
// === Использует указанный компилятор для .pas файлов
// === Если не указать - используется "C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe"
// === Можно указать несколько, будет использован первый существующий .exe файл компилятора
// 
// - "Stages=...+...+..."
// === Запускает только указанные стадии упаковки
//   - "FirstPack"  | Датаскрапинг данных об исходных библиотеках. Единственная по-умолчанию выключенная стадия
//   - "Reference"  | Упаковка справок
//   - "Dummy"      | Упаковка модуля Dummy.pas (тест кодогенерации)
//   - "OpenCL"     | Упаковка модуля OpenCL.pas
//   - "OpenCLABC"  | Упаковка модуля OpenCLABC.pas
//   - "OpenGL"     | Упаковка модуля OpenGL.pas
//   - "OpenGLABC"  | Упаковка модуля OpenGLABC.pas
//   - "Compile"    | Компиляция всех упакованных модулей
//   - "Test"       | Тестирование (то же что запуск "Tests\Tester.exe" напрямую, но с указанными модулями)
//   - "Release"    | Создание и наполнение папки Release, а так же копирование чего надо в ProgramFiles
// === К примеру: "Stages= OpenCLABC + Compile + Test + Release"
// === Лишние пробелы по краям имён стадий допускаются, но "Stages=" должно быть слитно
// 

uses System.Threading;
uses System.Threading.Tasks;
uses System.IO;

uses 'Utils/AOtp';
uses 'Utils/Timers';
uses 'Utils/ATask';
uses 'Utils/PathUtils';

{$region SpecialNames}

const FirstPackStr  = 'FirstPack';
const ReferenceStr  = 'Reference';
const DummyStr      = 'Dummy';
const OpenCLStr     = 'OpenCL';
const OpenCLABCStr  = 'OpenCLABC';
const OpenGLStr     = 'OpenGL';
const OpenGLABCStr  = 'OpenGLABC';
const CompileStr    = 'Compile';
const TestStr       = 'Test';
const ReleaseStr    = 'Release';

var AllLLModules := HSet(
  DummyStr,OpenCLStr,OpenGLStr
);
var AllModules := HSet(
  DummyStr,
  OpenCLStr,OpenCLABCStr,
  OpenGLStr,OpenGLABCStr
);
var AllStages := HSet(
  FirstPackStr,
  ReferenceStr,
  DummyStr,
  OpenCLStr,OpenCLABCStr,
  OpenGLStr,OpenGLABCStr,
  CompileStr,
  TestStr,
  ReleaseStr
);

{$endregion SpecialNames}

{$region PackStage} type
  
  {$region Base}
  
  PackingStage = abstract class
    protected id, description, log_name: string;
    private log: FileLogger;
    
    protected const lk_console_only           = 'console only';
    protected const lk_pack_stage_unspecific  = 'pack stage unspecific';
    static constructor;
    begin
      FileLogger.RegisterGenerallyBadKind(lk_console_only);
      FileLogger.RegisterGenerallyBadKind(lk_pack_stage_unspecific);
    end;
    
    public static CurrentStages: HashSet<string>;
    public static function ModuleStages := AllModules.Intersect(CurrentStages);
    public static function IsPackingAllModules := ModuleStages.Count in |0,AllModules.Count|;
    
    public static function TitleTask(title: string; decor: char := '='): AsyncTask;
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
    
    protected constructor(name: string);
    begin
      self.id := name;
      self.description := name;
      self.log_name := name;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public function MakeTask: AsyncTask;
    begin
      if (id<>nil) and (id not in CurrentStages) then exit;
      Result := MakeCoreTask;
      if Result=nil then exit;
      
      if self.log_name<>nil then
      begin
        self.log := new FileLogger($'Log/{log_name}.log', false, OtpKind.Empty, new OtpKind(lk_console_only, lk_pack_stage_unspecific, AsyncTaskProcessExec.lk_exec_task_pre_compile));
        Result := new AsyncTaskOtpHandler(Result, self.log.Otp) + ProcTask(self.log.Close);
      end;
      
      if self.description<>nil then
        Result := TitleTask(self.description) + Result;
      
    end;
    protected function MakeCoreTask: AsyncTask; abstract;
    
  end;
  
  {$endregion Base}
  
  {$region FirstPack}
  
  FirstPackStage = sealed class(PackingStage)
    
    public constructor;
    begin
      inherited Create(FirstPackStr);
      self.description := 'First Pack';
    end;
    
    protected function MakeCoreTask: AsyncTask; override;
    begin
      
      {$region UpdateReps}
      
      var T_UpdateReps :=
        TitleTask('Update Reps', '~')
        +
        
        ExecTask('DataScraping/Reps/PullReps.pas', 'SubReps Update')
        
      ;
      
      {$endregion UpdateReps}
      
      {$region Scrap XML}
      
      var T_ScrapXML :=
        TitleTask('Scrap XML', '~') +
        
        |'Dummy','OpenCL','OpenGL'|
        .Select(id->ExecTask($'DataScraping/XML/{id}/ScrapXML.pas', $'ScrapXML[{id}]'))
        .CombineAsyncTask
        
      ;
      
      {$endregion Scrap XML}
      
      Result :=
        T_UpdateReps +
        T_ScrapXML
      ;
    end;
    
  end;
  
  {$endregion FirstPack}
  
  {$region Reference}
  
  ReferenceStage = sealed class(PackingStage)
    
    public constructor;
    begin
      inherited Create(ReferenceStr);
      self.description := 'References';
    end;
    
    protected function MakeCoreTask: AsyncTask; override :=
      ExecTask('Packing/Reference/ReferencePacker.pas', 'ReferencePacker');
    
  end;
  
  {$endregion Reference}
  
  {$region Modules}
  
  ModulePackingStage = abstract class(PackingStage)
    
    private static module_pack_evs := new Dictionary<string, ManualResetEvent>;
    public static function GetModulePackEv(module_name: string): ManualResetEvent;
    begin
      lock module_pack_evs do
        if not module_pack_evs.TryGetValue(module_name, Result) then
        begin
          Result := new ManualResetEvent(false);
          module_pack_evs[module_name] := Result;
        end;
    end;
    
    public constructor(module_name: string) :=
      inherited Create(module_name);
    
    protected function ModuleLvl: string; abstract;
    protected function MakeCoreTask: AsyncTask; override :=
      ProcTask(()->Directory.CreateDirectory('Modules.Packed'))
    +
      ExecTask('Packing/Template/Pack Template.pas', $'Template[{id}]', $'nick={id}', $'dir={ModuleLvl}', $'"inp_fname=Modules/{id}.pas"', $'"otp_fname=Modules.Packed/{id}.pas"')
    +
      ExecTask('Packing/Descriptions/PackDescriptions.pas', $'Descriptions[{id}]', $'nick={id}', $'"fname=Modules.Packed/{id}.pas"')
    +
      SetEvTask(GetModulePackEv(self.id));
    
  end;
  LLModuleStage = sealed class(ModulePackingStage)
    
    protected function ModuleLvl: string; override := 'LowLvl';
    
  end;
  HLModuleStage = sealed class(ModulePackingStage)
    
    protected function ModuleLvl: string; override := 'HighLvl';
    
  end;
  
  {$endregion Modules}
  
  {$region Compile}
  
  CompileStage = sealed class(PackingStage)
    
    public constructor;
    begin
      inherited Create(CompileStr);
      self.description := 'Compiling';
      if not IsPackingAllModules then log_name := nil;
    end;
    
    private function MakeModuleCompileTask(mn: string): AsyncTask;
    begin
      if mn       in CurrentStages then Result += EventTask(ModulePackingStage.GetModulePackEv(mn));
      if mn+'ABC' in CurrentStages then Result += EventTask(ModulePackingStage.GetModulePackEv(mn+'ABC'));
      
      if mn+'ABC' in CurrentStages then
        Result += CompTask($'Modules.Packed/{mn}ABC.pas') else
      if mn in CurrentStages then
        Result += CompTask($'Modules.Packed/{mn}.pas');
      
    end;
    
    protected function MakeCoreTask: AsyncTask; override :=
      AllLLModules.Select(MakeModuleCompileTask).CombineAsyncTask;
    
  end;
  
  {$endregion Compile}
  
  {$region Test}
  
  TestStage = sealed class(PackingStage)
    private module_stages_str := ModuleStages.JoinToString(' + ');
    
    public constructor;
    begin
      inherited Create(TestStr);
      self.description := 'Testing';
      if not IsPackingAllModules then log_name := nil;
    end;
    
    protected function MakeCoreTask: AsyncTask; override :=
      CompTask('Utils/Testing/TestExecutor.pas') +
      CompTask('Tests/Tester.pas') +
      ExecTask('Tests/Tester.exe', 'Tester', $'"Modules={module_stages_str}"', 'AutoUpdate=true');
    
  end;
  
  {$endregion Test}
  
  {$region Release}
  
  ReleaseStage = sealed class(PackingStage)
    
    public constructor;
    begin
      inherited Create(ReleaseStr);
      if not IsPackingAllModules then log_name := nil;
    end;
    
    protected function MakeCoreTask: AsyncTask; override;
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
          var mns := ModuleStages.ToHashSet;
          var all_modules := mns.Count=0;
          if all_modules then mns := AllModules.ToHashSet;
          foreach var mn in AllLLModules do
            if mn+'ABC' in mns then
              mns += mn;
          mns.Remove(DummyStr);
          
          var pf_dir := 'C:/Program Files (x86)/PascalABC.NET';
          var copy_to_pf := Directory.Exists(pf_dir);
          if not copy_to_pf then
            Otp($'WARNING: Dir [{pf_dir}] not found, skiping pf release copy', |lk_console_only|);
          
          foreach var mn in mns do
          begin
            var org_fname :=      $'Modules.Packed/{mn}.pas';
            var release_fname :=  $'Release/bin/Lib/{mn}.pas';
            var pf_fname :=       $'{pf_dir}/LibSource/{mn}.pas';
            Otp($'Packing {org_fname}');
            
            System.IO.Directory.CreateDirectory(Path.GetDirectoryName(release_fname));
            System.IO.File.Copy( org_fname, release_fname );
            if copy_to_pf then
            try
              foreach var old_fname in EnumerateAllFiles($'{pf_dir}/LibSource', $'{mn}.pas') do
                System.IO.File.Delete(old_fname);
              System.IO.Directory.CreateDirectory(Path.GetDirectoryName(pf_fname));
              System.IO.File.Copy( org_fname, pf_fname, true );
            except
              on System.UnauthorizedAccessException do
                Otp($'WARNING: Not enough rights to copy [{org_fname}] to [{pf_dir}/LibSource]', |lk_console_only|);
            end;
          end;
          
          if copy_to_pf and ((CompileStr in PackingStage.CurrentStages) or all_modules) then
            foreach var mn in mns do
            begin
              var org_fname := $'Modules.Packed/{mn}.pcu';
              var pf_fname := $'{pf_dir}/Lib/{mn}.pcu';
              
              if FileExists(org_fname) then
              try
                foreach var old_fname in EnumerateAllFiles($'{pf_dir}/Lib', $'{mn}.pcu') do
                  System.IO.File.Delete(old_fname);
                System.IO.Directory.CreateDirectory(Path.GetDirectoryName(pf_fname));
                System.IO.File.Copy( org_fname, pf_fname, true );
              except
                on System.UnauthorizedAccessException do
                  Otp($'WARNING: Not enough rights to copy [{org_fname}] to [{pf_dir}/Lib]', |lk_console_only|);
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
          var AllowedExtensions := HSet(
            '.cl',
            '.glsl', '.vert','.geom','.frag',
            '.pas',
            '.bmp'
          );
          var DisallowedExtensions := HSet(
            '.gitignore', '.td',
            '.cache', '.dat',
            '.exe', '.pdb', '.pcu'
          );
          
          System.IO.Directory.EnumerateFiles('Samples', '*.*', System.IO.SearchOption.AllDirectories)
          .Select(fname->fname.Replace('\','/'))
          .Where(fname->Path.GetFileNameWithoutExtension(fname) not in AllModules)
          .ForEach(fname->
          begin
            var ext := Path.GetExtension(fname);
            if ext in DisallowedExtensions then exit;
            if ext not in AllowedExtensions then
              Otp('WARNING: Sample file with unknown extension:');
            Otp($'Packing sample file "{fname}"');
            var res_fname := GetFullPath(GetRelativePath(fname, 'Samples'), 'Release/InstallerSamples/StandardUnits/OpenGL и OpenCL');
            System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(res_fname));
            System.IO.File.Copy(fname, res_fname);
            c += 1;
          end);
          
          Otp($'Packed {c} sample files');
        end)
      ;
      
      {$endregion CopySamples}
      
      Result :=
        T_Clear
        +
        
        T_CopyModules *
        T_CopySamples
        
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
    
    FileLogger.RegisterGenerallyBadKind(PackingStage.lk_console_only);
    FileLogger.RegisterGenerallyExpKind(PackingStage.lk_pack_stage_unspecific);
    FileLogger.RegisterGenerallyExpKind(AsyncTaskProcessExec.lk_exec_task_pre_compile);
    
    Logger.AttachToMain(
      new FileLogger('LastPack.log') +
      new FileLogger('LastPack (Timed).log', true)
    );
    
    // ====================================================
    
    begin
      var arg := CommandLineArgs.SingleOrDefault(arg->arg.StartsWith('Stages='));
      
      if arg<>nil then
      begin
        PackingStage.CurrentStages := arg.Remove(0,'Stages='.Length).Split('+').Select(st->st.Trim).ToHashSet;
        PackingStage.CurrentStages.RemoveWhere(stage->
        begin
          if stage in AllStages then exit;
          Otp($'WARNING: Invalid pack stage [{stage}]');
          Result := true;
        end);
        Otp($'Executing selected stages:');
      end else
      if not |'[REDIRECTIOMODE]','[RUNMODE]'|.Any(m->m in System.Environment.GetCommandLineArgs) then
      begin
        PackingStage.CurrentStages := AllStages.ToHashSet;
        PackingStage.CurrentStages.ExceptWith(|FirstPackStr|);
        Otp($'Executing default stages:');
      end else
      begin
        PackingStage.CurrentStages := AllStages.ToHashSet;
//        PackingStage.CurrentStages := HSet(FirstPackStr);
//        PackingStage.CurrentStages := HSet(DummyStr, OpenCLStr, OpenGLStr, CompileStr);
//        PackingStage.CurrentStages := HSet(OpenCLABCStr, OpenGLABCStr, CompileStr);
//        PackingStage.CurrentStages := HSet(DummyStr, OpenCLStr,OpenCLABCStr, OpenGLStr,OpenGLABCStr, CompileStr);
        Otp($'Executing debug stages:');
      end;
      
      Otp(PackingStage.CurrentStages.JoinIntoString(' + '));
    end;
    
    {$endregion Load}
    
    {$region MiscClear}
    
    var c := 0;
    var skip_pcu := AllModules.Except(PackingStage.CurrentStages).ToHashSet;
    
    foreach var fname in |{'*.pcu',}'*.pdb'|.SelectMany(p->Directory.EnumerateFiles(GetCurrentDir, p, SearchOption.AllDirectories)) do
    begin
      if Path.GetFileNameWithoutExtension(fname) in skip_pcu then continue;
      try
        System.IO.File.Delete(fname);
      except
        Otp($'WARNING: Failed to clear file {GetRelativePath(fname)}');
      end;
      c += 1;
    end;
    
    {$endregion MiscClear}
    
    var T_FirstPack := FirstPackStage .Create               .MakeTask;
    var T_Reference := ReferenceStage .Create               .MakeTask;
    var T_Dummy     := LLModuleStage  .Create(DummyStr)     .MakeTask;
    var T_OpenCL    := LLModuleStage  .Create(OpenCLStr)    .MakeTask;
    var T_OpenCLABC := HLModuleStage  .Create(OpenCLABCStr) .MakeTask;
    var T_OpenGL    := LLModuleStage  .Create(OpenGLStr)    .MakeTask;
    var T_OpenGLABC := HLModuleStage  .Create(OpenGLABCStr) .MakeTask;
    var T_Compile   := CompileStage   .Create               .MakeTask;
    var T_Test      := TestStage      .Create               .MakeTask;
    var T_Release   := ReleaseStage   .Create               .MakeTask;
    
    Otp('Start packing');
    
    (
      T_FirstPack +
      
      T_Reference *
      ( T_Dummy ) *
      ( T_OpenCL + T_OpenCLABC ) *
      ( T_OpenGL + T_OpenGLABC )
      
      + T_Compile * T_Test
      + T_Release
    ).SyncExec;
    
    Otp('Done packing');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.