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

var stages: HashSet<string>;

function FirstPack  := stages.Contains(FirstPackStr );
function Spec       := stages.Contains(SpecStr      );
function OpenCL     := stages.Contains(OpenCLStr    );
function OpenCLABC  := stages.Contains(OpenCLABCStr );
function OpenGL     := stages.Contains(OpenGLStr    );
function OpenGLABC  := stages.Contains(OpenGLABCStr );
function Compile    := stages.Contains(CompileStr   );
function Test       := stages.Contains(TestStr      );
function Release    := stages.Contains(ReleaseStr   );

var module_packed_evs: Dictionary<string, ManualResetEvent>;

{$endregion SpecialNames}

{$region Shortcuts}

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
  var full_title := sb.ToString;
  
  Result := ProcTask(()->Otp(full_title));
end;

function LLModuleTask(mn: string) := not stages.Contains(mn) ? EmptyTask :
  TitleTask(mn) +
  ExecTask('Packing\Template\Pack Template.pas', $'Template[{mn}]', $'nick={mn}', $'"inp_fname=Modules\Template\{mn}.pas"', $'"otp_fname=Modules\{mn}.pas"') +
  ProcTask(()->Directory.CreateDirectory('Modules.Packed')) +
  ProcTask(()->System.IO.File.Copy($'Modules\{mn}.pas', $'Modules.Packed\{mn}.pas', true)) +
  SetEvTask(module_packed_evs[mn])
;

function HLModuleTask(mn: string) := not stages.Contains(mn) ? EmptyTask :
  TitleTask(mn) +
  ProcTask(()->Directory.CreateDirectory('Modules.Packed\Internal')) +
  
  ExecTask('Packing\Template\Pack Template.pas', $'Template[{mn}]',     $'nick={mn}', $'"inp_fname=Modules\{mn}.pas"',              $'"otp_fname=Modules.Packed\{mn}.pas"') *
  ExecTask('Packing\Template\Pack Template.pas', $'Template[{mn}Base]', $'nick={mn}', $'"inp_fname=Modules\Internal\{mn}Base.pas"', $'"otp_fname=Modules.Packed\Internal\{mn}Base.pas"')
  
  + ExecTask('Packing\Doc\PackComments.pas', $'Comments[{mn}]', $'nick={mn}', $'"fname=Modules.Packed\{mn}.pas"', $'"fname=Modules.Packed\Internal\{mn}Base.pas"')
  + SetEvTask(module_packed_evs[mn])
;

{$endregion Shortcuts}

begin
  try
    
//    stages := AllStages;
//    module_packed_evs := AllModules.Intersect(stages).ToDictionary(mn->mn,mn->new ManualResetEvent(false));
//    CompTask('Packing\Template\Pack Template.pas').SyncExec;
//    exit;
    
    {$region Load}
    
    Logger.main_log += new FileLogger('LastPack.log');
    Logger.main_log += new FileLogger('LastPack (Timed).log', true);
    
    // ====================================================
    
    begin
      var arg := CommandLineArgs.SingleOrDefault(arg->arg.StartsWith('Stages='));
      
      if arg=nil then
      begin
        stages := AllStages.ToHashSet;
        stages.Remove(FirstPackStr);
        Logger.main_log += new FileLogger('LastPack (Default).log');
        Otp($'Executing default stages:');
      end else
      begin
        stages := arg.Remove(0,'Stages='.Length).Split('+').Select(st->st.Trim).ToHashSet;
        stages.RemoveWhere(stage->
        begin
          if stage in AllStages then exit;
          Otp($'WARNING: Invalid pack stage [{stage}]');
          Result := true;
        end);
        Otp($'Executing selected stages:');
      end;
//      stages := HSet(OpenGLABCStr);
      
      Otp(stages.JoinIntoString(' + '));
    end;
    
    module_packed_evs := AllModules.Intersect(stages).ToDictionary(mn->mn,mn->new ManualResetEvent(false));
    
    {$endregion Load}
    
    {$region MiscClear}
    
    var T_MiscClear :=
      ProcTask(()->
      begin
        var c := 0;
        var skip_pcu := AllModules.Except(stages).SelectMany(mn->
          mn.EndsWith('ABC') ? Seq(
            mn+'Base.pcu',
            mn+'.pcu'
          ) : Seq(
            mn+'.pcu'
          )
        ).ToHashSet;
        
        foreach var fname in Arr('*.pcu','*.pdb').SelectMany(p->Directory.EnumerateFiles(GetCurrentDir, p, SearchOption.AllDirectories)) do
        begin
          if skip_pcu.Contains(Path.GetFileName(fname)) then continue;
          try
            System.IO.File.Delete(fname);
          except
            Otp($'WARNING: Failed to clear file {GetRelativePath(fname)}');
          end;
          c += 1;
        end;
        
//        if c<>0 then Otp($'Cleared {c} files');
      end)
    ;
    
    {$endregion MiscClear}
    
    {$region FirstPack}
    var T_FirstPack: SecThrProc;
    if not FirstPack then
      T_FirstPack := EmptyTask else
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
      
      T_FirstPack :=
        TitleTask('First Pack') +
        T_UpdateReps
        +
        
        T_ScrapXML
        
        +
        EmptyTask
      ;
    end;
    {$endregion FirstPack}
    
    {$region Spec}
    
    var T_Spec := not Spec ? EmptyTask :
      TitleTask('Specs') +
      ExecTask('Packing\Spec\SpecPacker.pas', 'SpecPacker')
    ;
    
    {$endregion Spec}
    
    {$region Compile}
    
    var T_Compile := not Compile ? EmptyTask :
      TitleTask('Compiling') +
      AllLLModules.Select(mn->
      begin
        Result := EmptyTask;
        if stages.Contains(mn      ) then Result += EventTask(module_packed_evs[mn      ]);
        if stages.Contains(mn+'ABC') then Result += EventTask(module_packed_evs[mn+'ABC']);
        
        if stages.Contains(mn+'ABC') then
        begin
          if not stages.Contains(mn) then System.IO.File.Copy($'Modules\{mn}.pas', $'Modules.Packed\{mn}.pas', true);
          Result += CompTask($'Modules.Packed\{mn}ABC.pas');
        end else
        if stages.Contains(mn) then
          Result += CompTask($'Modules.Packed\{mn}.pas');
        
      end).CombineAsyncTask
    ;
    
    {$endregion Compile}
    
    {$region Test}
    
    var T_Test := not Test ? EmptyTask :
      TitleTask('Testing') +
      ExecTask('Tests\Tester.pas', 'Tester', $'Modules={AllModules.Intersect(stages).JoinToString(''+'')}')
    ;
    
    {$endregion Test}
    
    {$region Release}
    var T_Release: SecThrProc;
    if not Release then
      T_Release := EmptyTask else
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
        ProcTask(()->
        begin
          var mns := AllModules.Intersect(stages).ToHashSet;
          var all_modules := mns.Count=0;
          if all_modules then mns := AllModules.ToHashSet;
          
          var pf_dir := 'C:\Program Files (x86)\PascalABC.NET';
          var copy_to_pf := Directory.Exists(pf_dir);
          if not copy_to_pf then Otp($'WARNING: Dir [{pf_dir}] not found, skiping pf release copy');
          
          foreach var mn in AllLLModules do
            if mns.Contains(mn+'ABC') then
              mns += $'Internal\{mn}ABCBase';
          
          foreach var mn in mns do
          begin
            var org_fname :=      $'Modules.Packed\{mn}.pas';
            var release_fname :=  $'Release\bin\Lib\{mn}.pas';
            var pf_fname :=       $'{pf_dir}\LibSource\{mn}.pas';
            Otp($'Packing {org_fname}');
            
            System.IO.Directory.CreateDirectory(Path.GetDirectoryName(release_fname));
            System.IO.File.Copy( org_fname, release_fname );
            if copy_to_pf then
            try
              System.IO.Directory.CreateDirectory(Path.GetDirectoryName(pf_fname));
              System.IO.File.Copy( org_fname, pf_fname, true );
            except
              on System.UnauthorizedAccessException do
                Otp($'WARNING: Not enough rights to copy [{org_fname}] to [{pf_dir}\LibSource]');
            end;
          end;
          
          if copy_to_pf and (Compile or all_modules) then
            foreach var mn in mns do
            begin
              var org_fname := $'Modules.Packed\{mn}.pcu';
              var pf_fname := $'{pf_dir}\Lib\{mn}.pcu';
              
              if FileExists(org_fname) then
              try
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
          
          Otp($'Packed {c} samples');
        end)
      ;
      
      {$endregion CopySamples}
      
      {$region CopySpec}
      
      var T_CopySpec :=
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
      
      T_Release :=
        TitleTask('Release') +
        T_Clear
        +
        
        T_CopyModules *
        T_CopySamples *
        T_CopySpec
        
        +
        EmptyTask
      ;
    end;
    {$endregion Release}
    
    Otp('Start packing');
    
    (
      T_MiscClear +
      T_FirstPack +
      
      T_Spec *
      LLModuleTask(OpenCLStr) * HLModuleTask(OpenCLABCStr) *
      LLModuleTask(OpenGLStr) * HLModuleTask(OpenGLABCStr) *
      T_Compile
      
      + T_Test
      + T_Release
    ).SyncExec;
    
    Otp('Done packing');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.