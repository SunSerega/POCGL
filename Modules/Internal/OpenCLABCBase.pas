
{%..\LicenseHeader%}

/// Модуль для внутренних типов модуля OpenCLABC
unit OpenCLABCBase;

{$region ToDo}

//===================================
// Обязательно сделать до следующего пула:

{$region Справка}

//ToDo Враперы
//ToDo KernelArg в справку

//ToDo Подробнее написать в справке про "BCQ.Add*":
// - WriteArray2 НЕ_интуитивно обрабатывает offset'ы
// - ReadValue отсутствует
// - FillArray отсутствует

//ToDo Wait очереди:
// - Пока сделал так: если ожидающая очередь абортится - она перестаёт ожидать.
// - Это может создать неопределённое поведение. Но, по моему, это правильней всего.
// - Если так и останется - не забыть добавить в справку

//ToDo Написать в справке что опасно передавать @i вместо KernelArg, где i - захваченная переменная

//ToDo Написать в справке, что любые лямбды пользователя, переданные в этот модуль, могут получить ThreadAbortException
// - Но это только если возникнет ошибка во время выполнения другой части очереди

{$endregion Справка}

//ToDo Тесты всех фич модуля
//ToDo И в каждом сделать по несколько выполнений, на случай плавающий ошибок

//ToDo Исправить интерфейс CommandQueueBase

//===================================
// Запланированное:

//ToDo В тестеровщике, в тестах ошибок, в текстах ошибок - постоянно меняются номера лямбд...
// - Наверное стоит захардкодить в тестировщик игнор числа после "<>lambda", и так же для контейнера лямбды

//ToDo Заполнение Platform.All сейчас вылетит на компе с 0 платформ...
// - Сразу не забыть исправить описание

//ToDo IWaitQueue.CancelWait
//ToDo WaitAny(aborter, WaitAll(...));
// - Что случится с WaitAll если aborter будет первым?
// - Очереди переданные в Wait - вообще не запускаются так
// - Поэтому я и думал про что то типа CancelWait
// - А вообще лучше разрешить выполнять Wait внутри другого Wait
// - И заодно проверить чтобы Abort работало на Wait-ы

//ToDo Проверки и кидания исключений перед всеми cl.*, чтобы выводить норм сообщения об ошибках
// - В том числе проверки с помощью BlittableHelper

//ToDo Создание SubDevice из cl_device_id

//ToDo Очереди-маркеры для Wait-очередей
// - чтобы не приходилось использовать константные для этого

//ToDo Очередь-обработчик ошибок
// - .HandleExceptions и какой то аналог try-finally
// - .ThenFinally ?
// - Сделать легко, надо только вставить свой промежуточный CLTaskBase
// - Единственное - для Wait очереди надо хранить так же оригинальный CLTaskBase
//ToDo Раздел справки про обработку ошибок
// - Написать что аналог try-finally стоит использовать на Wait-маркерах для потоко-безопастности

//ToDo Когда будут очереди-обработчики - удалить ивенты CLTask-ов. Они, по сути, ограниченная версия.
// - И использование их тут изнутри - в целом говнокод...

//ToDo Всё же стоит добавить .ThenUse - аналог .ThenConvert, не изменяющий значение, а только использующий

//ToDo Синхронные (с припиской Fast, а может Quick) варианты всего работающего по принципу HostQueue
//
//ToDo И асинхронные умнее запускать - помнить значение, указывающее можно ли выполнить их синхронно
// - Может даже можно синхронно выполнить "HPQ(...)+HPQ(...)", в некоторых случаях?
//ToDo Enqueueabl-ы вызывают .Invoke для первого параметра и .InvokeNewQ для остальных
// - А что если все параметры кроме последнего - константы?
// - Надо как то умнее это обрабатывать
//ToDo И сделать наконец нормальный класс-контейнер состояния очереди, параметрами всё не передашь

//ToDo Исправить десериализацию ProgramCode
// - Пока что закомментировал и поставил raise

//ToDo CommmandQueueBase.ToString для дебага
// - так же дублирующий protected метод (tabs: integer; index: Dictionary<CommandQueueBase,integer>)

//ToDo ICommandQueue.Cycle(integer)
//ToDo ICommandQueue.Cycle // бесконечность циклов
//ToDo ICommandQueue.CycleWhile(***->boolean)
// - Возможность передать свой обработчик ошибок как Exception->Exception
//ToDo В продолжение Cycle: Однако всё ещё остаётся проблема - как сделать ветвление?
// - И если уже делать - стоит сделать и метод CQ.ThenIf(res->boolean; if_true, if_false: CQ)
//ToDo И ещё - AbortQueue, который, по сути, может использоваться как exit, continue или break, если с обработчиками ошибок

//ToDo Интегрировать профайлинг очередей

//ToDo Перепродумать SubBuffer, в случае перевыделения основного буфера - он плохо себя ведёт...

//===================================
// Сделать когда-нибуть:

//ToDo Пройтись по всем функциям OpenCL, посмотреть функционал каких не доступен из OpenCLABC
// - clGetKernelWorkGroupInfo - свойства кернела на определённом устройстве

{$endregion ToDo}

{$region Bugs}

//ToDo Issue компилятора:
//ToDo https://github.com/pascalabcnet/pascalabcnet/issues/{id}
// - ?

//ToDo Баги NVidia
//ToDo https://developer.nvidia.com/nvidia_bug/{id}
// - NV#3035203

{$endregion}

interface

uses System;
uses System.Threading;
uses System.Runtime.InteropServices;
uses System.Collections.ObjectModel;

uses OpenCL in '..\OpenCL';

type
  
  {$region Properties}
  
  {$region Base}
  
  NtvPropertiesBase<TNtv, TInfo> = abstract class
    protected ntv: TNtv;
    public constructor(ntv: TNtv) := self.ntv := ntv;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure GetSizeImpl(id: TInfo; var sz: UIntPtr); abstract;
    protected procedure GetValImpl(id: TInfo; sz: UIntPtr; var res: byte); abstract;
    
    protected function GetSize(id: TInfo): UIntPtr;
    begin GetSizeImpl(id, Result); end;
    
    protected procedure FillPtr(id: TInfo; sz: UIntPtr; ptr: IntPtr) :=
    GetValImpl(id, sz, PByte(pointer(ptr))^);
    protected procedure FillVal<T>(id: TInfo; sz: UIntPtr; var res: T) :=
    GetValImpl(id, sz, PByte(pointer(@res))^);
    
    protected function GetVal<T>(id: TInfo): T;
    begin FillVal(id, new UIntPtr(Marshal.SizeOf&<T>), Result); end;
    protected function GetValArr<T>(id: TInfo): array of T;
    begin
      var sz := GetSize(id);
      Result := new T[uint64(sz) div Marshal.SizeOf&<T>];
      
      if Result.Length<>0 then
        FillVal(id, sz, Result[0]);
      
    end;
    protected function GetValArrArr<T>(id: TInfo; szs: array of UIntPtr): array of array of T;
    type PT = ^T;
    begin
      if szs.Length=0 then
      begin
        SetLength(Result,0);
        exit;
      end;
      
      var res := new IntPtr[szs.Length];
      SetLength(Result, szs.Length);
      
      for var i := 0 to szs.Length-1 do res[i] := Marshal.AllocHGlobal(IntPtr(pointer(szs[i])));
      try
        
        FillVal(id, new UIntPtr(szs.Length*Marshal.SizeOf&<IntPtr>), res[0]);
        
        var tsz := Marshal.SizeOf&<T>;
        for var i := 0 to szs.Length-1 do
        begin
          Result[i] := new T[uint64(szs[i]) div tsz];
          //ToDo более эффективное копирование
          for var i2 := 0 to Result[i].Length-1 do
            Result[i][i2] := PT(pointer(res[i]+tsz*i2))^;
        end;
        
      finally
        for var i := 0 to szs.Length-1 do Marshal.FreeHGlobal(res[i]);
      end;
      
    end;
    
    {$region GetInt}
    
    private function GetIntPtr(id: TInfo) := GetVal&<IntPtr>(id);
    
    private function GetUInt32(id: TInfo) := GetVal&<UInt32>(id);
    private function GetUInt64(id: TInfo) := GetVal&<UInt64>(id);
    private function GetUIntPtr(id: TInfo) := GetVal&<UIntPtr>(id);
    
    {$endregion GetInt}
    
    {$region GetIntArr}
    
    private function GetByteArr(id: TInfo) := GetValArr&<Byte>(id);
    private function GetUIntPtrArr(id: TInfo) := GetValArr&<UIntPtr>(id);
    
    private function GetByteArrArr(id: TInfo; szs: array of UIntPtr) := GetValArrArr&<Byte>(id, szs);
    
    {$endregion GetIntArr}
    
    {$region GetString}
    
    private function GetString(id: TInfo): string;
    begin
      var sz := GetSize(id);
      
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        FillPtr(id, sz, str_ptr);
        Result := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
    end;
    
    {$endregion GetString}
    
    {$region GetBoolean}
    
    private function GetBoolean(id: TInfo) := GetVal&<Bool>(id).val <> 0;
    
    {$endregion GetBoolean}
    
  end;
  
  {$endregion Base}
  
  {$region Platform}
  
  PlatformProperties = sealed class(NtvPropertiesBase<cl_platform_id, PlatformInfo>)
    
    private static function clGetSize(platform: cl_platform_id; param_name: PlatformInfo; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetPlatformInfo';
    private static function clGetVal(platform: cl_platform_id; param_name: PlatformInfo; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetPlatformInfo';
    
    protected procedure GetSizeImpl(id: PlatformInfo; var sz: UIntPtr); override :=
    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;
    protected procedure GetValImpl(id: PlatformInfo; sz: UIntPtr; var res: byte); override :=
    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;
    
    {%Platform.Properties!PropGen.pas%}
    
  end;
  
  {$endregion Platform}
  
  {$region Device}
  
  DeviceProperties = sealed class(NtvPropertiesBase<cl_device_id, DeviceInfo>)
    
    private static function clGetSize(device: cl_device_id; param_name: DeviceInfo; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetDeviceInfo';
    private static function clGetVal(device: cl_device_id; param_name: DeviceInfo; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetDeviceInfo';
    
    protected procedure GetSizeImpl(id: DeviceInfo; var sz: UIntPtr); override :=
    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;
    protected procedure GetValImpl(id: DeviceInfo; sz: UIntPtr; var res: byte); override :=
    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;
    
    private function GetDeviceType(id: DeviceInfo)                  := GetVal&<DeviceType>(id);
    private function GetDeviceFPConfig(id: DeviceInfo)              := GetVal&<DeviceFPConfig>(id);
    private function GetDeviceMemCacheType(id: DeviceInfo)          := GetVal&<DeviceMemCacheType>(id);
    private function GetDeviceLocalMemType(id: DeviceInfo)          := GetVal&<DeviceLocalMemType>(id);
    private function GetDeviceExecCapabilities(id: DeviceInfo)      := GetVal&<DeviceExecCapabilities>(id);
    private function GetCommandQueueProperties(id: DeviceInfo)      := GetVal&<CommandQueueProperties>(id);
    private function GetDeviceAffinityDomain(id: DeviceInfo)        := GetVal&<DeviceAffinityDomain>(id);
    private function GetDeviceSVMCapabilities(id: DeviceInfo)       := GetVal&<DeviceSVMCapabilities>(id);
    
    private function GetDevicePartitionPropertyArr(id: DeviceInfo)  := GetValArr&<DevicePartitionProperty>(id);
    
    {%Device.Properties!PropGen.pas%}
    
  end;
  
  {$endregion Device}
  
  {$region Context}
  
  ContextProperties = sealed class(NtvPropertiesBase<cl_context, ContextInfo>)
    
    private static function clGetSize(context: cl_context; param_name: ContextInfo; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetContextInfo';
    private static function clGetVal(context: cl_context; param_name: ContextInfo; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetContextInfo';
    
    protected procedure GetSizeImpl(id: ContextInfo; var sz: UIntPtr); override :=
    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;
    protected procedure GetValImpl(id: ContextInfo; sz: UIntPtr; var res: byte); override :=
    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;
    
    private function GetContextPropertiesArr(id: ContextInfo) := GetValArr&<ContextProperties>(id);
    
    {%Context.Properties!PropGen.pas%}
    
  end;
  
  {$endregion Context}
  
  {$region Buffer}
  
  BufferProperties = sealed class(NtvPropertiesBase<cl_mem, MemInfo>)
    
    private static function clGetSize(memobj: cl_mem; param_name: MemInfo; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetMemObjectInfo';
    private static function clGetVal(memobj: cl_mem; param_name: MemInfo; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetMemObjectInfo';
    
    protected procedure GetSizeImpl(id: MemInfo; var sz: UIntPtr); override :=
    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;
    protected procedure GetValImpl(id: MemInfo; sz: UIntPtr; var res: byte); override :=
    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;
    
    private function GetMemObjectType(id: MemInfo)  := GetVal&<MemObjectType>(id);
    private function GetMemFlags(id: MemInfo)       := GetVal&<MemFlags>(id);
    
    {%Mem.Properties!PropGen.pas%}
    
  end;
  
  {$endregion Buffer}
  
  {$region Kernel}
  
  KernelProperties = sealed class(NtvPropertiesBase<cl_kernel, KernelInfo>)
    
    private static function clGetSize(kernel: cl_kernel; param_name: KernelInfo; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetKernelInfo';
    private static function clGetVal(kernel: cl_kernel; param_name: KernelInfo; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetKernelInfo';
    
    protected procedure GetSizeImpl(id: KernelInfo; var sz: UIntPtr); override :=
    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;
    protected procedure GetValImpl(id: KernelInfo; sz: UIntPtr; var res: byte); override :=
    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;
    
    {%Kernel.Properties!PropGen.pas%}
    
  end;
  
  {$endregion Kernel}
  
  {$region Program}
  
  ProgramProperties = sealed class(NtvPropertiesBase<cl_program, ProgramInfo>)
    
    private static function clGetSize(&program: cl_program; param_name: ProgramInfo; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetProgramInfo';
    private static function clGetVal(&program: cl_program; param_name: ProgramInfo; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;
    external 'opencl.dll' name 'clGetProgramInfo';
    
    protected procedure GetSizeImpl(id: ProgramInfo; var sz: UIntPtr); override :=
    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;
    protected procedure GetValImpl(id: ProgramInfo; sz: UIntPtr; var res: byte); override :=
    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;
    
    {%Program.Properties!PropGen.pas%}
    
  end;
  
  {$endregion Program}
  
  {$endregion Properties}
  
  {$region Wrappers}
  
  {$region Base}
  
  WrapperBase<TNtv, TProp> = abstract class
  where TProp: class;
    private ntv: TNtv;
    
    private _properties: TProp;
    protected function GetProperties: TProp;
    begin
      if _properties=nil then _properties := CreateProp;
      Result := _properties;
    end;
    private function CreateProp: TProp; abstract;
    
    ///--
    public function Equals(obj: object): boolean; override :=
    (obj is WrapperBase<TNtv, TProp>(var wr)) and (self.ntv=wr.ntv);
    
  end;
  
  {$endregion Base}
  
  {$region Platform}
  
  Platform = sealed class(WrapperBase<cl_platform_id, PlatformProperties>)
    private function CreateProp: PlatformProperties; override := new PlatformProperties(ntv);
    
    public property Native: cl_platform_id read ntv;
    public property Properties: PlatformProperties read GetProperties;
    
    {$region constructor's}
    
    public constructor(pl: cl_platform_id) :=
    self.ntv := pl;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    private static _all: IList<Platform>;
    private static function MakePlatformList: IList<Platform>;
    begin
      if _all=nil then
      begin
        var c: UInt32;
        cl.GetPlatformIDs(0, IntPtr.Zero, c).RaiseIfError;
        
        var all_arr := new cl_platform_id[c];
        cl.GetPlatformIDs(c, all_arr[0], IntPtr.Zero).RaiseIfError;
        
        _all := new ReadOnlyCollection<Platform>(all_arr.ConvertAll(pl->new Platform(pl)));
      end;
      Result := _all;
    end;
    public static property All: IList<Platform> read MakePlatformList;
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(pl1, pl2: Platform): boolean := pl1.ntv = pl2.ntv;
    public static function operator<>(pl1, pl2: Platform): boolean := pl1.ntv <> pl2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}]';
    
    {$endregion operator's}
    
  end;
  
  {$endregion Platform}
  
  {$region Device}
  
  SubDevice = class;
  Device = class(WrapperBase<cl_device_id, DeviceProperties>)
    private function CreateProp: DeviceProperties; override := new DeviceProperties(ntv);
    
    public property Native: cl_device_id read ntv;
    public property Properties: DeviceProperties read GetProperties;
    
    public property BasePlatform: Platform read new Platform(Properties.GetVal&<cl_platform_id>(DeviceInfo.DEVICE_PLATFORM));
    
    {$region constructor's}
    
    public constructor(dvc: cl_device_id) :=
    self.ntv := dvc;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public static function GetAllFor(pl: Platform; t: DeviceType): array of Device;
    begin
      
      var c: UInt32;
      var ec := cl.GetDeviceIDs(pl.Native, t, 0, IntPtr.Zero, c);
      if ec=ErrorCode.DEVICE_NOT_FOUND then exit;
      ec.RaiseIfError;
      
      var all := new cl_device_id[c];
      cl.GetDeviceIDs(pl.Native, t, c, all[0], IntPtr.Zero).RaiseIfError;
      
      Result := all.ConvertAll(dvc->new Device(dvc));
    end;
    public static function GetAllFor(pl: Platform) := GetAllFor(pl, DeviceType.DEVICE_TYPE_GPU);
    
    private function Split(props: array of DevicePartitionProperty): array of SubDevice;
    
    public function SplitEqually(CUCount: integer): array of SubDevice;
    begin
      if CUCount <= 0 then raise new ArgumentException($'%Err:Device:SplitCUCount%');
      Result := Split(
        new DevicePartitionProperty[](
          DevicePartitionProperty.DEVICE_PARTITION_EQUALLY,
          DevicePartitionProperty.Create(CUCount),
          DevicePartitionProperty.Create(0)
        )
      );
    end;
    
    
    public function SplitByCounts(params CUCounts: array of integer): array of SubDevice;
    begin
      foreach var CUCount in CUCounts do
        if CUCount <= 0 then raise new ArgumentException($'%Err:Device:SplitCUCount%');
      
      var props := new DevicePartitionProperty[CUCounts.Length+2];
      props[0] := DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS;
      for var i := 0 to CUCounts.Length-1 do
        props[i+1] := new DevicePartitionProperty(CUCounts[i]);
      props[props.Length-1] := DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS_LIST_END;
      
      Result := Split(props);
    end;
    
    public function SplitByAffinityDomain(affinity_domain: DeviceAffinityDomain) :=
    Split(
      new DevicePartitionProperty[](
        DevicePartitionProperty.DEVICE_PARTITION_EQUALLY,
        DevicePartitionProperty.Create(new IntPtr(affinity_domain.val)),
        DevicePartitionProperty.Create(0)
      )
    );
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(dvc1, dvc2: Device): boolean := dvc1.ntv = dvc2.ntv;
    public static function operator<>(dvc1, dvc2: Device): boolean := dvc1.ntv <> dvc2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}]';
    
    {$endregion operator's}
    
  end;
  SubDevice = sealed class(Device)
    private _parent: Device;
    public property Parent: Device read _parent;
    
    {$region constructor's}
    
    private constructor(dvc: cl_device_id; parent: Device);
    begin
      inherited Create(dvc);
      self._parent := parent;
    end;
    private constructor := inherited;
    
    protected procedure Finalize; override :=
    cl.ReleaseDevice(ntv).RaiseIfError;
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator in(sub_dvc: SubDevice; dvc: Device): boolean := sub_dvc.Parent=dvc;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] of {Parent}';
    
    {$endregion operator's}
    
  end;
  
  {$endregion Device}
  
  {$region Context}
  
  CommandQueueBase = class;
  CommandQueue<T> = class;
  CLTaskBase = class;
  CLTask<T> = class;
  Context = sealed class(WrapperBase<cl_context, ContextProperties>, IDisposable)
    private dvcs: IList<Device>;
    private main_dvc: Device;
    
    private function CreateProp: ContextProperties; override := new ContextProperties(ntv);
    
    public property Native:     cl_context    read ntv;
    public property AllDevices: IList<Device> read dvcs;
    public property MainDevice: Device        read main_dvc;
    
    public property Properties: ContextProperties read GetProperties;
    
    private function GetAllNtvDevices: array of cl_device_id;
    begin
      Result := new cl_device_id[dvcs.Count];
      for var i := 0 to Result.Length-1 do
        Result[i] := dvcs[i].Native;
    end;
    
    {$region Default}
    
    private static default_need_init := true;
    private static default_init_lock := new object;
    private static _default: Context;
    
    private static function GetDefault: Context;
    begin
      
      if default_need_init then lock default_init_lock do if default_need_init then
      begin
        default_need_init := false;
        _default := MakeNewDefaultContext;
      end;
      
      Result := _default;
    end;
    private static procedure SetDefault(new_default: Context);
    begin
      default_need_init := false;
      _default := new_default;
    end;
    public static property &Default: Context read GetDefault write SetDefault;
    
    private static function MakeNewDefaultContext: Context;
    begin
      var pls := Platform.All;
      if pls=nil then exit;
      
      foreach var pl in pls do
      begin
        var dvcs := Device.GetAllFor(pl);
        if dvcs=nil then continue;
        Result := new Context(dvcs);
        exit;
      end;
      
      foreach var pl in pls do
      begin
        var dvcs := Device.GetAllFor(pl, DeviceType.DEVICE_TYPE_ALL);
        if dvcs=nil then continue;
        Result := new Context(dvcs);
        exit;
      end;
      
      Result := nil;
    end;
    
    {$endregion Default}
    
    {$region constructor's}
    
    private static procedure CheckMainDevice(main_dvc: Device; dvc_lst: IList<Device>) :=
    if not dvc_lst.Contains(main_dvc) then raise new ArgumentException($'%Err:Context:WrongMainDvc%');
    
    public constructor(dvcs: IList<Device>; main_dvc: Device);
    begin
      CheckMainDevice(main_dvc, dvcs);
      
      var ntv_dvcs := new cl_device_id[dvcs.Count];
      for var i := 0 to ntv_dvcs.Length-1 do
        ntv_dvcs[i] := dvcs[i].Native;
      
      var ec: ErrorCode;
      //ToDo позволить использовать CL_CONTEXT_INTEROP_USER_SYNC в свойствах
      self.ntv := cl.CreateContext(nil, ntv_dvcs.Count, ntv_dvcs, nil, IntPtr.Zero, ec);
      ec.RaiseIfError;
      
      self.dvcs := new ReadOnlyCollection<Device>(dvcs);
      self.main_dvc := main_dvc;
    end;
    public constructor(params dvcs: array of Device) := Create(dvcs, dvcs[0]);
    
    private static function GetContextDevices(ntv: cl_context): array of Device;
    begin
      
      var sz: UIntPtr;
      cl.GetContextInfo(ntv, ContextInfo.CONTEXT_DEVICES, UIntPtr.Zero, nil, sz).RaiseIfError;
      
      var res := new cl_device_id[uint64(sz) div Marshal.SizeOf&<cl_device_id>];
      cl.GetContextInfo(ntv, ContextInfo.CONTEXT_DEVICES, sz, res[0], IntPtr.Zero).RaiseIfError;
      
      Result := res.ConvertAll(dvc->new Device(dvc));
    end;
    private procedure InitFromNtv(ntv: cl_context; dvcs: IList<Device>; main_dvc: Device);
    begin
      CheckMainDevice(main_dvc, dvcs);
      cl.RetainContext(ntv).RaiseIfError;
      self.ntv := ntv;
      self.dvcs := new ReadOnlyCollection<Device>(dvcs);
      self.main_dvc := main_dvc;
    end;
    public constructor(ntv: cl_context; main_dvc: Device) :=
    InitFromNtv(ntv, GetContextDevices(ntv), main_dvc);
    
    public constructor(ntv: cl_context);
    begin
      var dvcs := GetContextDevices(ntv);
      InitFromNtv(ntv, dvcs, dvcs[0]);
    end;
    
    private constructor(c: Context; main_dvc: Device) :=
    InitFromNtv(c.ntv, c.dvcs, main_dvc);
    public function MakeSibling(new_main_dvc: Device) := new Context(self, new_main_dvc);
    
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure Dispose :=
    if ntv<>cl_context.Zero then lock self do
    begin
      cl.ReleaseContext(ntv).RaiseIfError;
      ntv := cl_context.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(c1, c2: Context): boolean := c1.ntv = c2.ntv;
    public static function operator<>(c1, c2: Context): boolean := c1.ntv <> c2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] on devices: {AllDevices.JoinToString('', '')}; Main device: {MainDevice}';
    
    {$endregion operator's}
    
    {$region Invoke}
    
    public function BeginInvoke<T>(q: CommandQueue<T>): CLTask<T>;
    public function BeginInvoke(q: CommandQueueBase): CLTaskBase;
    
    public function SyncInvoke<T>(q: CommandQueue<T>): T;
    public function SyncInvoke(q: CommandQueueBase): Object;
    
    {$endregion Invoke}
    
  end;
  
  {$endregion Context}
  
  {$region Buffer}
  
  BufferCommandQueue = class;
  KernelArg = class;
  Buffer = class(WrapperBase<cl_mem, BufferProperties>, IDisposable)
    private sz: UIntPtr;
    
    public property Native: cl_mem read ntv;
    
    private function CreateProp: BufferProperties; override;
    begin
      if ntv=cl_mem.Zero then raise new InvalidOperationException($'%Err:Buffer:Empty%');
      Result := new BufferProperties(ntv);
    end;
    public property Properties: BufferProperties read GetProperties;
    
    public property Size: UIntPtr read sz;
    public property Size32: UInt32 read sz.ToUInt32;
    public property Size64: UInt64 read sz.ToUInt64;
    
    public function NewQueue: BufferCommandQueue;
    
    {$region constructor's}
    
    public constructor(size: UIntPtr) := self.sz := size;
    public constructor(size: integer) := Create(new UIntPtr(size));
    public constructor(size: int64)   := Create(new UIntPtr(size));
    
    public constructor(size: UIntPtr; c: Context);
    begin
      Create(size);
      Init(c);
    end;
    public constructor(size: integer; c: Context) := Create(new UIntPtr(size), c);
    public constructor(size: int64; c: Context)   := Create(new UIntPtr(size), c);
    
    protected constructor(ntv: cl_mem);
    begin
      cl.RetainMemObject(ntv).RaiseIfError;
      self.ntv := ntv;
      
      cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(Marshal.SizeOf&<UIntPtr>), self.sz, IntPtr.Zero).RaiseIfError;
      GC.AddMemoryPressure(Size64);
      
    end;
    
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure Init(c: Context); virtual :=
    lock self do
    begin
      
      var ec: ErrorCode;
      var new_ntv := cl.CreateBuffer(c.Native, MemFlags.MEM_READ_WRITE, sz, IntPtr.Zero, ec);
      ec.RaiseIfError;
      
      if self.ntv=cl_mem.Zero then
        GC.AddMemoryPressure(Size64) else
        cl.ReleaseMemObject(self.ntv).RaiseIfError;
      
      self.ntv := new_ntv;
    end;
    
    public procedure InitIfNeed(c: Context); virtual :=
    if self.ntv=cl_mem.Zero then lock self do
    begin
      if self.ntv<>cl_mem.Zero then exit; // Во время ожидания lock могли инициализировать
      
      var ec: ErrorCode;
      var new_ntv := cl.CreateBuffer(c.Native, MemFlags.MEM_READ_WRITE, sz, IntPtr.Zero, ec);
      ec.RaiseIfError;
      
      GC.AddMemoryPressure(Size64);
      self.ntv := new_ntv;
    end;
    
    public procedure Dispose; virtual :=
    if ntv<>cl_mem.Zero then lock self do
    begin
      if self.ntv=cl_mem.Zero then exit; // Во время ожидания lock могли удалить
      self._properties := nil;
      GC.RemoveMemoryPressure(Size64);
      cl.ReleaseMemObject(ntv).RaiseIfError;
      ntv := cl_mem.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(b1, b2: Buffer): boolean := b1.ntv = b2.ntv;
    public static function operator<>(b1, b2: Buffer): boolean := b1.ntv <> b2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] of size {Size}';
    
    {$endregion operator's}
    
    {%BufferMethods.Implicit.Interface!MethodGen.pas%}
    
    {%BufferGetMethods.Implicit.Interface!GetMethodGen.pas%}
    
  end;
  SubBuffer = sealed class(Buffer)
    private _parent: Buffer;
    public property Parent: Buffer read _parent;
    
    {$region operator's}
    
    public static function operator in(sub_b: SubBuffer; b: Buffer): boolean := sub_b.Parent=b;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] of size {Size} inside {Parent}';
    
    {$endregion operator's}
    
    {$region constructor's}
    
    protected constructor(parent: Buffer; reg: cl_buffer_region);
    begin
      inherited Create(reg.size);
      
      var parent_ntv := parent.Native;
      if parent_ntv=cl_mem.Zero then raise new InvalidOperationException($'%Err:Buffer:Empty%');
      
      var ec: ErrorCode;
      self.ntv := cl.CreateSubBuffer(parent_ntv, MemFlags.MEM_READ_WRITE, BufferCreateType.BUFFER_CREATE_TYPE_REGION, reg, ec);
      ec.RaiseIfError;
      
      self._parent := parent;
    end;
    public constructor(parent: Buffer; origin, size: UIntPtr) := Create(parent, new cl_buffer_region(origin, size));
    
    public constructor(parent: Buffer; origin, size: UInt32) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    public constructor(parent: Buffer; origin, size: UInt64) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    
    private procedure InitIgnoreOrErr :=
    if self.ntv=cl_mem.Zero then raise new NotSupportedException($'%Err:SubBuffer:InitCall%');
    public procedure Init(c: Context); override := InitIgnoreOrErr;
    public procedure InitIfNeed(c: Context); override := InitIgnoreOrErr;
    
    public procedure Dispose; override :=
    if ntv<>cl_mem.Zero then lock self do
    begin
      if self.ntv=cl_mem.Zero then exit; // Во время ожидания lock могли удалить
      self._properties := nil;
      cl.ReleaseMemObject(ntv).RaiseIfError;
      ntv := cl_mem.Zero;
    end;
    
    {$endregion constructor's}
    
  end;
  
  {$endregion Buffer}
  
  {$region Kernel}
  
  KernelCommandQueue = class;
  Kernel = sealed class(WrapperBase<cl_kernel, KernelProperties>, IDisposable)
    private function CreateProp: KernelProperties; override := new KernelProperties(ntv);
    
    public property Native: cl_kernel read ntv;
    public property Properties: KernelProperties read GetProperties;
    
    private _prog: cl_program;
    private _name: string;
    public property Name: string read _name;
    
    public function NewQueue: KernelCommandQueue;
    
    {$region constructor's}
    
    private function MakeNewNtv: cl_kernel;
    begin
      var ec: ErrorCode;
      Result := cl.CreateKernel(_prog, _name, ec);
      ec.RaiseIfError;
    end;
    protected constructor(prog: cl_program; name: string);
    begin
      self._prog := prog;
      self._name := name;
      self.ntv := self.MakeNewNtv;
    end;
    
    public constructor(ntv: cl_kernel; retain: boolean := true);
    begin
      
      cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, new UIntPtr(cl_program.Size), self._prog, IntPtr.Zero).RaiseIfError;
      
      var sz: UIntPtr;
      cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, UIntPtr.Zero, nil, sz).RaiseIfError;
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, sz, str_ptr, IntPtr.Zero).RaiseIfError;
        self._name := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
      if retain then cl.RetainKernel(ntv).RaiseIfError;
      self.ntv := ntv;
    end;
    
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure Dispose :=
    if ntv<>cl_kernel.Zero then lock self do
    begin
      if ntv=cl_kernel.Zero then exit;
      cl.ReleaseKernel(ntv).RaiseIfError;
      ntv := cl_kernel.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(k1, k2: Kernel): boolean := k1.ntv = k2.ntv;
    public static function operator<>(k1, k2: Kernel): boolean := k1.ntv <> k2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{Name}:{ntv.val}]';
    
    {$endregion operator's}
    
    {$region UseExclusiveNative}
    
    private exclusive_ntv_lock := new object;
    public procedure UseExclusiveNative(p: cl_kernel->());
    begin
      var owned := Monitor.TryEnter(exclusive_ntv_lock);
      var k: cl_kernel;
      try
        k := owned ? ntv : MakeNewNtv;
        p(k);
      finally
        if owned then
          Monitor.Exit(exclusive_ntv_lock) else
          cl.ReleaseKernel(k).RaiseIfError;
      end;
    end;
    public function UseExclusiveNative<T>(f: cl_kernel->T): T;
    begin
      var owned := Monitor.TryEnter(exclusive_ntv_lock);
      var k: cl_kernel;
      try
        k := owned ? ntv : MakeNewNtv;
        Result := f(k);
      finally
        if owned then
          Monitor.Exit(exclusive_ntv_lock) else
          cl.ReleaseKernel(k).RaiseIfError;
      end;
    end;
    
    {$endregion UseExclusiveNative}
    
    {%KernelMethods.Implicit.Interface!MethodGen.pas%}
    
  end;
  
  {$endregion Kernel}
  
  {$region ProgramCode}
  
  ProgramCode = sealed class(WrapperBase<cl_program, ProgramProperties>)
    private function CreateProp: ProgramProperties; override := new ProgramProperties(ntv);
    
    public property Native: cl_program read ntv;
    public property Properties: ProgramProperties read GetProperties;
    
    protected _c: Context;
    public property BaseContext: Context read _c;
    
    {$region constructor's}
    
    private procedure Build;
    begin
      
      var ec := cl.BuildProgram(self.ntv, _c.dvcs.Count,_c.GetAllNtvDevices, nil, nil,IntPtr.Zero);
      if ec=ErrorCode.BUILD_PROGRAM_FAILURE then
      begin
        var sb := new StringBuilder($'%Err:ProgramCode:BuildFail%');
        
        foreach var dvc in _c.AllDevices do
        begin
          sb += #10#10;
          sb += dvc.ToString;
          sb += ':'#10;
          
          var sz: UIntPtr;
          cl.GetProgramBuildInfo(self.ntv, dvc.Native, ProgramBuildInfo.PROGRAM_BUILD_LOG, UIntPtr.Zero,IntPtr.Zero,sz).RaiseIfError;
          
          var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
          try
            cl.GetProgramBuildInfo(self.ntv, dvc.Native, ProgramBuildInfo.PROGRAM_BUILD_LOG, sz,str_ptr,IntPtr.Zero).RaiseIfError;
            sb += Marshal.PtrToStringAnsi(str_ptr);
          finally
            Marshal.FreeHGlobal(str_ptr);
          end;
          
        end;
        
        raise new OpenCLException(ec, sb.ToString);
      end else
        ec.RaiseIfError;
      
    end;
    
    public constructor(c: Context; params files_texts: array of string);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateProgramWithSource(c.Native, files_texts.Length, files_texts, nil, ec);
      ec.RaiseIfError;
      
      self._c := c;
      self.Build;
      
    end;
    
    private constructor(ntv: cl_program; c: Context);
    begin
      cl.RetainProgram(ntv).RaiseIfError;
      self._c := c;
      self.ntv := ntv;
    end;
    
    private static function GetProgContext(ntv: cl_program): Context;
    begin
      var c: cl_context;
      cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_CONTEXT, new UIntPtr(Marshal.SizeOf&<cl_context>), c, IntPtr.Zero).RaiseIfError;
      Result := new Context(c);
    end;
    public constructor(ntv: cl_program) :=
    Create(ntv, GetProgContext(ntv));
    
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure Dispose :=
    if ntv<>cl_program.Zero then lock self do
    begin
      if ntv=cl_program.Zero then exit;
      cl.ReleaseProgram(ntv).RaiseIfError;
      ntv := cl_program.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
    {$region GetKernel}
    
    public property KernelByName[kname: string]: Kernel read new Kernel(ntv, kname); default;
    
    public function GetAllKernels: array of Kernel;
    begin
      
      var c: UInt32;
      cl.CreateKernelsInProgram(ntv, 0, IntPtr.Zero, c).RaiseIfError;
      
      var res := new cl_kernel[c];
      cl.CreateKernelsInProgram(ntv, c, res[0], IntPtr.Zero).RaiseIfError;
      
      Result := res.ConvertAll(k->new Kernel(k, false));
    end;
    
    {$endregion GetKernel}
    
    {$region Serialize}
    
    public function Serialize: array of array of byte :=
    {%Static\ProgramCode.Serialize!!Stub= } nil { %};
    
    public procedure SerializeTo(bw: System.IO.BinaryWriter);
    begin
      var bin := Serialize;
      
      bw.Write(bin.Length);
      foreach var a in bin do
      begin
        bw.Write(a.Length);
        bw.Write(a);
      end;
      
    end;
    public procedure SerializeTo(str: System.IO.Stream) :=
    SerializeTo(new System.IO.BinaryWriter(str));
    
    {$endregion Serialize}
    
    {$region Deserialize}
    
    public static function Deserialize(c: Context; bin: array of array of byte): ProgramCode;
    begin
      var ntv: cl_program;
      
      var dvcs := c.GetAllNtvDevices;
      
      var ec: ErrorCode;
      ntv := cl.CreateProgramWithBinary(
        c.Native, c.AllDevices.Count, dvcs[0],
        bin.ConvertAll(a->new UIntPtr(a.Length))[0], bin,
        IntPtr.Zero, ec
      );
      ec.RaiseIfError;
      
      Result := new ProgramCode(ntv, c);
      Result.Build;
      
    end;
    
    public static function DeserializeFrom(c: Context; br: System.IO.BinaryReader): ProgramCode;
    begin
      var bin: array of array of byte;
      
      SetLength(bin, br.ReadInt32);
      for var i := 0 to bin.Length-1 do
      begin
        var len := br.ReadInt32;
        bin[i] := br.ReadBytes(len);
        if bin[i].Length<>len then raise new System.IO.EndOfStreamException;
      end;
      
      Result := Deserialize(c, bin);
    end;
    public static function DeserializeFrom(c: Context; str: System.IO.Stream) :=
    DeserializeFrom(c, new System.IO.BinaryReader(str));
    
    {$endregion Deserialize}
    
  end;
  
  {$endregion ProgramCode}
  
  {$endregion Wrappers}
  
  {$region Util type's}
  
  {$region CLTaskExt}
  
  UserEvent = class;
  CLTaskExt = static class
    
    static procedure AddErr(tsk: CLTaskBase; e: Exception);
    static function AddErr(tsk: CLTaskBase; ec: ErrorCode): boolean;
    static function AddErr(tsk: CLTaskBase; st: CommandExecutionStatus): boolean;
    
  end;
  
  {$endregion CLTaskExt}
  
  {$region NativeUtils}
  
  NativeUtils = static class
    public static AbortStatus := new CommandExecutionStatus(integer.MinValue);
    
    public static function CopyToUnm<TRecord>(a: TRecord): IntPtr; where TRecord: record;
    begin
      Result := Marshal.AllocHGlobal(Marshal.SizeOf&<TRecord>);
      var res: ^TRecord := pointer(Result);
      res^ := a;
    end;
    
    public static function AsPtr<T>(p: pointer): ^T := p;
    public static function AsPtr<T>(p: IntPtr) := AsPtr&<T>(pointer(p));
    
    public static function GCHndAlloc(o: object) :=
    CopyToUnm(GCHandle.Alloc(o));
    
    public static procedure GCHndFree(gc_hnd_ptr: IntPtr);
    begin
      AsPtr&<GCHandle>(gc_hnd_ptr)^.Free;
      Marshal.FreeHGlobal(gc_hnd_ptr);
    end;
    
    public static function StartNewThread(p: Action): Thread;
    begin
      Result := new Thread(p);
      Result.IsBackground := true;
      Result.Start;
    end;
    
    protected static procedure FixCQ(c: cl_context; dvc: cl_device_id; var cq: cl_command_queue);
    begin
      if cq <> cl_command_queue.Zero then exit;
      var ec: ErrorCode;
      cq := cl.CreateCommandQueue(c, dvc, CommandQueueProperties.NONE, ec);
      ec.RaiseIfError;
    end;
    
  end;
  
  {$endregion NativeUtils}
  
  {$region Blittable}
  
  BlittableException = sealed class(Exception)
    public constructor(t, blame: System.Type; source_name: string) :=
    inherited Create(t=blame ? $'%Err:Blittable:Main%' : $'%Err:Blittable:Blame%' );
  end;
  BlittableHelper = static class
    
    private static blittable_cache := new Dictionary<System.Type, System.Type>;
    public static function Blame(t: System.Type): System.Type;
    begin
      if t.IsPointer then exit;
      if t.IsClass then
      begin
        Result := t;
        exit;
      end;
      
      //ToDo протестировать - может быстрее будет без blittable_cache, потому что всё заинлайнится?
      if blittable_cache.TryGetValue(t, Result) then exit;
      
      foreach var fld in t.GetFields(System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.Public or System.Reflection.BindingFlags.NonPublic) do
        if fld.FieldType<>t then
        begin
          Result := Blame(fld.FieldType);
          if Result<>nil then break;
        end;
      
      blittable_cache[t] := Result;
    end;
    
    public static function IsBlittable(t: System.Type) := Blame(t)=nil;
    public static procedure RaiseIfNeed(t: System.Type; source_name: string);
    begin
      var blame := BlittableHelper.Blame(t);
      if blame=nil then exit;
      raise new BlittableException(t, blame, source_name);
    end;
    
  end;
  
  {$endregion Blittable}
  
  {$region EventList}
  
  EventList = sealed class
    public evs: array of cl_event;
    public count := 0;
    public abortable := false; // true только если можно моментально отменить
    
    public constructor := exit;
    
    public constructor(count: integer) :=
    self.evs := count=0 ? nil : new cl_event[count];
    
    public property Item[i: integer]: cl_event read evs[i]; default;
    
    public static function operator implicit(ev: cl_event): EventList;
    begin
      if ev=cl_event.Zero then
        Result := new EventList else
      begin
        Result := new EventList(1);
        Result += ev;
      end;
    end;
    
    public constructor(params evs: array of cl_event);
    begin
      self.evs := evs;
      self.count := evs.Length;
    end;
    
    public static procedure operator+=(l: EventList; ev: cl_event);
    begin
      l.evs[l.count] := ev;
      l.count += 1;
    end;
    
    public static procedure operator+=(l: EventList; ev: EventList);
    begin
      for var i := 0 to ev.count-1 do
        l += ev[i];
      if ev.abortable then l.abortable := true;
    end;
    
    public static function operator+(l1, l2: EventList): EventList;
    begin
      Result := new EventList(l1.count+l2.count);
      Result += l1;
      Result += l2;
      Result.abortable := l1.abortable and l2.abortable;
    end;
    
    public static function operator+(l: EventList; ev: cl_event): EventList;
    begin
      Result := new EventList(l.count+1);
      Result += l;
      Result += ev;
    end;
    
    public static function operator=(l1, l2: EventList): boolean;
    begin
      if object.ReferenceEquals(l1, l2) then
      begin
        Result := true;
        exit;
      end;
      if object.ReferenceEquals(l1, nil) then exit;
      if object.ReferenceEquals(l2, nil) then exit;
      if l1.count <> l2.count then exit;
      for var i := 0 to l1.count-1 do
        if l1[i]<>l2[i] then exit;
      Result := true;
    end;
    public static function operator<>(l1, l2: EventList): boolean := not (l1=l2);
    
    private static function Combine(evs: IList<EventList>; tsk: CLTaskBase; c: cl_context; main_dvc: cl_device_id; var cq: cl_command_queue): EventList;
    
    public procedure Retain :=
    for var i := 0 to count-1 do
      cl.RetainEvent(evs[i]).RaiseIfError;
    
    public procedure Release :=
    for var i := 0 to count-1 do
      cl.ReleaseEvent(evs[i]).RaiseIfError;
    public function Release(tsk: CLTaskBase): boolean;
    begin
      for var i := 0 to count-1 do
        if CLTaskExt.AddErr(tsk, cl.ReleaseEvent(evs[i])) then
          Result := true;
    end;
    
    public static procedure AttachCallback(ev: cl_event; cb: EventCallback) :=
    cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, NativeUtils.GCHndAlloc(cb)).RaiseIfError;
    public static procedure AttachCallback(ev: cl_event; cb: EventCallback; tsk: CLTaskBase) :=
    CLTaskExt.AddErr(tsk, cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, NativeUtils.GCHndAlloc(cb)) );
    
    private static function DefaultStatusErr(tsk: CLTaskBase; st: CommandExecutionStatus): boolean := CLTaskExt.AddErr(tsk, st);
    public static procedure AttachCallback(ev: cl_event; work: Action; tsk: CLTaskBase; st_err_handler: (CLTaskBase, CommandExecutionStatus)->boolean := DefaultStatusErr) :=
    AttachCallback(ev, (ev,st,data)->
    begin
      NativeUtils.GCHndFree(data);
      if st_err_handler(tsk, st) then exit;
      if CLTaskExt.AddErr(tsk, cl.ReleaseEvent(ev)) then exit;
      
      try
        work;
      except
        on e: Exception do CLTaskExt.AddErr(tsk, e);
      end;
      
    end);
    public static procedure AttachFinallyCallback(ev: cl_event; work: Action; tsk: CLTaskBase) :=
    AttachCallback(ev, (ev,st,data)->
    begin
      NativeUtils.GCHndFree(data);
      
      try
        work;
      except
        on e: Exception do CLTaskExt.AddErr(tsk, e);
      end;
      
    end);
    
    public function ToMarker(c: cl_context; dvc: cl_device_id; var cq: cl_command_queue): cl_event;
    begin
      
      if self.count>1 then
      begin
        NativeUtils.FixCQ(c, dvc, cq);
        cl.EnqueueMarkerWithWaitList(cq, self.count, self.evs, Result).RaiseIfError;
      end else
      begin
        Result := self[0]; // 0 элементов не должно быть. но если что - сразу видно где ошибка
        cl.RetainEvent(Result).RaiseIfError;
      end;
      
    end;
    
    private function SmartStatusErr(tsk: CLTaskBase; st: CommandExecutionStatus): boolean;
    begin
      //ToDo NV#3035203
//      if not st.IS_ERROR then exit;
//      if st.val <> ErrorCode.EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST.val then
//        Result := CLTaskExt.AddErr(tsk, st) else
        for var i := 0 to count-1 do
        begin
          if CLTaskExt.AddErr(tsk, cl.GetEventInfo(
            evs[i], EventInfo.EVENT_COMMAND_EXECUTION_STATUS,
            new UIntPtr(sizeof(CommandExecutionStatus)), st, IntPtr.Zero
          )) then continue;
          if CLTaskExt.AddErr(tsk, st) then Result := true;
        end;
      
      //ToDo NV#3035203 - без бага эта часть не нужна
      if st.val <> ErrorCode.EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST.val then
        if CLTaskExt.AddErr(tsk, st) then Result := true;
    end;
    public procedure AttachCallback(work: Action; tsk: CLTaskBase; c: cl_context; dvc: cl_device_id; var cq: cl_command_queue) :=
    if evs=nil then work else AttachCallback(self.ToMarker(c, dvc, cq), work, tsk, SmartStatusErr);
    public procedure AttachFinallyCallback(work: Action; tsk: CLTaskBase; c: cl_context; dvc: cl_device_id; var cq: cl_command_queue) :=
    if evs=nil then work else AttachFinallyCallback(self.ToMarker(c, dvc, cq), work, tsk);
    
    /// True если возникла ошибка
    public function WaitAndRelease(tsk: CLTaskBase): boolean;
    begin
      Result := SmartStatusErr(tsk, CommandExecutionStatus(cl.WaitForEvents(self.count, self.evs)));
      if self.Release(tsk) then Result := true;
    end;
    
  end;
  
  {$endregion EventList}
  
  {$region UserEvent}
  
  UserEvent = sealed class
    private uev: cl_event;
    private done := false;
    
    {$region constructor's}
    
    public constructor(c: cl_context);
    begin
      var ec: ErrorCode;
      self.uev := cl.CreateUserEvent(c, ec);
      ec.RaiseIfError;
    end;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    static function MakeUserEvent(tsk: CLTaskBase; c: cl_context): UserEvent;
    
    public static function StartBackgroundWork(after: EventList; work: Action; c: cl_context; tsk: CLTaskBase): UserEvent;
    begin
      var res := MakeUserEvent(tsk, c);
      
      var abort_thr_ev := new AutoResetEvent(false);
      res.AttachFinallyCallback(()->abort_thr_ev.Set(), tsk);
      
      var work_thr: Thread;
      var abort_thr := NativeUtils.StartNewThread(()->
      begin
        abort_thr_ev.WaitOne; // изначальная пауза, чтобы work_thr не убили до того как он успеет запуститься и выполнить cl.ReleaseEvent
        abort_thr_ev.WaitOne;
        work_thr.Abort;
      end);
      
      work_thr := NativeUtils.StartNewThread(()->
      try
        var err := (after<>nil) and (after.count<>0) and
          (after.abortable ? after : after + MakeUserEvent(tsk,c)).WaitAndRelease(tsk);
        // ThreadAbortException может прийти только из abort_thr, поэтому до следующей строчки - его не будет
        // Таким образом следующая строчка всегда выполнится
        abort_thr_ev.Set;
        // Далее - в любом случае выполняется res.SetStatus, который вызывает
        // содержимое res.AttachFinallyCallback выше
        // Поэтому abort_thr никогда не застрянет
        
        if err then
        begin
          abort_thr.Abort;
          res.Abort;
        end else
        begin
          work;
          abort_thr.Abort;
          res.SetStatus(CommandExecutionStatus.COMPLETE);
        end;
        
      except
        on e: Exception do
        begin
          CLTaskExt.AddErr(tsk, e);
          // Первый .AddErr всегда сам вызывает .Abort на всех UserEvent
          // А значит и abort_thr.Abort уже выполнило выше
          // Единственное исключение - если "e is ThreadAbortException"
          // Но это случится только если abort_thr уже доработало
//          abort_thr.Abort;
//          res.Abort;
        end;
      end);
      
      Result := res;
    end;
    
    {$endregion constructor's}
    
    {$region Status}
    
    public property CanRemove: boolean read done;
    
    /// True если статус получилось изменить
    public function SetStatus(st: CommandExecutionStatus): boolean;
    begin
      lock self do
      begin
        if done then exit;
        cl.SetUserEventStatus(uev, st).RaiseIfError;
        done := true;
        Result := true;
      end;
    end;
    /// True если статус получилось изменить
    public function SetStatus(st: CommandExecutionStatus; tsk: CLTaskBase): boolean;
    begin
      lock self do
      begin
        if done then exit;
        if CLTaskExt.AddErr(tsk, cl.SetUserEventStatus(uev, st)) then exit;
        done := true;
        Result := true;
      end;
    end;
    public function Abort := SetStatus(NativeUtils.AbortStatus);
    
    {$endregion Status}
    
    {$region AttachCallback}
    
    public procedure AttachFinallyCallback(work: Action; tsk: CLTaskBase);
    begin
      cl.RetainEvent(self.uev).RaiseIfError;
      EventList.AttachFinallyCallback(self, work, tsk);
    end;
    
    {$endregion AttachCallback}
    
    {$region operator's}
    
    public static function operator implicit(ev: UserEvent): cl_event := ev.uev;
    public static function operator implicit(ev: UserEvent): EventList;
    begin
      Result := ev.uev;
      Result.abortable := true;
    end;
    
    public static function operator +(ev1: EventList; ev2: UserEvent): EventList;
    begin
      Result := ev1 + ev2.uev;
      Result.abortable := true;
    end;
    
    {$endregion operator's}
    
  end;
  
  {$endregion UserEvent}
  
  {$region QueueRes}
  
  IPtrQueueRes<T> = interface
    function GetPtr: ^T;
  end;
  QRPtrWrap<T> = sealed class(IPtrQueueRes<T>)
    private ptr: ^T := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<T>));
    
    public constructor(val: T) := self.ptr^ := val;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(new IntPtr(ptr));
    
    public function GetPtr: ^T := ptr;
    
  end;
  
  QueueRes<T> = class;
  QueueResBase = abstract class
    public ev: EventList;
    public can_set_ev := true;
    
    public constructor(ev: EventList) :=
    self.ev := ev;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public function TrySetEvBase(new_ev: EventList): QueueResBase; abstract;
    
    public function GetResBase: object; abstract;
    
    public function LazyQuickTransformBase<T2>(f: object->T2): QueueRes<T2>; abstract;
    
  end;
  
  QueueResDelayedPtr<T> = class;
  QueueRes<T> = abstract class(QueueResBase)
    
    public function GetRes: T; abstract;
    public function GetResBase: object; override := GetRes;
    
    public function Clone: QueueRes<T>; abstract;
    
    public function TrySetEv(new_ev: EventList): QueueRes<T>;
    begin
      if self.ev=new_ev then
        Result := self else
      begin
        Result := can_set_ev ? self : Clone;
        Result.ev := new_ev;
      end;
    end;
    public function TrySetEvBase(new_ev: EventList): QueueResBase; override := TrySetEv(new_ev);
    
    public function EnsureAbortability(tsk: CLTaskBase; c: Context): QueueRes<T>;
    begin
      Result := self;
      if (ev.count<>0) and not ev.abortable then
        Result := Result.TrySetEv(ev + UserEvent.MakeUserEvent(tsk, c.Native));
    end;
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>; abstract;
    public function LazyQuickTransformBase<T2>(f: object->T2): QueueRes<T2>; override :=
    LazyQuickTransform(o->f(o));
    
    /// Должно выполнятся только после ожидания ивентов
    public function ToPtr: IPtrQueueRes<T>; abstract;
    
  end;
  
  // Результат который просто есть
  IQueueResConst = interface end;
  QueueResConst<T> = sealed class(QueueRes<T>, IQueueResConst)
    private res: T;
    
    public constructor(res: T; ev: EventList);
    begin
      inherited Create(ev);
      self.res := res;
    end;
    private constructor := inherited;
    
    public function Clone: QueueRes<T>; override := new QueueResConst<T>(res, ev);
    
    public function GetRes: T; override := res;
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>; override :=
    new QueueResConst<T2>(f(self.res), self.ev);
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(res);
    
  end;
  
  // Результат который надо будет сначала дождаться, а потом ещё досчитать
  IQueueResFunc = interface
    function GetF: ()->object;
  end;
  QueueResFunc<T> = sealed class(QueueRes<T>, IQueueResFunc)
    private f: ()->T;
    
    public constructor(f: ()->T; ev: EventList);
    begin
      inherited Create(ev);
      self.f := f;
    end;
    private constructor := inherited;
    
    public function Clone: QueueRes<T>; override := new QueueResFunc<T>(f, ev);
    
    public function GetRes: T; override := f();
    public function IQueueResFunc.GetF: ()->object := ()->f();
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>; override :=
    new QueueResFunc<T2>(()->f(self.f()), self.ev);
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(f());
    
  end;
  
  // Результат который будет сохранён куда то, надо только дождаться
  IQueueResDelayed = interface end;
  QueueResDelayedBase<T> = abstract class(QueueRes<T>, IQueueResDelayed)
    
    public static function MakeNew(need_ptr_qr: boolean): QueueResDelayedBase<T>;
    
    public procedure SetRes(value: T); abstract;
    
    public function Clone: QueueRes<T>; override := new QueueResFunc<T>(self.GetRes, ev);
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>; override :=
    new QueueResFunc<T2>(()->f(self.GetRes()), self.ev);
    
  end;
  QueueResDelayedObj<T> = sealed class(QueueResDelayedBase<T>)
    private res := default(T);
    
    public constructor :=
    inherited Create(nil);
    
    public function GetRes: T; override := res;
    public procedure SetRes(value: T); override := res := value;
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(res);
    
  end;
  QueueResDelayedPtr<T> = sealed class(QueueResDelayedBase<T>, IPtrQueueRes<T>)
    private ptr: ^T := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<T>));
    
    public constructor :=
    inherited Create(nil);
    
    public constructor(res: T; ev: EventList);
    begin
      inherited Create(ev);
      self.ptr^ := res;
    end;
    
    public function GetPtr: ^T := ptr;
    public function GetRes: T; override := ptr^;
    public procedure SetRes(value: T); override := ptr^ := value;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(new IntPtr(ptr));
    
    public function ToPtr: IPtrQueueRes<T>; override := self;
    
  end;
  
  {$endregion QueueRes}
  
  {$region MWEventContainer}
  
  MWEventContainer = sealed class // MW = Multi Wait
    private curr_handlers := new Queue<()->boolean>;
    private cached := 0;
    
    public procedure AddHandler(handler: ()->boolean) :=
    lock self do
      if cached=0 then
        curr_handlers += handler else
      if handler() then
        cached -= 1;
    
    public procedure ExecuteHandler :=
    lock self do
    begin
      while curr_handlers.Count<>0 do
        if curr_handlers.Dequeue()() then
          exit;
      cached += 1;
    end;
    
  end;
  
  {$endregion MWEventContainer}
  
  {$endregion Util type's}
  
  {$region Multiusable}
  
  MultiusableCommandQueueHubBase = abstract class
    
  end;
  
  {$endregion Multiusable}
  
  {$region CLTask}
  
  CLTaskBase = abstract class
    
    protected wh := new ManualResetEvent(false);
    protected wh_lock := new object;
    
    protected mu_res := new Dictionary<MultiusableCommandQueueHubBase, QueueResBase>;
    
    {$region property's}
    
    private function OrgQueueBase: CommandQueueBase; abstract;
    public property OrgQueue: CommandQueueBase read OrgQueueBase;
    
    private org_c: Context;
    public property OrgContext: Context read org_c;
    
    {$endregion property's}
    
    {$region AddErr}
    protected err_lst := new List<Exception>;
    
    /// lock err_lst do err_lst.ToArray
    private function GetErrArr: array of Exception;
    begin
      lock err_lst do
        Result := err_lst.ToArray;
    end;
    
    public property Error: AggregateException read err_lst.Count=0 ? nil : new AggregateException($'%Err:CLTask:%', GetErrArr);
    
    protected procedure AddErr(e: Exception) :=
    begin
      if e is ThreadAbortException then exit;
      lock err_lst do err_lst += e;
      lock user_events do
      begin
        for var i := user_events.Count-1 downto 0 do
          user_events[i].Abort;
        user_events.Clear;
      end;
    end;
    
    /// True если ошибка есть
    protected function AddErr(ec: ErrorCode): boolean;
    begin
      if not ec.IS_ERROR then exit;
      AddErr(new OpenCLException(ec, $'Внутренняя ошибка OpenCLABC: {ec}{#10}{Environment.StackTrace}'));
      Result := true;
    end;
    /// True если ошибка есть
    protected function AddErr(st: CommandExecutionStatus) :=
    (st=NativeUtils.AbortStatus) or (st.IS_ERROR and AddErr(ErrorCode(st)));
    
    {$endregion AddErr}
    
    {$region UserEvent's}
    protected user_events := new List<UserEvent>;
    
    protected function MakeUserEvent(c: cl_context): UserEvent;
    begin
      Result := new UserEvent(c);
      
      lock user_events do
      begin
        if err_lst.Count<>0 then
          Result.Abort else
          user_events += Result;
      end;
      
    end;
    
    {$endregion UserEvent's}
    
    {$region CLTask event's}
    
    protected procedure WhenDoneBase(cb: Action<CLTaskBase>); abstract;
    public procedure WhenDone(cb: Action<CLTaskBase>) := WhenDoneBase(cb);
    
    protected procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); abstract;
    public procedure WhenComplete(cb: Action<CLTaskBase, object>) := WhenCompleteBase(cb);
    
    protected procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); abstract;
    public procedure WhenError(cb: Action<CLTaskBase, array of Exception>) := WhenErrorBase(cb);
    
    /// True если очередь уже завершилась
    private function AddEventHandler<T>(ev: List<T>; cb: T): boolean; where T: Delegate;
    begin
      lock wh_lock do
      begin
        Result := wh.WaitOne(0);
        if not Result then ev += cb;
      end;
    end;
    
    {$endregion CLTask event's}
    
    {$region SyncRes}
    
    public procedure Wait;
    begin
      wh.WaitOne;
      var err := self.Error;
      if err<>nil then raise err;
    end;
    
    protected function WaitResBase: object; abstract;
    public function WaitRes := WaitResBase;
    
    {$endregion}
    
  end;
  
  CLTask<T> = sealed class(CLTaskBase)
    protected q: CommandQueue<T>;
    protected q_res: T;
    
    public property OrgQueue: CommandQueue<T> read q; reintroduce;
    protected function OrgQueueBase: CommandQueueBase; override;
    
    private procedure RegisterWaitables(q: CommandQueue<T>);
    private function InvokeQueue(q: CommandQueue<T>; c: Context; var cq: cl_command_queue): QueueRes<T>;
    protected constructor(q: CommandQueue<T>; c: Context);
    begin
      self.q := q;
      self.org_c := c;
      RegisterWaitables(q);
      
      var cq: cl_command_queue;
      var qr := InvokeQueue(q, c, cq);
      
      // mu выполняют лишний .Retain, чтобы ивент не удалился пока очередь ещё запускается
      foreach var mu_qr in mu_res.Values do
        mu_qr.ev.Release;
      mu_res := nil;
      
      //CQ.Invoke всегда выполняет UserEvent.EnsureAbortability, поэтому тут оно не нужно
      qr.ev.AttachFinallyCallback(()->
      begin
        if cq<>cl_command_queue.Zero then
          System.Threading.Tasks.Task.Run(()->self.AddErr( cl.ReleaseCommandQueue(cq) ));
        OnQDone(qr);
      end, self, c.Native, c.MainDevice.Native, cq);
      
    end;
    
    {$region CLTask event's}
    
    protected EvDone := new List<Action<CLTask<T>>>;
    public procedure WhenDone(cb: Action<CLTask<T>>); reintroduce :=
    if AddEventHandler(EvDone, cb) then cb(self);
    protected procedure WhenDoneBase(cb: Action<CLTaskBase>); override :=
    WhenDone(cb as object as Action<CLTask<T>>); //ToDo #2221
    
    protected EvComplete := new List<Action<CLTask<T>, T>>;
    public procedure WhenComplete(cb: Action<CLTask<T>, T>); reintroduce :=
    if AddEventHandler(EvComplete, cb) then cb(self, q_res);
    protected procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); override :=
    WhenComplete(cb as object as Action<CLTask<T>, T>); //ToDo #2221
    
    protected EvError := new List<Action<CLTask<T>, array of Exception>>;
    public procedure WhenError(cb: Action<CLTask<T>, array of Exception>); reintroduce :=
    if AddEventHandler(EvError, cb) then cb(self, GetErrArr);
    protected procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); override :=
    WhenError(cb as object as Action<CLTask<T>, array of Exception>); //ToDo #2221
    
    {$endregion CLTask event's}
    
    {$region Execution}
    
    private procedure OnQDone(qr: QueueRes<T>);
    begin
      var l_EvDone:     array of Action<CLTask<T>>;
      var l_EvComplete: array of Action<CLTask<T>, T>;
      var l_EvError:    array of Action<CLTask<T>, array of Exception>;
      
      lock wh_lock do
      try
        
        l_EvDone      := EvDone.ToArray;
        l_EvComplete  := EvComplete.ToArray;
        l_EvError     := EvError.ToArray;
        
        if err_lst.Count=0 then self.q_res := qr.GetRes;
      finally
        wh.Set;
      end;
      
      qr.ev.Release(self);
      
      foreach var ev in l_EvDone do
      try
        ev(self);
      except
        on e: Exception do AddErr(e);
      end;
      
      if err_lst.Count=0 then
      begin
        
        foreach var ev in l_EvComplete do
        try
          ev(self, self.q_res);
        except
          on e: Exception do AddErr(e);
        end;
        
      end else
      if l_EvError.Length<>0 then
      begin
        var err_arr := GetErrArr;
        
        foreach var ev in l_EvError do
        try
          ev(self, err_arr);
        except
          on e: Exception do AddErr(e);
        end;
        
      end;
      
    end;
    
    public function WaitRes: T; reintroduce;
    begin
      Wait;
      Result := self.q_res;
    end;
    protected function WaitResBase: object; override := WaitRes;
    
    {$endregion Execution}
    
  end;
  
  {$endregion CLTask}
  
  {$region CommandQueue}
  
  {$region Base}
  
  CommandQueueBase = abstract class
    
    {$region Invoke}
    
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; abstract;
    
    protected function InvokeNewQBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueResBase; abstract;
    
    {$endregion Invoke}
    
    {$region MW}
    
    private waiters_c := 0;
    private function IsWaitable := waiters_c<>0;
    private procedure MakeWaitable := lock self do waiters_c += 1;
    private procedure UnMakeWaitable := lock self do waiters_c -= 1;
    
    /// добавляет tsk в качестве ключа для всех ожидаемых очередей
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
    private mw_evs := new Dictionary<CLTaskBase, MWEventContainer>;
    private procedure RegisterWaiterTask(tsk: CLTaskBase) :=
    lock mw_evs do if not mw_evs.ContainsKey(tsk) then
    begin
      mw_evs[tsk] := new MWEventContainer;
      tsk.WhenDone(tsk->lock mw_evs do mw_evs.Remove(tsk));
    end;
    
    private procedure AddMWHandler(tsk: CLTaskBase; handler: ()->boolean);
    begin
      var cont: MWEventContainer;
      lock mw_evs do cont := mw_evs[tsk];
      cont.AddHandler(handler);
    end;
    
    private procedure ExecuteMWHandlers;
    begin
      var conts: array of MWEventContainer;
      lock mw_evs do conts := mw_evs.Values.ToArray;
      for var i := 0 to conts.Length-1 do conts[i].ExecuteHandler;
    end;
    
    {$endregion MW}
    
    {$region ConstQueue}
    
    public static function operator implicit(o: object): CommandQueueBase;
    
    {$endregion ConstQueue}
    
    {$region Cast}
    
    public function Cast<T>: CommandQueue<T>;
    
    {$endregion}
    
    {$region ThenConvert}
    
    public function ThenConvertBase<TOtp>(f: object->TOtp): CommandQueue<TOtp> := ThenConvertBase((o,c)->f(o));
    public function ThenConvertBase<TOtp>(f: (object, Context)->TOtp): CommandQueue<TOtp>; abstract;
    
    //ToDo
//    public function ThenConvert<TOtp>(f: object->TOtp): CommandQueue<TOtp> := ThenConvert((o,c)->f(o));
//    public function ThenConvert<TOtp>(f: (object, Context)->TOtp): CommandQueue<TOtp>;
    
    {$endregion ThenConvert}
    
    {$region +/*}
    
    private function AfterQueueSyncBase(q: CommandQueueBase): CommandQueueBase; abstract;
    private function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; abstract;
    
    public static function operator+(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueSyncBase(q1);
    public static function operator*(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueAsyncBase(q1);
    
    public static procedure operator+=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1*q2;
    
    {$endregion +/*}
    
    {$region Multiusable}
    
    public function MultiusableBase: ()->CommandQueueBase; abstract;
    
    //ToDo
//    public function Multiusable: ()->CommandQueueBase := MultiusableBase;
    
    {$endregion Multiusable}
    
    {$region ThenWait}
    
    public function ThenWaitForAllBase(qs: sequence of CommandQueueBase): CommandQueueBase; abstract;
    public function ThenWaitForAnyBase(qs: sequence of CommandQueueBase): CommandQueueBase; abstract;
    
    public function ThenWaitForAllBase(params qs: array of CommandQueueBase): CommandQueueBase := ThenWaitForAllBase(qs.AsEnumerable);
    public function ThenWaitForAnyBase(params qs: array of CommandQueueBase): CommandQueueBase := ThenWaitForAnyBase(qs.AsEnumerable);
    public function ThenWaitForBase(q: CommandQueueBase) := ThenWaitForAllBase(q);
    
    //ToDo
//    public function ThenWaitForAll(params qs: array of CommandQueueBase) := ThenWaitForAllBase(qs);
//    public function ThenWaitForAll(qs: sequence of CommandQueueBase    ) := ThenWaitForAllBase(qs);
//    
//    public function ThenWaitForAny(params qs: array of CommandQueueBase) := ThenWaitForAnyBase(qs);
//    public function ThenWaitForAny(qs: sequence of CommandQueueBase    ) := ThenWaitForAnyBase(qs);
//    
//    public function ThenWaitFor(q: CommandQueueBase) := ThenWaitForAll(q);
    
    {$endregion ThenWait}
    
  end;
  CommandQueue<T> = abstract class(CommandQueueBase)
    
    {$region Invoke}
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>;
    begin
      Result := InvokeImpl(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev).EnsureAbortability(tsk, c);
      
      if self.IsWaitable then
        Result.ev.AttachCallback(self.ExecuteMWHandlers, tsk, c.Native, main_dvc, cq);
      
    end;
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; override :=
    Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    
    protected function InvokeNewQ(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueRes<T>;
    begin
      var cq := cl_command_queue.Zero;
      Result := Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      
      // Result.ev.abortable уже true, потому что .EnsureAbortability в Invoke
      if cq<>cl_command_queue.Zero then
        Result.ev.AttachFinallyCallback(()->
        begin
          System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(cq)))
        end, tsk, c.Native, main_dvc, cq);
      
    end;
    protected function InvokeNewQBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueResBase; override :=
    InvokeNewQ(tsk, c, main_dvc, need_ptr_qr, prev_ev);
    
    {$endregion Invoke}
    
    {$region ConstQueue}
    
    public static function operator implicit(o: T): CommandQueue<T>;
    
    {$endregion ConstQueue}
    
    {$region ThenConvert}
    
    public function ThenConvert<TOtp>(f: T->TOtp): CommandQueue<TOtp>;
    public function ThenConvert<TOtp>(f: (T, Context)->TOtp): CommandQueue<TOtp>;
    
    ///--
    public function ThenConvertBase<TOtp>(f: (object, Context)->TOtp): CommandQueue<TOtp>; override :=
    ThenConvert(f as object as Func2<T, Context, TOtp>);
    
    {$endregion ThenConvert}
    
    {$region +/*}
    
    public static function operator+(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    public static function operator*(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    
    protected function AfterQueueSyncBase (q: CommandQueueBase): CommandQueueBase; override := q+self;
    protected function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; override := q*self;
    
    public static procedure operator+=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1*q2;
    
    {$endregion +/*}
    
    {$region Multiusable}
    
    public function Multiusable: ()->CommandQueue<T>;
    ///--
    public function MultiusableBase: ()->CommandQueueBase; override := Multiusable as object as Func<CommandQueueBase>; //ToDo #2221
    
    {$endregion Multiusable}
    
    {$region ThenWait}
    
    public function ThenWaitForAll(params qs: array of CommandQueueBase): CommandQueue<T> := ThenWaitForAll(qs.AsEnumerable);
    public function ThenWaitForAll(qs: sequence of CommandQueueBase): CommandQueue<T>;
    ///--
    public function ThenWaitForAllBase(qs: sequence of CommandQueueBase): CommandQueueBase; override := ThenWaitForAll(qs);
    
    public function ThenWaitForAny(params qs: array of CommandQueueBase): CommandQueue<T> := ThenWaitForAny(qs.AsEnumerable);
    public function ThenWaitForAny(qs: sequence of CommandQueueBase): CommandQueue<T>;
    ///--
    public function ThenWaitForAnyBase(qs: sequence of CommandQueueBase): CommandQueueBase; override := ThenWaitForAny(qs);
    
    public function ThenWaitFor(q: CommandQueueBase) := ThenWaitForAll(q);
    
    {$endregion ThenWait}
    
  end;
  
  {$endregion Base}
  
  {$region Host}
  
  /// очередь, выполняющая какую то работу на CPU, всегда в отдельном потоке
  HostQueue<TInp,TRes> = abstract class(CommandQueue<TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TInp>; abstract;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; abstract;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TRes>; override;
    begin
      var prev_qr := InvokeSubQs(tsk, c, main_dvc, cq, prev_ev);
      
      var qr := QueueResDelayedBase&<TRes>.MakeNew(need_ptr_qr);
      qr.ev := UserEvent.StartBackgroundWork(prev_qr.ev, ()->qr.SetRes( ExecFunc(prev_qr.GetRes(), c) ), c.Native, tsk);
      
      Result := qr;
    end;
    
  end;
  
  {$endregion Host}
  
  {$region Const}
  
  IConstQueue = interface
    function GetConstVal: Object;
  end;
  ConstQueue<T> = sealed class(CommandQueue<T>, IConstQueue)
    private res: T;
    
    public constructor(o: T) :=
    self.res := o;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public function IConstQueue.GetConstVal: object := self.res;
    public property Val: T read self.res;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      if prev_ev=nil then prev_ev := new EventList;
      
      if need_ptr_qr then
        Result := new QueueResDelayedPtr<T> (self.res, prev_ev) else
        Result := new QueueResConst<T>      (self.res, prev_ev);
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
  end;
  
  {$endregion Const}
  
  {$region Array}
  
  {$region Simple}
  
  ISimpleQueueArray = interface
    function GetQS: array of CommandQueueBase;
  end;
  SimpleQueueArray<T> = abstract class(CommandQueue<T>, ISimpleQueueArray)
    protected qs: array of CommandQueueBase;
    
    public constructor(params qs: array of CommandQueueBase) := self.qs := qs;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public function GetQS: array of CommandQueueBase := qs;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    foreach var q in qs do q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
  ISimpleSyncQueueArray = interface(ISimpleQueueArray) end;
  SimpleSyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleSyncQueueArray)
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      
      for var i := 0 to qs.Length-2 do
        prev_ev := qs[i].InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).ev;
      
      Result := (qs[qs.Length-1] as CommandQueue<T>).Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    end;
    
  end;
  
  ISimpleAsyncQueueArray = interface(ISimpleQueueArray) end;
  SimpleAsyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleAsyncQueueArray)
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      var evs := new EventList[qs.Length];
      
      for var i := 0 to qs.Length-2 do
      begin
        if prev_ev<>nil then prev_ev.Retain;
        evs[i] := qs[i].InvokeNewQBase(tsk, c, main_dvc, false, prev_ev).ev;
      end;
      
      if prev_ev<>nil then prev_ev.Retain;
      // Используем внешнюю cq, чтобы не создавать лишнюю
      Result := (qs[qs.Length-1] as CommandQueue<T>).Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      evs[evs.Length-1] := Result.ev;
      if prev_ev<>nil then prev_ev.Release;
      
      Result := Result.TrySetEv( EventList.Combine(evs, tsk, c.Native, main_dvc, cq) ?? new EventList );
    end;
    
  end;
  
  {$endregion Simple}
  
  {$region Conv}
  
  {$region Generic}
  
  ConvQueueArrayBase<TInp, TRes> = abstract class(HostQueue<array of TInp, TRes>)
    protected qs: array of CommandQueue<TInp>;
    protected f: Func<array of TInp, Context, TRes>;
    
    public constructor(qs: array of CommandQueue<TInp>; f: Func<array of TInp, Context, TRes>);
    begin
      self.qs := qs;
      self.f := f;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    foreach var q in qs do q.RegisterWaitables(tsk, prev_hubs);
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
  ConvSyncQueueArray<TInp, TRes> = sealed class(ConvQueueArrayBase<TInp, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<array of TInp>; override;
    begin
      var qrs := new QueueRes<TInp>[qs.Length];
      
      for var i := 0 to qs.Length-1 do
      begin
        var qr := qs[i].Invoke(tsk, c, main_dvc, false, cq, prev_ev);
        prev_ev := qr.ev;
        qrs[i] := qr;
      end;
      
      Result := new QueueResFunc<array of TInp>(()->
      begin
        Result := new TInp[qrs.Length];
        for var i := 0 to qrs.Length-1 do
          Result[i] := qrs[i].GetRes;
      end, prev_ev);
    end;
    
  end;
  ConvAsyncQueueArray<TInp, TRes> = sealed class(ConvQueueArrayBase<TInp, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<array of TInp>; override;
    begin
      var qrs := new QueueRes<TInp>[qs.Length];
      var evs := new EventList[qs.Length];
      
      for var i := 0 to qs.Length-2 do
      begin
        if prev_ev<>nil then prev_ev.Retain;
        var qr := qs[i].InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
        qrs[i] := qr;
        evs[i] := qr.ev;
      end;
      
      if prev_ev<>nil then prev_ev.Retain;
      // Отдельно, чтобы не создавать лишнюю cq
      var qr := qs[qs.Length-1].Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      qrs[evs.Length-1] := qr;
      evs[evs.Length-1] := qr.ev;
      if prev_ev<>nil then prev_ev.Release;
      
      Result := new QueueResFunc<array of TInp>(()->
      begin
        Result := new TInp[qrs.Length];
        for var i := 0 to qrs.Length-1 do
          Result[i] := qrs[i].GetRes;
      end, EventList.Combine(evs, tsk, c.Native, main_dvc, cq) ?? new EventList);
    end;
    
  end;
  
  {$endregion Generic}
  
  {%ConvQueueStaticArray!ConvQueueStaticArray.pas%}
  
  {$endregion Conv}
  
  {$region Utils}
  
  QueueArrayUtils = static class
    
    public static function FlattenQueueArray<T>(inp: sequence of CommandQueueBase): array of CommandQueueBase; where T: ISimpleQueueArray;
    begin
      var enmr := inp.GetEnumerator;
      if not enmr.MoveNext then raise new InvalidOperationException('%Err:FlattenQueueArray:InpEmpty%');
      
      var res := new List<CommandQueueBase>;
      while true do
      begin
        var curr := enmr.Current;
        var next := enmr.MoveNext;
        
        if not (curr is IConstQueue) or not next then
          if curr as object is T(var sqa) then //ToDo #2146
            res.AddRange(sqa.GetQS) else
            res += curr;
        
        if not next then break;
      end;
      
      Result := res.ToArray;
    end;
    
    public static function  FlattenSyncQueueArray(inp: sequence of CommandQueueBase) := FlattenQueueArray&< ISimpleSyncQueueArray>(inp);
    public static function FlattenAsyncQueueArray(inp: sequence of CommandQueueBase) := FlattenQueueArray&<ISimpleAsyncQueueArray>(inp);
    
  end;
  
  {$endregion}
  
  {$endregion Array}
  
  {$endregion CommandQueue}
  
  {$region GPUCommandContainer's}
  
  {$region Base}
  
  GPUCommand<T> = abstract class
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; abstract;
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
  end;
  
  GPUCommandContainer<T> = class;
  GPUCommandContainerBody<T> = abstract class
    private cc: GPUCommandContainer<T>;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
  end;
  
  GPUCommandContainer<T> = abstract class(CommandQueue<T>)
    protected body: GPUCommandContainerBody<T>;
    protected commands := new List<GPUCommand<T>>;
    
    {$region def}
    
    protected procedure InitObj(obj: T; c: Context); virtual := exit;
    
    {$endregion def}
    
    {$region Common}
    
    protected constructor(o: T);
    protected constructor(q: CommandQueue<T>);
    
    {$endregion Common}
    
    {$region sub implementation}
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override :=
    body.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      body.RegisterWaitables(tsk, prev_hubs);
      foreach var comm in commands do comm.RegisterWaitables(tsk, prev_hubs);
    end;
    
    {$endregion sub implementation}
    
    {$region reintroduce методы}
    
    //ToDo #2145
    ///--
    public function Equals(obj: object): boolean; reintroduce := inherited Equals(obj);
    ///--
    public function ToString: string; reintroduce := inherited ToString();
    ///--
    public function GetType: System.Type; reintroduce := inherited GetType();
    ///--
    public function GetHashCode: integer; reintroduce := inherited GetHashCode();
    
    {$endregion reintroduce методы}
    
  end;
  
  {$endregion Base}
  
  {$region BufferCommandQueue}
  
  BufferCommandQueue = sealed class(GPUCommandContainer<Buffer>)
    
    {$region constructor's}
    
    protected procedure InitObj(obj: Buffer; c: Context); override := obj.InitIfNeed(c);
    protected static function InitBuffer(b: Buffer; c: Context): Buffer;
    begin
      b.InitIfNeed(c);
      Result := b;
    end;
    
    public constructor(b: Buffer) := inherited;
    public constructor(q: CommandQueue<Buffer>) :=
    inherited Create(q.ThenConvert(InitBuffer));
    
    {$endregion constructor's}
    
    {$region Utils}
    
    protected function AddCommand(comm: GPUCommand<Buffer>): BufferCommandQueue;
    begin
      self.commands += comm;
      Result := self;
    end;
    
    {$endregion Utils}
    
    {$region Non-command add's}
    
    {$region Queue}
    
    public function AddQueue(q: CommandQueueBase): BufferCommandQueue;
    
    {$endregion Queue}
    
    {$region Proc}
    
    public function AddProc(p: Buffer->()): BufferCommandQueue;
    public function AddProc(p: (Buffer, Context)->()): BufferCommandQueue;
    
    {$endregion Proc}
    
    {$region Wait}
    
    public function AddWaitAll(params qs: array of CommandQueueBase): BufferCommandQueue := AddWaitAll(qs.AsEnumerable);
    public function AddWaitAll(qs: sequence of CommandQueueBase): BufferCommandQueue;
    
    public function AddWaitAny(params qs: array of CommandQueueBase): BufferCommandQueue := AddWaitAny(qs.AsEnumerable);
    public function AddWaitAny(qs: sequence of CommandQueueBase): BufferCommandQueue;
    
    public function AddWait(q: CommandQueueBase) := AddWaitAll(q);
    
    {$endregion Wait}
    
    {$endregion Non-command add's}
    
    {%BufferMethods.Explicit.Interface!MethodGen.pas%}
    
    {%BufferGetMethods.Explicit.Interface!GetMethodGen.pas%}
    
  end;
  
  {$endregion BufferCommandQueue}
  
  {$region KernelCommandQueue}
  
  KernelCommandQueue = sealed class(GPUCommandContainer<Kernel>)
    
    {$region constructor's}
    
    public constructor(k: Kernel) := inherited;
    public constructor(q: CommandQueue<Kernel>) := inherited;
    
    {$endregion constructor's}
    
    {$region Utils}
    
    protected function AddCommand(comm: GPUCommand<Kernel>): KernelCommandQueue;
    begin
      self.commands += comm;
      Result := self;
    end;
    
    {$endregion Utils}
    
    {$region Non-command add's}
    
    {$region Queue}
    
    public function AddQueue(q: CommandQueueBase): KernelCommandQueue;
    
    {$endregion Queue}
    
    {$region Proc}
    
    public function AddProc(p: Kernel->()): KernelCommandQueue;
    public function AddProc(p: (Kernel, Context)->()): KernelCommandQueue;
    
    {$endregion Proc}
    
    {$region Wait}
    
    public function AddWaitAll(params qs: array of CommandQueueBase): KernelCommandQueue := AddWaitAll(qs.AsEnumerable);
    public function AddWaitAll(qs: sequence of CommandQueueBase): KernelCommandQueue;
    
    public function AddWaitAny(params qs: array of CommandQueueBase): KernelCommandQueue := AddWaitAny(qs.AsEnumerable);
    public function AddWaitAny(qs: sequence of CommandQueueBase): KernelCommandQueue;
    
    public function AddWait(q: CommandQueueBase) := AddWaitAll(q);
    
    {$endregion Wait}
    
    {$endregion Non-command add's}
    
    {%KernelMethods.Explicit.Interface!MethodGen.pas%}
    
  end;
  
  {$endregion KernelCommandQueue}
  
  {$endregion GPUCommandContainer's}
  
  {$region Enqueueable's}
  
  EnqueueableGPUCommand<T> = abstract class(GPUCommand<T>)
    
    // Если это True - InvokeParams должен возращать (...)->cl_event.Zero
    // Иначе останется ивент, который никто не удалил
    protected function NeedThread: boolean; virtual := false;
    
    private function MakeEvList(exp_size: integer; start_ev: EventList): List<EventList>;
    begin
      var need_start_ev := (start_ev<>nil) and (start_ev.count<>0);
      Result := new List<EventList>(exp_size + integer(need_start_ev));
      if need_start_ev then Result += start_ev;
    end;
    protected function ParamCountL1: integer; abstract;
    protected function ParamCountL2: integer; abstract;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (T, cl_command_queue, CLTaskBase, Context, EventList)->cl_event; abstract;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_qr: QueueRes<T>; l2_start_ev: EventList): EventList;
    begin
      var need_thread := self.NeedThread;
      
      var evs_l1 := MakeEvList(ParamCountL1, prev_qr.ev); // ожидание до Enqueue
      var evs_l2 := MakeEvList(ParamCountL2, l2_start_ev); // ожидание, передаваемое в Enqueue
      
      var enq_f := InvokeParams(tsk, c, main_dvc, cq, evs_l1, evs_l2);
      var ev_l1 := EventList.Combine(evs_l1, tsk, c.Native, main_dvc, cq);
      var ev_l2 := EventList.Combine(evs_l2, tsk, c.Native, main_dvc, cq) ?? new EventList;
      
      NativeUtils.FixCQ(c.Native, main_dvc, cq);
      
      if not need_thread and (ev_l1=nil) then
      begin
        Result := enq_f(prev_qr.GetRes, cq, tsk, c, ev_l2);
        Result.abortable := true; // ev_l2 тут всегда напрямую передаётся в cl.Enqueue*... и ev_l2.abortable всегда true
        //ToDo С другой стороны, если ev_l2 абортится - получаем CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST в качестве статуса
        // - Надо бы проверить как это всё работает
      end else
      begin
        var res_ev: UserEvent;
        
        // Асинхронное Enqueue, придётся пересоздать cq
        var lcq := cq;
        cq := cl_command_queue.Zero;
        
        if need_thread then
          res_ev := UserEvent.StartBackgroundWork(ev_l1, ()->enq_f(prev_qr.GetRes, lcq, tsk, c, ev_l2), c.Native, tsk) else
        begin
          res_ev := tsk.MakeUserEvent(c.Native);
          
          //ВНИМАНИЕ "ev_l1=nil" не может случится, из за условий выше
          ev_l1.AttachCallback(()->
          begin
            ev_l1.Release;
            var enq_ev := enq_f(prev_qr.GetRes, lcq, tsk, c, ev_l2);
            EventList.AttachCallback(enq_ev, ()->res_ev.SetStatus(CommandExecutionStatus.COMPLETE), tsk);
          end, tsk, c.Native, main_dvc, lcq);
          
        end;
        
        EventList.AttachFinallyCallback(res_ev, ()->
        begin
          System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(lcq)));
        end, tsk);
        Result := res_ev; //ВНИМАНИЕ: "Result.abortable" тут установлено автоматически
      end;
      
    end;
    
    protected function InvokeObj(o: T; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    Invoke(tsk, c, main_dvc, cq, new QueueResConst<T>(o, nil), prev_ev);
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    Invoke(tsk, c, main_dvc, cq, o_q().Invoke(tsk, c, main_dvc, false, cq, prev_ev), nil);
    
  end;
  
  EnqueueableGetCommand<TObj, TRes> = abstract class(CommandQueue<TRes>)
    protected prev_commands: GPUCommandContainer<TObj>;
    
    public constructor(prev_commands: GPUCommandContainer<TObj>) :=
    self.prev_commands := prev_commands;
    
    // Если это True - InvokeParams должен возращать (...)->cl_event.Zero
    // Иначе останется ивент, который никто не удалил
    protected function NeedThread: boolean; virtual := false;
    
    protected function ForcePtrQr: boolean; virtual := false;
    
    private function MakeEvList(exp_size: integer; start_ev: EventList): List<EventList>;
    begin
      var need_start_ev := (start_ev<>nil) and (start_ev.count<>0);
      Result := new List<EventList>(exp_size + integer(need_start_ev));
      if need_start_ev then Result += start_ev;
    end;
    protected function ParamCountL1: integer; abstract;
    protected function ParamCountL2: integer; abstract;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (TObj, cl_command_queue, CLTaskBase, EventList, QueueResDelayedBase<TRes>)->cl_event; abstract;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TRes>; override;
    begin
      var need_thread := self.NeedThread;
      var prev_qr := prev_commands.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      
      var evs_l1 := MakeEvList(ParamCountL1, prev_qr.ev); // ожидание до Enqueue
      var evs_l2 := MakeEvList(ParamCountL2, nil); // ожидание, передаваемое в Enqueue
      
      var enq_f := InvokeParams(tsk, c, main_dvc, cq, evs_l1, evs_l2);
      var ev_l1 := EventList.Combine(evs_l1, tsk, c.Native, main_dvc, cq);
      var ev_l2 := EventList.Combine(evs_l2, tsk, c.Native, main_dvc, cq) ?? new EventList;
      
      NativeUtils.FixCQ(c.Native, main_dvc, cq);
      
      var qr := QueueResDelayedBase&<TRes>.MakeNew(need_ptr_qr or ForcePtrQr);
      Result := qr;
      
      if not need_thread and (ev_l1=nil) then
      begin
        Result.ev := enq_f(prev_qr.GetRes, cq, tsk, ev_l2, qr);
        Result.ev.abortable := true; //ToDo та же история что выше
      end else
      begin
        var res_ev: UserEvent;
        
        // Асинхронное Enqueue, придётся пересоздать cq
        var lcq := cq;
        cq := cl_command_queue.Zero;
        
        if need_thread then
          res_ev := UserEvent.StartBackgroundWork(ev_l1, ()->enq_f(prev_qr.GetRes, lcq, tsk, ev_l2, qr), c.Native, tsk) else
        begin
          res_ev := tsk.MakeUserEvent(c.Native);
          
          //ВНИМАНИЕ "ev_l1=nil" не может случится, из за условий выше
          ev_l1.AttachCallback(()->
          begin
            ev_l1.Release;
            var enq_ev := enq_f(prev_qr.GetRes, lcq, tsk, ev_l2, qr);
            EventList.AttachCallback(enq_ev, ()->res_ev.SetStatus(CommandExecutionStatus.COMPLETE), tsk);
          end, tsk, c.Native, main_dvc, lcq);
          
        end;
        
        EventList.AttachFinallyCallback(res_ev, ()->
        begin
          System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(lcq)));
        end, tsk);
        Result.ev := res_ev; //ВНИМАНИЕ: "Result.abortable" тут установлено автоматически
      end;
      
    end;
    
  end;
  
  {$endregion Enqueueable's}
  
  {$region KernelArg}
  
  ISetableKernelArg = interface
    procedure SetArg(k: cl_kernel; ind: UInt32; c: Context);
  end;
  KernelArg = abstract class
    
    {$region Def}
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
    {$endregion Def}
    
    {$region Buffer}
    
    public static function FromBuffer(b: Buffer): KernelArg;
    public static function operator implicit(b: Buffer): KernelArg := FromBuffer(b);
    
    public static function FromBufferCQ(bq: CommandQueue<Buffer>): KernelArg;
    public static function operator implicit(bq: CommandQueue<Buffer>): KernelArg := FromBufferCQ(bq);
    public static function operator implicit(bq: BufferCommandQueue): KernelArg := FromBufferCQ(bq as CommandQueue<Buffer>);
    
    {$endregion Buffer}
    
    {$region Record}
    
    public static function FromRecord<TRecord>(val: TRecord): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(val: TRecord): KernelArg; where TRecord: record; begin Result := FromRecord(val); end;
    
    public static function FromRecordCQ<TRecord>(valq: CommandQueue<TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(valq: CommandQueue<TRecord>): KernelArg; where TRecord: record; begin Result := FromRecordCQ(valq); end;
    
    {$endregion Record}
    
    {$region Ptr}
    
    public static function FromPtr(ptr: IntPtr; sz: UIntPtr): KernelArg;
    
    public static function FromPtrCQ(ptr_q: CommandQueue<IntPtr>; sz_q: CommandQueue<UIntPtr>): KernelArg;
    
    public static function FromRecordPtr<TRecord>(ptr: ^TRecord): KernelArg; where TRecord: record; begin Result := FromPtr(new IntPtr(ptr), new UIntPtr(Marshal.SizeOf&<TRecord>)); end;
    public static function operator implicit<TRecord>(ptr: ^TRecord): KernelArg; where TRecord: record; begin Result := FromRecordPtr(ptr); end;
    
    {$endregion Ptr}
    
  end;
  
  {$endregion KernelArg}
  
  {$region WCQWaiter}
  
  WCQWaiter = abstract class
    private waitables: array of CommandQueueBase;
    
    public constructor(waitables: array of CommandQueueBase);
    begin
      foreach var q in waitables do q.MakeWaitable;
      self.waitables := waitables;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure RegisterWaitables(tsk: CLTaskBase) :=
    foreach var q in waitables do q.RegisterWaiterTask(tsk);
    
    public function GetWaitEv(tsk: CLTaskBase; c: Context): UserEvent; abstract;
    
    protected procedure Finalize; override :=
    foreach var q in waitables do q.UnMakeWaitable;
    
  end;
  
  WCQWaiterAll = sealed class(WCQWaiter)
    
    public function GetWaitEv(tsk: CLTaskBase; c: Context): UserEvent; override;
    begin
      var uev := tsk.MakeUserEvent(c.Native);
      
      var done := 0;
      var total := waitables.Length;
      var done_lock := new object;
      
      for var i := 0 to waitables.Length-1 do
        waitables[i].AddMWHandler(tsk, ()->
        begin
          if uev.CanRemove then exit;
          
          lock done_lock do
          begin
            done += 1;
            if done=total then
              // Если uev.Abort вызовет между .CanRemove и этой строчкой - значит это было в отдельном потоке,
              // т.е. в заведомо не_безопастном месте. А значит проверять тут - нет смысла
              uev.SetStatus(CommandExecutionStatus.COMPLETE);
          end;
          
          Result := true;
        end);
      
      Result := uev;
    end;
    
  end;
  WCQWaiterAny = sealed class(WCQWaiter)
    
    public function GetWaitEv(tsk: CLTaskBase; c: Context): UserEvent; override;
    begin
      var uev := tsk.MakeUserEvent(c.Native);
      
      for var i := 0 to waitables.Length-1 do
        waitables[i].AddMWHandler(tsk, ()->uev.SetStatus(CommandExecutionStatus.COMPLETE));
      
      Result := uev;
    end;
    
  end;
  
  {$endregion WCQWaiter}
  
implementation

{$region DelayedImpl}

{$region Device}

function Device.Split(props: array of DevicePartitionProperty): array of SubDevice;
begin
  
  var c: UInt32;
  cl.CreateSubDevices(self.Native, props, 0, IntPtr.Zero, c).RaiseIfError;
  
  var res := new cl_device_id[int64(c)];
  cl.CreateSubDevices(self.Native, props, c, res[0], IntPtr.Zero).RaiseIfError;
  
  Result := res.ConvertAll(sdvc->new SubDevice(sdvc, self));
end;

{$endregion Device}

{$region Buffer}

function Buffer.NewQueue := new BufferCommandQueue(self);

{$endregion Buffer}

{$region Kernel}

function Kernel.NewQueue := new KernelCommandQueue(self);

{$endregion Kernel}

{$region EventList}

static function EventList.Combine(evs: IList<EventList>; tsk: CLTaskBase; c: cl_context; main_dvc: cl_device_id; var cq: cl_command_queue): EventList;
begin
  var count := 0;
  var need_abort_ev := true;
  
  for var i := 0 to evs.Count-1 do
  begin
    count += evs[i].count;
    if need_abort_ev and evs[i].abortable then need_abort_ev := false;
  end;
  if count=0 then exit;
  
  Result := new EventList(count + integer(need_abort_ev));
  
  for var i := 0 to evs.Count-1 do
    Result += evs[i];
  
  if need_abort_ev then
  begin
    var uev := tsk.MakeUserEvent(c);
    Result.AttachCallback(()->begin uev.SetStatus(CommandExecutionStatus.COMPLETE) end, tsk, c, main_dvc, cq); //ToDo лишний begin-end
    Result += cl_event(uev);
    Result.abortable := true;
  end;
  
end;

{$endregion EventList}

{$region QueueRes}

static function QueueResDelayedBase<T>.MakeNew(need_ptr_qr: boolean) := need_ptr_qr ?
new QueueResDelayedPtr<T> as QueueResDelayedBase<T> :
new QueueResDelayedObj<T> as QueueResDelayedBase<T>;

{$endregion QueueRes}

{$region UserEvent}

static function UserEvent.MakeUserEvent(tsk: CLTaskBase; c: cl_context) := tsk.MakeUserEvent(c);

{$endregion UserEvent}

{$region CLTask}

static procedure CLTaskExt.AddErr(tsk: CLTaskBase; e: Exception) := tsk.AddErr(e);
static function CLTaskExt.AddErr(tsk: CLTaskBase; ec: ErrorCode) := tsk.AddErr(ec);
static function CLTaskExt.AddErr(tsk: CLTaskBase; st: CommandExecutionStatus) := tsk.AddErr(st);

function CLTask<T>.OrgQueueBase: CommandQueueBase := self.OrgQueue;

procedure CLTask<T>.RegisterWaitables(q: CommandQueue<T>) := q.RegisterWaitables(self, new HashSet<MultiusableCommandQueueHubBase>);

function CLTask<T>.InvokeQueue(q: CommandQueue<T>; c: Context; var cq: cl_command_queue): QueueRes<T> :=
q.Invoke(self, c, c.MainDevice.Native, false, cq, nil);

{$endregion CLTask}

{$region CommandQueue}

static function CommandQueueBase.operator implicit(o: object): CommandQueueBase :=
new ConstQueue<object>(o);

static function CommandQueue<T>.operator implicit(o: T): CommandQueue<T> :=
new ConstQueue<T>(o);

{$endregion CommandQueue}

{$endregion DelayedImpl}

{$region CLTaskResLess}

type
  CLTaskResLess = sealed class(CLTaskBase)
    protected q: CommandQueueBase;
    protected q_res: object;
    
    protected function OrgQueueBase: CommandQueueBase; override := q;
    
    protected constructor(q: CommandQueueBase; c: Context);
    begin
      self.q := q;
      self.org_c := c;
      q.RegisterWaitables(self, new HashSet<MultiusableCommandQueueHubBase>);
      
      var cq: cl_command_queue;
      var qr := q.InvokeBase(self, c, c.MainDevice.Native, false, cq, nil);
      
      // mu выполняют лишний .Retain, чтобы ивент не удалился пока очередь ещё запускается
      foreach var mu_qr in mu_res.Values do
        mu_qr.ev.Release;
      mu_res := nil;
      
      //CQ.Invoke всегда выполняет UserEvent.EnsureAbortability, поэтому тут оно не нужно
      qr.ev.AttachFinallyCallback(()->
      begin
        if cq<>cl_command_queue.Zero then
          System.Threading.Tasks.Task.Run(()->self.AddErr( cl.ReleaseCommandQueue(cq) ));
        OnQDone(qr);
      end, self, c.Native, c.MainDevice.Native, cq);
      
    end;
    
    {$region CLTask event's}
    
    protected EvDone := new List<Action<CLTaskBase>>;
    protected procedure WhenDoneBase(cb: Action<CLTaskBase>); override :=
    if AddEventHandler(EvDone, cb) then cb(self);
    
    protected EvComplete := new List<Action<CLTaskBase, object>>;
    protected procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); override :=
    if AddEventHandler(EvComplete, cb) then cb(self, q_res);
    
    protected EvError := new List<Action<CLTaskBase, array of Exception>>;
    protected procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); override :=
    if AddEventHandler(EvError, cb) then cb(self, GetErrArr);
    
    {$endregion CLTask event's}
    
    {$region Execution}
    
    private procedure OnQDone(qr: QueueResBase);
    begin
      var l_EvDone:     array of Action<CLTaskBase>;
      var l_EvComplete: array of Action<CLTaskBase, object>;
      var l_EvError:    array of Action<CLTaskBase, array of Exception>;
      
      lock wh_lock do
      try
        
        l_EvDone      := EvDone.ToArray;
        l_EvComplete  := EvComplete.ToArray;
        l_EvError     := EvError.ToArray;
        
        if err_lst.Count=0 then self.q_res := qr.GetResBase;
      finally
        wh.Set;
      end;
      
      qr.ev.Release(self);
      
      foreach var ev in l_EvDone do
      try
        ev(self);
      except
        on e: Exception do AddErr(e);
      end;
      
      if err_lst.Count=0 then
      begin
        
        foreach var ev in l_EvComplete do
        try
          ev(self, self.q_res);
        except
          on e: Exception do AddErr(e);
        end;
        
      end else
      if l_EvError.Length<>0 then
      begin
        var err_arr := GetErrArr;
        
        foreach var ev in l_EvError do
        try
          ev(self, err_arr);
        except
          on e: Exception do AddErr(e);
        end;
        
      end;
      
    end;
    
    protected function WaitResBase: object; override;
    begin
      Wait;
      Result := q_res;
    end;
    
    {$endregion Execution}
    
  end;
  
function Context.BeginInvoke<T>(q: CommandQueue<T>) := new CLTask<T>(q, self);
function Context.BeginInvoke(q: CommandQueueBase) := new CLTaskResLess(q, self);

function Context.SyncInvoke<T>(q: CommandQueue<T>) := BeginInvoke(q).WaitRes;
function Context.SyncInvoke(q: CommandQueueBase) := BeginInvoke(q).WaitRes;

{$endregion CLTaskResLess}

{$region Queue converter's}

{$region Cast}

type
  CastQueue<T> = sealed class(CommandQueue<T>)
    private q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override :=
    q.InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).LazyQuickTransformBase(o->T(o));
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
function CommandQueueBase.Cast<T> := new CastQueue<T>(self);

{$endregion Cast}

{$region ThenConvert}

type
  CommandQueueThenConvert<TInp, TRes> = sealed class(HostQueue<TInp, TRes>)
    protected q: CommandQueue<TInp>;
    protected f: (TInp, Context)->TRes;
    
    public constructor(q: CommandQueue<TInp>; f: (TInp, Context)->TRes);
    begin
      self.q := q;
      self.f := f;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TInp>; override :=
    q.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
function CommandQueue<T>.ThenConvert<TOtp>(f: (T, Context)->TOtp) :=
new CommandQueueThenConvert<T, TOtp>(self, f);
function CommandQueue<T>.ThenConvert<TOtp>(f: T->TOtp) :=
new CommandQueueThenConvert<T, TOtp>(self, (o,c)->f(o));

{$endregion ThenConvert}

{$region QueueArray}

static function CommandQueue<T>.operator+(q1: CommandQueueBase; q2: CommandQueue<T>) := new SimpleSyncQueueArray<T>(q1, q2);
static function CommandQueue<T>.operator*(q1: CommandQueueBase; q2: CommandQueue<T>) := new SimpleAsyncQueueArray<T>(q1, q2);

{$endregion QueueArray}

{$region Multiusable}

type
  MultiusableCommandQueueHub<T> = sealed class(MultiusableCommandQueueHubBase)
    public q: CommandQueue<T>;
    public constructor(q: CommandQueue<T>) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public function OnNodeInvoked(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean): QueueRes<T>;
    begin
      
      var res_o: QueueResBase;
      if tsk.mu_res.TryGetValue(self, res_o) then
        Result := QueueRes&<T>( res_o ) else
      begin
        Result := self.q.InvokeNewQ(tsk, c, main_dvc, need_ptr_qr, nil);
        Result.can_set_ev := false;
        tsk.mu_res[self] := Result;
      end;
      
      Result.ev.Retain;
    end;
    
    public function MakeNode: CommandQueue<T>;
    
  end;
  
  MultiusableCommandQueueNode<T> = sealed class(CommandQueue<T>)
    public hub: MultiusableCommandQueueHub<T>;
    public constructor(hub: MultiusableCommandQueueHub<T>) := self.hub := hub;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := hub.OnNodeInvoked(tsk, c, main_dvc, need_ptr_qr);
      if prev_ev<>nil then Result := Result.TrySetEv( prev_ev + Result.ev );
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    if prev_hubs.Add(hub) then hub.q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
function MultiusableCommandQueueHub<T>.MakeNode :=
new MultiusableCommandQueueNode<T>(self);

function CommandQueue<T>.Multiusable: ()->CommandQueue<T> := MultiusableCommandQueueHub&<T>.Create(self).MakeNode;

{$endregion Multiusable}

{$region Wait}

type
  CommandQueueThenWaitFor<T> = sealed class(CommandQueue<T>)
    public q: CommandQueue<T>;
    public waiter: WCQWaiter;
    
    public constructor(q: CommandQueue<T>; waiter: WCQWaiter);
    begin
      self.q := q;
      self.waiter := waiter;
    end;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := q.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      Result := Result.TrySetEv( Result.ev + waiter.GetWaitEv(tsk, c) );
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      q.RegisterWaitables(tsk, prev_hubs);
      waiter.RegisterWaitables(tsk);
    end;
    
  end;
  
function CommandQueue<T>.ThenWaitForAll(qs: sequence of CommandQueueBase) :=
new CommandQueueThenWaitFor<T>(self, new WCQWaiterAll(qs.ToArray));

function CommandQueue<T>.ThenWaitForAny(qs: sequence of CommandQueueBase) :=
new CommandQueueThenWaitFor<T>(self, new WCQWaiterAny(qs.ToArray));

{$endregion Wait}

{$endregion Queue converter's}

{$region Special GPUCommand's}

{$region Queue}

type
  QueueCommand<T> = sealed class(GPUCommand<T>)
    public q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := q.InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).ev;
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := q.InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).ev;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
function BufferCommandQueue.AddQueue(q: CommandQueueBase) := AddCommand(new QueueCommand<Buffer>(q));
function KernelCommandQueue.AddQueue(q: CommandQueueBase) := AddCommand(new QueueCommand<Kernel>(q));

{$endregion Queue}

{$region Proc}

type
  ProcCommandBase<T> = abstract class(GPUCommand<T>)
    
    protected procedure ExecProc(o: T; c: Context); abstract;
    
    protected function InvokeObj(o: T; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    UserEvent.StartBackgroundWork(prev_ev, ()->ExecProc(o, c), c.Native, tsk);
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override;
    begin
      var o_q_res := o_q().Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      Result := UserEvent.StartBackgroundWork(o_q_res.ev, ()->ExecProc(o_q_res.GetRes(), c), c.Native, tsk);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
  end;
  ProcCommand<T> = sealed class(ProcCommandBase<T>)
    public p: T->();
    
    public constructor(p: T->()) := self.p := p;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure ExecProc(o: T; c: Context); override := p(o);
    
  end;
  ProcCommandC<T> = sealed class(ProcCommandBase<T>)
    public p: (T,Context)->();
    
    public constructor(p: (T,Context)->()) := self.p := p;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure ExecProc(o: T; c: Context); override := p(o, c);
    
    
  end;
  
function BufferCommandQueue.AddProc(p: Buffer->()) := AddCommand(new ProcCommand<Buffer>(p));
function KernelCommandQueue.AddProc(p: Kernel->()) := AddCommand(new ProcCommand<Kernel>(p));

function BufferCommandQueue.AddProc(p: (Buffer, Context)->()) := AddCommand(new ProcCommandC<Buffer>(p));
function KernelCommandQueue.AddProc(p: (Kernel, Context)->()) := AddCommand(new ProcCommandC<Kernel>(p));

{$endregion Proc}

{$region Wait}

type
  WaitCommand<T> = sealed class(GPUCommand<T>)
    public waiter: WCQWaiter;
    
    public constructor(waiter: WCQWaiter) :=
    self.waiter := waiter;
    
    private function Invoke(tsk: CLTaskBase; c: Context; prev_ev: EventList): EventList;
    begin
      if prev_ev=nil then
        Result := waiter.GetWaitEv(tsk, c) else
        Result := prev_ev + waiter.GetWaitEv(tsk, c);
    end;
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := Invoke(tsk, c, prev_ev);
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := Invoke(tsk, c, prev_ev);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    waiter.RegisterWaitables(tsk);
    
  end;
  
function BufferCommandQueue.AddWaitAll(qs: sequence of CommandQueueBase) := AddCommand(new WaitCommand<Buffer>(new WCQWaiterAll(qs.ToArray)));
function KernelCommandQueue.AddWaitAll(qs: sequence of CommandQueueBase) := AddCommand(new WaitCommand<Kernel>(new WCQWaiterAll(qs.ToArray)));

function BufferCommandQueue.AddWaitAny(qs: sequence of CommandQueueBase) := AddCommand(new WaitCommand<Buffer>(new WCQWaiterAny(qs.ToArray)));
function KernelCommandQueue.AddWaitAny(qs: sequence of CommandQueueBase) := AddCommand(new WaitCommand<Kernel>(new WCQWaiterAny(qs.ToArray)));

{$endregion Wait}

{$endregion Special GPUCommand's}

{$region GPUCommandContainerBody}

type
  CCBObj<T> = sealed class(GPUCommandContainerBody<T>)
    public o: T;
    
    public constructor(o: T; cc: GPUCommandContainer<T>);
    begin
      self.o := o;
      self.cc := cc;
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      var res_obj := self.o;
      cc.InitObj(res_obj, c);
      
      foreach var comm in cc.commands do
        prev_ev := comm.InvokeObj(res_obj, tsk, c, main_dvc, cq, prev_ev);
      
      Result := new QueueResConst<T>(res_obj, prev_ev ?? new EventList);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
  end;
  CCBQueue<T> = sealed class(GPUCommandContainerBody<T>)
    public hub: MultiusableCommandQueueHub<T>;
    
    public constructor(q: CommandQueue<T>; cc: GPUCommandContainer<T>);
    begin
      self.hub := new MultiusableCommandQueueHub<T>(q);
      self.cc := cc;
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      var new_plug: ()->CommandQueue<T> := hub.MakeNode;
      // new_plub всегда делает mu ноду, а она не использует prev_ev
      // это тут, чтобы хаб передал need_ptr_qr. Он делает это при первом Invoke
      Result := new_plug().Invoke(tsk, c, main_dvc, need_ptr_qr, cq, nil);
      
      foreach var comm in cc.commands do
        prev_ev := comm.InvokeQueue(new_plug, tsk, c, main_dvc, cq, prev_ev);
      
      Result := Result.TrySetEv( prev_ev ?? new EventList );
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    hub.q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
constructor GPUCommandContainer<T>.Create(o: T) :=
self.body := new CCBObj<T>(o, self);

constructor GPUCommandContainer<T>.Create(q: CommandQueue<T>) :=
self.body := new CCBQueue<T>(q, self);

{$endregion GPUCommandContainerBody}

{$region KernelArg}

{$region Const}

{$region Base}

type
  ConstKernelArg = abstract class(KernelArg, ISetableKernelArg)
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; override :=
    new QueueResConst<ISetableKernelArg>(self, new EventList);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); abstract;
    
  end;
  
{$endregion Base}

{$region Buffer}

type
  KernelArgBuffer = sealed class(ConstKernelArg)
    private b: Buffer;
    
    public constructor(b: Buffer) := self.b := b;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override;
    begin
      b.InitIfNeed(c);
      cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), b.ntv).RaiseIfError; 
    end;
    
  end;
  
static function KernelArg.FromBuffer(b: Buffer) := new KernelArgBuffer(b) as KernelArg; //ToDo лишний as

{$endregion Buffer}

{$region Record}

type
  KernelArgRecord<TRecord> = sealed class(ConstKernelArg)
  where TRecord: record;
    private val: ^TRecord := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<TRecord>));
    
    public constructor(val: TRecord) := self.val^ := val;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(new IntPtr(val));
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override :=
    cl.SetKernelArg(k, ind, new UIntPtr(Marshal.SizeOf&<TRecord>), pointer(self.val)).RaiseIfError; 
    
  end;
  
static function KernelArg.FromRecord<TRecord>(val: TRecord) := new KernelArgRecord<TRecord>(val) as KernelArg; //ToDo лишний as

{$endregion Record}

{$region Ptr}

type
  KernelArgPtr = sealed class(ConstKernelArg)
    private ptr: IntPtr;
    private sz: UIntPtr;
    
    public constructor(ptr: IntPtr; sz: UIntPtr);
    begin
      self.ptr := ptr;
      self.sz := sz;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override :=
    cl.SetKernelArg(k, ind, sz, pointer(ptr)).RaiseIfError;
    
  end;
  
static function KernelArg.FromPtr(ptr: IntPtr; sz: UIntPtr) := new KernelArgPtr(ptr, sz) as KernelArg; //ToDo лишний as

{$endregion Ptr}

{$endregion Const}

{$region Invokeable}

{$region Base}

type
  InvokeableKernelArg = abstract class(KernelArg) end;
  
{$endregion Base}

{$region Buffer}

type
  KernelArgBufferCQ = sealed class(InvokeableKernelArg)
    public q: CommandQueue<Buffer>;
    public constructor(q: CommandQueue<Buffer>) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; override :=
    q.InvokeNewQ(tsk, c, main_dvc, false, nil).LazyQuickTransform(b->new KernelArgBuffer(b) as ConstKernelArg as ISetableKernelArg); //ToDo #?
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
static function KernelArg.FromBufferCQ(bq: CommandQueue<Buffer>) :=
new KernelArgBufferCQ(bq) as KernelArg;

{$endregion Buffer}

{$region Record}

type
  KernelArgRecordQR<TRecord> = sealed class(ISetableKernelArg)
  where TRecord: record;
    public qr: QueueRes<TRecord>;
    public constructor(qr: QueueRes<TRecord>) := self.qr := qr;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context);
    begin
      var sz := new UIntPtr(Marshal.SizeOf&<TRecord>);
      if qr is QueueResDelayedPtr<TRecord>(var pqr) then
        cl.SetKernelArg(k, ind, sz, pointer(pqr.ptr)).RaiseIfError else
      begin
        var val := qr.GetRes;
        cl.SetKernelArg(k, ind, sz, val).RaiseIfError;
      end;
    end;
    
  end;
  KernelArgRecordCQ<TRecord> = sealed class(InvokeableKernelArg)
  where TRecord: record;
    public q: CommandQueue<TRecord>;
    public constructor(q: CommandQueue<TRecord>) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; override;
    begin
      var prev_qr := q.InvokeNewQ(tsk, c, main_dvc, true, nil);
      Result := new QueueResConst<ISetableKernelArg>(new KernelArgRecordQR<TRecord>(prev_qr), prev_qr.ev);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
static function KernelArg.FromRecordCQ<TRecord>(valq: CommandQueue<TRecord>) :=
new KernelArgRecordCQ<TRecord>(valq) as KernelArg;

{$endregion Record}

{$region Ptr}

type
  KernelArgPtrCQ = sealed class(InvokeableKernelArg)
    public ptr_q: CommandQueue<IntPtr>;
    public sz_q: CommandQueue<UIntPtr>;
    public constructor(ptr_q: CommandQueue<IntPtr>; sz_q: CommandQueue<UIntPtr>);
    begin
      self.ptr_q := ptr_q;
      self.sz_q := sz_q;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; override;
    begin
      var ptr_qr  := ptr_q.InvokeNewQ(tsk, c, main_dvc, false, nil);
      var sz_qr   :=  sz_q.InvokeNewQ(tsk, c, main_dvc, false, nil);
      Result := new QueueResFunc<ISetableKernelArg>(()->new KernelArgPtr(ptr_qr.GetRes, sz_qr.GetRes), ptr_qr.ev+sz_qr.ev);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      ptr_q.RegisterWaitables(tsk, prev_hubs);
       sz_q.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
static function KernelArg.FromPtrCQ(ptr_q: CommandQueue<IntPtr>; sz_q: CommandQueue<UIntPtr>) :=
new KernelArgPtrCQ(ptr_q, sz_q) as KernelArg;

{$endregion Ptr}

{$endregion Invokeable}

{$endregion KernelArg}

{$region CommonCommands}

{$region BufferCQ}

{%BufferMethods.Explicit.Implementation!MethodGen.pas%}

{%BufferGetMethods.Explicit.Implementation!MethodGen.pas%}

{$endregion BufferCQ}

{$region Buffer}

{%BufferMethods.Implicit.Implementation!MethodGen.pas%}

{%BufferGetMethods.Implicit.Implementation!MethodGen.pas%}

{$endregion Buffer}

{$region KernelCQ}

{%KernelMethods.Explicit.Implementation!MethodGen.pas%}

{$endregion KernelCQ}

{$region Kernel}

{%KernelMethods.Implicit.Implementation!MethodGen.pas%}

{$endregion Kernel}

{$endregion CommonCommands}

end.