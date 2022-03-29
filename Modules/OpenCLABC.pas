
{%..\LicenseHeader%}

///
///Высокоуровневая оболочка модуля OpenCL
///   OpenCL и OpenCLABC можно использовать одновременно
///   Но контактировать они практически не будут
///
///Если не хватает типа/метода или найдена ошибка - писать сюда:
///   https://github.com/SunSerega/POCGL/issues
///
///Справка данного модуля находится в папке примеров
///   По-умолчанию, её можно найти в "C:\PABCWork.NET\Samples\OpenGL и OpenCL"
///
unit OpenCLABC;

{$region TODO}

//===================================
// Обязательно сделать до следующей стабильной версии:

//TODO Тесты:

//TODO Справка:
// - KernelArg
// - NativeArray
// - CLValue
// - !CL!Memory[Sub]Segment

//===================================
// Запланированное:

//TODO cl.WaitForEvents тратит время процессора??? Почему?
// - Вроде потому, что тогда возобновление работы произойдёт быстрее, чем с колбеком
//TODO Интегрировать профайлинг очередей
// - И в том числе профайлинг отдельных ивентов

//TODO CombineUse? А то CombineConv есть, а Use нету...

//TODO .Cycle(integer)
//TODO .Cycle // бесконечность циклов
//TODO .CycleWhile(***->boolean)
//TODO В продолжение Cycle: Однако всё ещё остаётся проблема - как сделать ветвление?
// - И если уже делать - стоит сделать и метод CQ.ThenIf(res->boolean; if_true, if_false: CQ)
//TODO И ещё - AbortQueue, который, по сути, может использоваться как exit, continue или break, если с обработчиками ошибок
// - Или может метод MarkerQueue.Abort?
//TODO .DelayInit, чтобы ветки .ThenIf можно было не инициализировать заранее
// - Тогда .ThenIf на много проще реализовать - через особый err_handler, который говорит что ошибки были, без собственно ошибок
//TODO CCQ.ThenIf(cond, command, nil)
// - Подумать как можно сделать это красивее, чем через MU

//TODO Пройтись по интерфейсу, порасставлять кидание исключений
//TODO Проверки и кидания исключений перед всеми cl.*, чтобы выводить норм сообщения об ошибках
//TODO Попробовать получать информацию о параметрах Kernel'а и выдавать адекватные ошибки, если передают что-то не то
// - Адрес RAM всегда превращается в read-only копию на стороне OpenCL-C?

//TODO Порядок Wait очередей в Wait группах
// - Проверить сочетание с каждой другой фичей

//TODO Использовать cl.EnqueueMapBuffer
// - В виде .AddMap((MappedArray,Context)->())
// - Недодел своей ветке

//TODO .pcu с неправильной позицией зависимости, или не теми настройками - должен игнорироваться
// - Иначе сейчас модули в примерах ссылаются на .pcu, который существует только во время работы Tester, ломая компилятор

//TODO Несколько TODO в:
// - Queue converter's >> Wait

//TODO NativeMemoryArea в отдельный модуль
// - При этом сделать его кросс-платформенным

//TODO Исправить перегрузки Kernel.Exec
// - Сначала решить как исправлять

//===================================
// Сделать когда-нибуть:

//TODO Пройтись по всем функциям OpenCL, посмотреть функционал каких не доступен из OpenCLABC
// - clGetKernelWorkGroupInfo - свойства кернела на определённом устройстве
// - clCreateContext: CL_CONTEXT_INTEROP_USER_SYNC
// - MemFlags кроме MemFlags.MEM_READ_WRITE
// - Другие типы cl_mem (сейчас используется только буфер)
// - clEnqueueNativeKernel
// --- CL_DEVICE_BUILT_IN_KERNELS

//TODO Фичи OpenCL3.0, которого у меня нет
// - CL_DEVICE_ILS_WITH_VERSION
// - CL_DEVICE_BUILT_IN_KERNELS_WITH_VERSION
// - CL_DEVICE_NUMERIC_VERSION
// - CL_DEVICE_OPENCL_C_ALL_VERSIONS
// - CL_DEVICE_OPENCL_C_FEATURES
// - CL_DEVICE_EXTENSIONS_WITH_VERSION
// - CL_DEVICE_ATOMIC_MEMORY_CAPABILITIES
// - CL_DEVICE_ATOMIC_FENCE_CAPABILITIES
// - CL_DEVICE_NON_UNIFORM_WORK_GROUP_SUPPORT
// - CL_DEVICE_WORK_GROUP_COLLECTIVE_FUNCTIONS_SUPPORT
// - CL_DEVICE_GENERIC_ADDRESS_SPACE_SUPPORT
// - CL_DEVICE_DEVICE_ENQUEUE_CAPABILITIES
// - CL_DEVICE_PIPE_SUPPORT
// - CL_DEVICE_PREFERRED_WORK_GROUP_SIZE_MULTIPLE
// - CL_DEVICE_LATEST_CONFORMANCE_VERSION_PASSED

//TODO Слишком новые фичи, которые могут много чего изменить:
// - cl_khr_command_buffer
// --- Буферы, хранящие список комманд
// - cl_khr_semaphore
// --- Как cl_event, но многоразовые

//===================================

{$endregion TODO}

{$region Bugs}

//TODO Issue компилятора:
//TODO https://github.com/pascalabcnet/pascalabcnet/issues/{id}
// - #2221
// - #2550
// - #2589
// - #2604
// - #2607
// - #2610

//TODO Баги NVidia
//TODO https://developer.nvidia.com/nvidia_bug/{id}
// - NV#3035203

{$endregion}

{$region DEBUG}{$ifdef DEBUG}

// Регистрация всех cl.RetainEvent и cl.ReleaseEvent
{ $define EventDebug}

// Регистрация использований cl_command_queue
{ $define QueueDebug}

// Регистрация активаций/деактиваций всех WaitHandler-ов
{ $define WaitDebug}

{ $define ForceMaxDebug}
{$ifdef ForceMaxDebug}
  {$define EventDebug}
  {$define QueueDebug}
  {$define WaitDebug}
{$endif ForceMaxDebug}

{$endif DEBUG}{$endregion DEBUG}

interface

uses System;
uses System.Threading;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;
uses System.Collections.ObjectModel;
uses System.Collections.Concurrent;

uses OpenCL;

type
  
  {$region Re-definition's}
  
  OpenCLException         = OpenCL.OpenCLException;
  
  DeviceType              = OpenCL.DeviceType;
  DeviceAffinityDomain    = OpenCL.DeviceAffinityDomain;
  
  {$endregion Re-definition's}
  
  {$region OpenCLABCInternalException}
  
  OpenCLABCInternalException = sealed class(Exception)
    
    private constructor(message: string) :=
    inherited Create(message);
//    private constructor(message: string; ec: ErrorCode) :=
//    inherited Create($'{message} with {ec}');
    private constructor(ec: ErrorCode) :=
    inherited Create(OpenCLException.Create(ec).Message);
    private constructor;
    begin
      inherited Create($'%Err:NoParamCtor%');
      raise self;
    end;
    
    private static procedure RaiseIfError(ec: ErrorCode) :=
    if ec.IS_ERROR then raise new OpenCLABCInternalException(ec);
    
    private static procedure RaiseIfError(st: CommandExecutionStatus) :=
    if st.val<0 then RaiseIfError(ErrorCode(st));
    
  end;
  
  {$endregion OpenCLABCInternalException}
  
  {$region DEBUG}
  
  {$region EventDebug}{$ifdef EventDebug}
  
  EventRetainReleaseData = record
    private is_release: boolean;
    private reason: string;
    
    private static debug_time_counter := Stopwatch.StartNew;
    private time: TimeSpan;
    
    public constructor(is_release: boolean; reason: string);
    begin
      self.is_release := is_release;
      self.reason := reason;
      self.time := debug_time_counter.Elapsed;
    end;
    
    private function GetActStr := is_release ? 'Released' : 'Retained';
    public function ToString: string; override :=
    $'{time} | {GetActStr} when: {reason}';
    
  end;
  EventDebug = static class
    
    {$region Retain/Release}
    
    private static RefCounter := new ConcurrentDictionary<cl_event, ConcurrentQueue<EventRetainReleaseData>>;
    private static function RefCounterFor(ev: cl_event) := RefCounter.GetOrAdd(ev, ev->new ConcurrentQueue<EventRetainReleaseData>);
    
    public static procedure RegisterEventRetain(ev: cl_event; reason: string) :=
    RefCounterFor(ev).Enqueue(new EventRetainReleaseData(false, reason));
    public static procedure RegisterEventRelease(ev: cl_event; reason: string);
    begin
      EventDebug.CheckExists(ev, reason);
      RefCounterFor(ev).Enqueue(new EventRetainReleaseData(true, reason));
    end;
    
    public static procedure ReportRefCounterInfo(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      foreach var kvp in RefCounter do
      begin
        otp.WriteLine($'Logging state change of {kvp.Key}:');
        var c := 0;
        foreach var act in kvp.Value do
        begin
          c += if act.is_release then -1 else +1;
          otp.WriteLine($'{c,3} | {act}');
        end;
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static function CountRetains(ev: cl_event) :=
    RefCounter[ev].Sum(act->act.is_release ? -1 : +1);
    public static procedure CheckExists(ev: cl_event; reason: string) :=
    if CountRetains(ev)<=0 then lock output do
    begin
      ReportRefCounterInfo(Console.Error);
      Sleep(1000);
      raise new OpenCLABCInternalException($'Event {ev} was released before last use ({reason}) at');
    end;
    
    public static procedure FinallyReport;
    begin
      foreach var ev in RefCounter.Keys do if CountRetains(ev)<>0 then
      begin
        ReportRefCounterInfo(Console.Error);
        Sleep(1000);
        raise new OpenCLABCInternalException(ev.ToString);
      end;
      var total_ev_count := RefCounter.Values.Sum(q->q.Select(act->act.is_release ? -1 : +1).PartialSum.CountOf(0));
      $'[EventDebug]: {total_ev_count} event''s created'.Println;
    end;
    
    {$endregion Retain/Release}
    
  end;
  
  {$endif EventDebug}{$endregion EventDebug}
  
  {$region QueueDebug}{$ifdef QueueDebug}
  
  QueueDebug = static class
    
    private static QueueUses := new ConcurrentDictionary<cl_command_queue, ConcurrentQueue<string>>;
    private static function QueueUsesFor(cq: cl_command_queue) := QueueUses.GetOrAdd(cq, cq->new ConcurrentQueue<string>);
    private static procedure Add(cq: cl_command_queue; use: string) := QueueUsesFor(cq).Enqueue(use);
    
    public static procedure ReportQueueUses(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      foreach var kvp in QueueUses do
      begin
        otp.WriteLine($'Logging uses of {kvp.Key}:');
        foreach var use in kvp.Value do
          otp.WriteLine(use);
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static procedure FinallyReport;
    begin
      var total_q_count := QueueUses.Keys.Sum(q->
      begin
        Result := 0;
        var last_return := false;
        foreach var use in QueueUses[q] do
        begin
          last_return := ('- return -' in use) or ('- last q -' in use);
          Result += ord(last_return);
        end;
        if last_return then exit;
        ReportQueueUses(Console.Error);
        Sleep(1000);
        raise new OpenCLABCInternalException(q.ToString);
      end);
      $'[QueueDebug]: {total_q_count} queue''s created'.Println;
    end;
    
  end;
  
  {$endif}{$endregion QueueDebug}
  
  {$region WaitDebug}{$ifdef WaitDebug}
  
  WaitDebug = static class
    
    private static WaitActions := new ConcurrentDictionary<object, ConcurrentQueue<string>>;
    
    private static procedure RegisterAction(handler: object; act: string) :=
    WaitActions.GetOrAdd(handler, hc->new System.Collections.Concurrent.ConcurrentQueue<string>).Enqueue(act);
    
    public static procedure ReportWaitActions(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      foreach var kvp in WaitActions do
      begin
        otp.WriteLine($'Logging actions of handler[{kvp.Key.GetHashCode}]:');
        foreach var act in kvp.Value do
          otp.WriteLine(act);
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static procedure FinallyReport;
    begin
      $'[WaitDebug]: {WaitActions.Count} wait handler''s created'.Println;
    end;
    
  end;
  
  {$endif}{$endregion WaitDebug}
  
  {$endregion DEBUG}
  
  {$region WrapperProperties}
  
  {%WrapperProperties\Interface!WrapperProperties.pas%}
  
  {$endregion WrapperProperties}
  
  {$region Wrappers}
  // For parameters of OpenCL_command-methods
  CommandQueue<T> = abstract partial class end;
  KernelArg = abstract partial class end;
  
  {$region ContextData}
  
  {$region Platform}
  
  Platform = partial class
    private ntv: cl_platform_id;
    
    public constructor(ntv: cl_platform_id) := self.ntv := ntv;
    private constructor := raise new OpenCLABCInternalException;
    
    private static all_need_init := true;
    private static _all: IList<Platform>;
    private static function GetAll: IList<Platform>;
    begin
      if all_need_init then
      begin
        var c: UInt32;
        OpenCLABCInternalException.RaiseIfError(
          cl.GetPlatformIDs(0, IntPtr.Zero, c)
        );
        
        if c<>0 then
        begin
          var all_arr := new cl_platform_id[c];
          OpenCLABCInternalException.RaiseIfError(
            cl.GetPlatformIDs(c, all_arr[0], IntPtr.Zero)
          );
          
          _all := new ReadOnlyCollection<Platform>(all_arr.ConvertAll(pl->new Platform(pl)));
        end else
          _all := nil;
        
        all_need_init := false;
      end;
      Result := _all;
    end;
    public static property All: IList<Platform> read GetAll;
    
  end;
  
  {$endregion Platform}
  
  {$region Device}
  
  Device = partial class
    private ntv: cl_device_id;
    
    private constructor(ntv: cl_device_id) := self.ntv := ntv;
    public static function FromNative(ntv: cl_device_id): Device;
    
    private constructor := raise new OpenCLABCInternalException;
    
    private function GetBasePlatform: Platform;
    begin
      var pl: cl_platform_id;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetDeviceInfo(self.ntv, DeviceInfo.DEVICE_PLATFORM, new UIntPtr(sizeof(cl_platform_id)), pl, IntPtr.Zero)
      );
      Result := new Platform(pl);
    end;
    public property BasePlatform: Platform read GetBasePlatform;
    
    public static function GetAllFor(pl: Platform; t: DeviceType): array of Device;
    begin
      
      var c: UInt32;
      var ec := cl.GetDeviceIDs(pl.ntv, t, 0, IntPtr.Zero, c);
      if ec=ErrorCode.DEVICE_NOT_FOUND then exit;
      OpenCLABCInternalException.RaiseIfError(ec);
      
      var all := new cl_device_id[c];
      OpenCLABCInternalException.RaiseIfError(
        cl.GetDeviceIDs(pl.ntv, t, c, all[0], IntPtr.Zero)
      );
      
      Result := all.ConvertAll(dvc->new Device(dvc));
    end;
    public static function GetAllFor(pl: Platform) := GetAllFor(pl, DeviceType.DEVICE_TYPE_GPU);
    
  end;
  
  {$endregion Device}
  
  {$region SubDevice}
  
  SubDevice = partial class(Device)
    private _parent: cl_device_id;
    public property Parent: Device read Device.FromNative(_parent);
    
    private constructor(parent, ntv: cl_device_id);
    begin
      inherited Create(ntv);
      self._parent := parent;
    end;
    
    private constructor := inherited;
    
    protected procedure Finalize; override :=
    OpenCLABCInternalException.RaiseIfError(cl.ReleaseDevice(ntv));
    
  end;
  
  {$endregion SubDevice}
  
  {$region Context}
  
  Context = partial class
    private ntv: cl_context;
    
    private dvcs: IList<Device>;
    public property AllDevices: IList<Device> read dvcs;
    
    private main_dvc: Device;
    public property MainDevice: Device        read main_dvc;
    
    private function GetAllNtvDevices: array of cl_device_id;
    begin
      Result := new cl_device_id[dvcs.Count];
      for var i := 0 to Result.Length-1 do
        Result[i] := dvcs[i].ntv;
    end;
    
    {$region Default}
    
    private static default_was_inited := 0;
    private static _default: Context;
    
    private static function GetDefault: Context;
    begin
      if Interlocked.CompareExchange(default_was_inited, 1, 0)=0 then
        Interlocked.CompareExchange(_default, MakeNewDefaultContext, nil);
      Result := _default;
    end;
    private static procedure SetDefault(new_default: Context);
    begin
      default_was_inited := 1;
      _default := new_default;
    end;
    public static property &Default: Context read GetDefault write SetDefault;
    
    protected static function MakeNewDefaultContext: Context;
    begin
      Result := nil;
      
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
        ntv_dvcs[i] := dvcs[i].ntv;
      
      var ec: ErrorCode;
      self.ntv := cl.CreateContext(nil, ntv_dvcs.Count, ntv_dvcs, nil, IntPtr.Zero, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      self.dvcs := if dvcs.IsReadOnly then dvcs else new ReadOnlyCollection<Device>(dvcs.ToArray);
      self.main_dvc := main_dvc;
    end;
    public constructor(params dvcs: array of Device) := Create(dvcs, dvcs[0]);
    
    protected static function GetContextDevices(ntv: cl_context): array of Device;
    begin
      
      var sz: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetContextInfo(ntv, ContextInfo.CONTEXT_DEVICES, UIntPtr.Zero, nil, sz)
      );
      
      var res := new cl_device_id[uint64(sz) div Marshal.SizeOf&<cl_device_id>];
      OpenCLABCInternalException.RaiseIfError(
        cl.GetContextInfo(ntv, ContextInfo.CONTEXT_DEVICES, sz, res[0], IntPtr.Zero)
      );
      
      Result := res.ConvertAll(dvc->new Device(dvc));
    end;
    private procedure InitFromNtv(ntv: cl_context; dvcs: IList<Device>; main_dvc: Device);
    begin
      CheckMainDevice(main_dvc, dvcs);
      OpenCLABCInternalException.RaiseIfError( cl.RetainContext(ntv) );
      self.ntv := ntv;
      // Копирование должно происходить в вызывающих методах
      self.dvcs := if dvcs.IsReadOnly then dvcs else new ReadOnlyCollection<Device>(dvcs);
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
    
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseContext(new cl_context(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
  end;
  
  {$endregion Context}
  
  {$endregion ContextData}
  
  {$region KernelData}
  
  {$region ProgramCode}
  
  ProgramCode = partial class
    private ntv: cl_program;
    
    private _c: Context;
    public property BaseContext: Context read _c;
    
    {$region constructor's}
    
    private procedure Build;
    begin
      var ec := cl.BuildProgram(self.ntv, _c.dvcs.Count,_c.GetAllNtvDevices, nil, nil,IntPtr.Zero);
      if not ec.IS_ERROR then exit;
      
      if ec=ErrorCode.BUILD_PROGRAM_FAILURE then
      begin
        var sb := new StringBuilder($'%Err:ProgramCode:BuildFail%');
        
        foreach var dvc in _c.AllDevices do
        begin
          sb += #10#10;
          sb += dvc.ToString;
          sb += ':'#10;
          
          var sz: UIntPtr;
          OpenCLABCInternalException.RaiseIfError(
            cl.GetProgramBuildInfo(self.ntv, dvc.ntv, ProgramBuildInfo.PROGRAM_BUILD_LOG, UIntPtr.Zero,IntPtr.Zero,sz)
          );
          
          var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
          try
            OpenCLABCInternalException.RaiseIfError(
              cl.GetProgramBuildInfo(self.ntv, dvc.ntv, ProgramBuildInfo.PROGRAM_BUILD_LOG, sz,str_ptr,IntPtr.Zero)
            );
            sb += Marshal.PtrToStringAnsi(str_ptr);
          finally
            Marshal.FreeHGlobal(str_ptr);
          end;
          
        end;
        
        raise new OpenCLException(ec, sb.ToString);
      end else
        OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    
    public constructor(c: Context; params file_texts: array of string);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateProgramWithSource(c.ntv, file_texts.Length, file_texts, nil, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      self._c := c;
      self.Build;
    end;
    public constructor(params file_texts: array of string) := Create(Context.Default, file_texts);
    
    private constructor(ntv: cl_program; c: Context);
    begin
      OpenCLABCInternalException.RaiseIfError( cl.RetainProgram(ntv) );
      self._c := c;
      self.ntv := ntv;
    end;
    
    private static function GetProgContext(ntv: cl_program): Context;
    begin
      var c: cl_context;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_CONTEXT, new UIntPtr(Marshal.SizeOf&<cl_context>), c, IntPtr.Zero)
      );
      Result := new Context(c);
    end;
    public constructor(ntv: cl_program) :=
    Create(ntv, GetProgContext(ntv));
    
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseProgram(new cl_program(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
    {$region Serialize}
    
    public function Serialize: array of array of byte;
    begin
      var sz: UIntPtr;
      
      OpenCLABCInternalException.RaiseIfError( cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARY_SIZES, UIntPtr.Zero, nil, sz) );
      var szs := new UIntPtr[sz.ToUInt64 div sizeof(UIntPtr)];
      OpenCLABCInternalException.RaiseIfError( cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARY_SIZES, sz, szs[0], IntPtr.Zero) );
      
      var res := new IntPtr[szs.Length];
      SetLength(Result, szs.Length);
      
      for var i := 0 to szs.Length-1 do res[i] := Marshal.AllocHGlobal(IntPtr(pointer(szs[i])));
      try
        OpenCLABCInternalException.RaiseIfError(
          cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARIES, sz, res[0], IntPtr.Zero)
        );
        for var i := 0 to szs.Length-1 do
        begin
          var a := new byte[szs[i].ToUInt64];
          Marshal.Copy(res[i], a, 0, a.Length);
          Result[i] := a;
        end;
      finally
        for var i := 0 to szs.Length-1 do Marshal.FreeHGlobal(res[i]);
      end;
      
    end;
    
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
        c.ntv, dvcs.Length, dvcs[0],
        bin.ConvertAll(a->new UIntPtr(a.Length))[0], bin,
        IntPtr.Zero, ec
      );
      OpenCLABCInternalException.RaiseIfError(ec);
      
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
  
  {$region Kernel}
  
  Kernel = partial class
    private ntv: cl_kernel;
    
    private code: ProgramCode;
    public property CodeContainer: ProgramCode read code;
    
    private k_name: string;
    public property Name: string read k_name;
    
    {$region constructor's}
    
    protected function MakeNewNtv: cl_kernel;
    begin
      var ec: ErrorCode;
      Result := cl.CreateKernel(code.ntv, k_name, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
    end;
    private constructor(code: ProgramCode; name: string);
    begin
      self.code := code;
      self.k_name := name;
      self.ntv := self.MakeNewNtv;
    end;
    
    public constructor(ntv: cl_kernel; retain: boolean := true);
    begin
      
      var code_ntv: cl_program;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, new UIntPtr(cl_program.Size), code_ntv, IntPtr.Zero)
      );
      self.code := new ProgramCode(code_ntv);
      
      var sz: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, UIntPtr.Zero, nil, sz)
      );
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        OpenCLABCInternalException.RaiseIfError(
          cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, sz, str_ptr, IntPtr.Zero)
        );
        self.k_name := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
      if retain then OpenCLABCInternalException.RaiseIfError( cl.RetainKernel(ntv) );
      self.ntv := ntv;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseKernel(new cl_kernel(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
    {$region UseExclusiveNative}
    
    private ntv_in_use := 0;
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure UseExclusiveNative(p: cl_kernel->()) :=
    if Interlocked.CompareExchange(ntv_in_use, 1, 0)=0 then
    try
      p(self.ntv);
    finally
      ntv_in_use := 0;
    end else
    begin
      var k := MakeNewNtv;
      try
        p(k);
      finally
        OpenCLABCInternalException.RaiseIfError( cl.ReleaseKernel(k) );
      end;
    end;
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function UseExclusiveNative<T>(f: cl_kernel->T): T;
    begin
      
      if Interlocked.CompareExchange(ntv_in_use, 1, 0)=0 then
      try
        Result := f(self.ntv);
      finally
        ntv_in_use := 0;
      end else
      begin
        var k := MakeNewNtv;
        try
          Result := f(k);
        finally
          OpenCLABCInternalException.RaiseIfError( cl.ReleaseKernel(k) );
        end;
      end;
      
    end;
    
    {$endregion UseExclusiveNative}
    
    {%ContainerMethods\Kernel\Implicit.Interface!ContainerMethods.pas%}
    
  end;
  
  ProgramCode = partial class
    
    public property KernelByName[kname: string]: Kernel read new Kernel(self, kname); default;
    
    public function GetAllKernels: array of Kernel;
    begin
      
      var c: UInt32;
      OpenCLABCInternalException.RaiseIfError( cl.CreateKernelsInProgram(ntv, 0, IntPtr.Zero, c) );
      
      var res := new cl_kernel[c];
      OpenCLABCInternalException.RaiseIfError( cl.CreateKernelsInProgram(ntv, c, res[0], IntPtr.Zero) );
      
      Result := res.ConvertAll(k->new Kernel(k, false));
    end;
    
  end;
  
  {$endregion Kernel}
  
  {$endregion KernelData}
  
  {$region Memory}
  
  {$region Native}
  
  {$region NativeMemoryArea}
  
  NativeMemoryArea = record
    public ptr: IntPtr;
    public sz: UIntPtr;
    
    public constructor(ptr: IntPtr; sz: UIntPtr);
    begin
      self.ptr := ptr;
      self.sz := sz;
    end;
    ///--
    public constructor := exit;
    
    {$region Fill}
    
    private static procedure RtlZeroMemory(dst: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlFillMemory(dst: IntPtr; length: UIntPtr; fill: byte);
    external 'kernel32.dll';
    
    public procedure FillZero := RtlZeroMemory(ptr, sz);
    public procedure Fill(val: byte) := RtlFillMemory(ptr, sz, val);
    
    {$endregion Fill}
    
    {$region Copy}
    
    private static procedure RtlCopyMemory(dst: IntPtr; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlCopyMemory(var dst: byte; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlCopyMemory(dst: IntPtr; var source: byte; length: UIntPtr);
    external 'kernel32.dll';
    
    public procedure CopyTo(area: NativeMemoryArea) := RtlCopyMemory(area.ptr, self.ptr, self.sz);
    public procedure CopyFrom(area: NativeMemoryArea) := RtlCopyMemory(self.ptr, area.ptr, self.sz);
    public static procedure CopyMinSize(source, dest: NativeMemoryArea);
    begin
      var min_sz := if source.sz.ToUInt64<dest.sz.ToUInt64 then source.sz else dest.sz;
      RtlCopyMemory(dest.ptr, source.ptr, min_sz);
    end;
    
    public procedure CopyTo<T>(var el: T) := RtlCopyMemory(PByte(pointer(@el))^, self.ptr, self.sz);
    public procedure CopyTo<T>(a: array of T) := CopyTo(a[0]);
    
    public procedure CopyFrom<T>(var el: T) := RtlCopyMemory(self.ptr, PByte(pointer(@el))^, self.sz);
    public procedure CopyFrom<T>(a: array of T) := CopyFrom(a[0]);
    
    {$endregion Copy}
    
    {$region CopyOverlapped}
    
    private static procedure RtlMoveMemory (dst: IntPtr; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlMoveMemory (var dst: byte; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlMoveMemory (dst: IntPtr; var source: byte; length: UIntPtr);
    external 'kernel32.dll';
    
    public procedure CopyOverlappedTo(area: NativeMemoryArea) := RtlMoveMemory(area.ptr, self.ptr, self.sz);
    public procedure CopyOverlappedFrom(area: NativeMemoryArea) := RtlMoveMemory(self.ptr, area.ptr, self.sz);
    public static procedure CopyOverlappedMinSize(source, dest: NativeMemoryArea);
    begin
      var min_sz := if source.sz.ToUInt64<dest.sz.ToUInt64 then source.sz else dest.sz;
      RtlMoveMemory(dest.ptr, source.ptr, min_sz);
    end;
    
    public procedure CopyOverlappedTo<T>(var el: T) := RtlMoveMemory(PByte(pointer(@el))^, self.ptr, self.sz);
    public procedure CopyOverlappedTo<T>(a: array of T) := CopyTo(a[0]);
    
    public procedure CopyOverlappedFrom<T>(var el: T) := RtlMoveMemory(self.ptr, PByte(pointer(@el))^, self.sz);
    public procedure CopyOverlappedFrom<T>(a: array of T) := CopyTo(a[0]);
    
    {$endregion CopyOverlapped}
    
    public function ToString: string; override :=
    $'{ptr}[{sz}]';
    
  end;
  
  {$endregion NativeMemoryArea}
  
  {$region NativeValue}
  
  NativeValue<T> = partial class(IDisposable)
  where T: record;
    private ptr: IntPtr;
    
    {$region constructor's}
    
    private procedure Init;
    begin
      self.ptr := Marshal.AllocHGlobal(value_size);
      GC.AddMemoryPressure(value_size);
    end;
    public constructor;
    begin
      Init;
      self.MemoryArea.FillZero;
    end;
    public constructor(o: T);
    begin
      Init;
      self.Value := o;
    end;
    public static function operator implicit(o: T): NativeValue<T> := new NativeValue<T>(o);
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static value_size := Marshal.SizeOf&<T>;
    public static property ValueSize: integer read value_size;
    
    public property MemoryArea: NativeMemoryArea read new NativeMemoryArea(ptr, new UIntPtr(value_size));
    
    private function PtrUntyped := pointer(ptr);
    public property Pointer: ^T read PtrUntyped();
    public property Value: T read Pointer^ write Pointer^ := value;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var l_ptr := Interlocked.Exchange(self.ptr, IntPtr.Zero);
      if l_ptr=IntPtr.Zero then exit;
      GC.RemoveMemoryPressure(value_size);
      Marshal.FreeHGlobal(l_ptr);
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    public function ToString: string; override :=
    $'{TypeName(self)}{{ {_ObjectToString(Value)} }}';
    
  end;
  
  {$endregion NativeValue}
  
  {$region NativeArray}
  
  NativeArray<T> = partial class
  where T: record;
    private area: NativeMemoryArea;
    
    {$region constructor's}
    
    private procedure AllocArea(length: integer);
    begin
      var sz := int64(item_size) * length;
      self.area := new NativeMemoryArea(
        Marshal.AllocHGlobal(new IntPtr(sz)),
        new UIntPtr(sz)
      );
      GC.AddMemoryPressure(sz);
    end;
    public constructor(length: integer);
    begin
      AllocArea(length);
      self.area.FillZero;
    end;
    public constructor(a: array of T);
    begin
      AllocArea(a.Length);
      self.area.CopyFrom(a);
    end;
    
    {$endregion constructor's}
    
    {$region Method's}
    
    public function IndexOf(item: T): integer?;
    begin
      Result := nil;
      for var i := 0 to ItemCount-1 do
        if self.Item[i]=item then
        begin
          Result := i;
          break;
        end;
    end;
    
    {$endregion Method's}
    
    {$region property's}
    
    private static item_size := Marshal.SizeOf&<T>;
    public static property ItemSize: integer read item_size;
    
    public property MemoryArea: NativeMemoryArea read self.area;
    public property ItemCount: cardinal read self.area.sz.ToUInt64 div item_size;
    
    private function ItemPtrUntyped(i: integer) := pointer(area.ptr + i*item_size);
    public property ItemPtrUnchecked[i: integer]: ^T read ItemPtrUntyped(i);
    
    private function GetAndCheckItemPtr(i: integer): ^T;
    begin
      if cardinal(i)>=ItemCount then raise new IndexOutOfRangeException;
      Result := ItemPtrUnchecked[i];
    end;
    public property ItemPtr[i: integer]: ^T read GetAndCheckItemPtr;
    public property Item[i: integer]: T read ItemPtr[i]^ write ItemPtr[i]^ := value; default;
    
    public property SliceAreaUnchecked[r: IntRange]: NativeMemoryArea read new NativeMemoryArea(
      self.area.ptr + r.Low*ItemSize,
      new UIntPtr((r.High-r.Low+1) * int64(ItemSize))
    );
    private function GetSliceAreaAndCheck(r: IntRange): NativeMemoryArea;
    begin
      if r.Low<0 then raise new IndexOutOfRangeException('Low');
      if cardinal(r.High)>=ItemCount then raise new IndexOutOfRangeException('High');
      Result := SliceAreaUnchecked[r];
    end;
    public property SliceArea[r: IntRange]: NativeMemoryArea read GetSliceAreaAndCheck;
    
    private function GetSliceCopy(r: IntRange): array of T;
    begin
      var area := SliceArea[r];
      Result := new T[r.High-r.Low+1];
      area.CopyTo(Result);
    end;
    public property SliceCopy[r: IntRange]: array of T read GetSliceCopy write
    begin
      var expected_len := r.High-r.Low+1;
      if value.Length<>expected_len then raise new ArgumentException($'%Err:NativeArray:SliceCopy:WriteSize%');
      var area := SliceArea[r];
      area.CopyFrom(value);
    end;
    
    {$endregion property's}
    
  end;
  
  NativeArrayEnumerator<T> = record(IEnumerator<T>)
  where T: record;
    private a: NativeArray<T>;
    private i: integer;
    
    public constructor(a: NativeArray<T>);
    begin
      self.a := a;
      self.Reset;
    end;
    ///--
    public constructor := exit;
    
    public function MoveNext: boolean;
    begin
      i += 1;
      Result := i < a.ItemCount;
    end;
    public procedure Reset := self.i := -1;
    
    public property Current: T read a[i];
    public property System.Collections.IEnumerator.Current: object read a[i];
    
    public procedure Dispose := a := nil;
    
  end;
  NativeArray<T> = partial class(IList<T>, IDisposable)
    
    {$region IList}
    
    public function System.Collections.Generic.IList<T>.IndexOf(item: T): integer := (self.IndexOf(item) ?? -1).Value;
    
    public procedure System.Collections.Generic.IList<T>.Insert(index: integer; item: T) := raise new NotSupportedException;
    public procedure System.Collections.Generic.IList<T>.RemoveAt(index: integer) := raise new NotSupportedException;
    
    {$endregion IList}
    
    {$region ICollection}
    
    //TODO #????
    ///--
    public property {System.Collections.Generic.ICollection<T>.}Count: integer read self.ItemCount;
    public property System.Collections.Generic.ICollection<T>.IsReadOnly: boolean read boolean(true);
    
    public procedure System.Collections.Generic.ICollection<T>.Add(item: T) := raise new NotSupportedException;
    public function System.Collections.Generic.ICollection<T>.Remove(item: T): boolean;
    begin
      Result := false;
      raise new NotSupportedException;
    end;
    public procedure System.Collections.Generic.ICollection<T>.Clear := raise new NotSupportedException;
    
    public function Contains(item: T) := self.IndexOf(item) <> nil;
    
    public procedure CopyTo(&array: array of T; arrayIndex: integer);
    begin
      if arrayIndex+self.ItemCount > &array.Length then raise new IndexOutOfRangeException;
      self.area.CopyTo(&array[arrayIndex]);
    end;
    
    {$endregion ICollection}
    
    {$region IEnumerable}
    
    public function GetEnumerator: System.Collections.Generic.IEnumerator<T> := new NativeArrayEnumerator<T>(self);
    public function System.Collections.IEnumerable.GetEnumerator: System.Collections.IEnumerator := new NativeArrayEnumerator<T>(self);
    
    {$endregion IEnumerable}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var l_ptr := Interlocked.Exchange(self.area.ptr, IntPtr.Zero);
      if l_ptr=IntPtr.Zero then exit;
      GC.RemoveMemoryPressure(area.sz.ToUInt64);
      Marshal.FreeHGlobal(l_ptr);
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      sb += TypeName(self);
      sb += '{';
      if self.ItemCount<>0 then
      begin
        sb += ' ';
        //TODO #????: as
        foreach var x in self as IList<T> do
        begin
          sb += _ObjectToString(x);
          sb += ', ';
        end;
        sb.Length -= ', '.Length;
        sb += ' ';
      end;
      sb += '}';
      Result := sb.ToString;
    end;
    
  end;
  
  {$endregion NativeArray}
  
  {$endregion Native}
  
  {$region OpenCL}
  
  {$region CLMemorySegment}
  
  CLMemorySegment = partial class(IDisposable)
    private ntv: cl_mem;
    
    {$region constructor's}
    
    public constructor(size: UIntPtr; c: Context);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE, size, IntPtr.Zero, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      GC.AddMemoryPressure(size.ToUInt64);
      
    end;
    public constructor(size: integer; c: Context) := Create(new UIntPtr(size), c);
    public constructor(size: int64; c: Context)   := Create(new UIntPtr(size), c);
    
    public constructor(size: UIntPtr) := Create(size, Context.Default);
    public constructor(size: integer) := Create(new UIntPtr(size));
    public constructor(size: int64)   := Create(new UIntPtr(size));
    
    private constructor(ntv: cl_mem);
    begin
      self.ntv := ntv;
      cl.RetainMemObject(ntv);
    end;
    public static function FromNative(ntv: cl_mem): CLMemorySegment;
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static function GetSize(ntv: cl_mem): UIntPtr;
    begin
      OpenCLABCInternalException.RaiseIfError(
        cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(UIntPtr.Size), Result, IntPtr.Zero)
      );
    end;
    public property Size: UIntPtr read GetSize(ntv);
    public property Size32: UInt32 read Size.ToUInt32;
    public property Size64: UInt64 read Size.ToUInt64;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    private procedure FinishReleasing(prev_ntv: cl_mem); virtual :=
    GC.RemoveMemoryPressure( GetSize(prev_ntv).ToUInt64 );
    
    public procedure Dispose;
    begin
      var prev_ntv := new cl_mem( Interlocked.Exchange(self.ntv.val, IntPtr.Zero) );
      if prev_ntv=cl_mem.Zero then exit;
      FinishReleasing(prev_ntv);
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseMemObject(prev_ntv) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    {%ContainerMethods\CLMemorySegment\Implicit.Interface!ContainerMethods.pas%}
    
    {%ContainerMethods\CLMemorySegment.Get\Implicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  {$endregion CLMemorySegment}
  
  {$region CLMemorySubSegment}
  
  CLMemorySubSegment = partial class(CLMemorySegment)
    private _parent: cl_mem;
    // Forbid parent from disposing itself
    private parent_dispose_lock: CLMemorySegment;
    
    {$region constructor's}
    
    private static function MakeSubNtv(parent: cl_mem; reg: cl_buffer_region): cl_mem;
    begin
      var ec: ErrorCode;
      Result := cl.CreateSubBuffer(parent, MemFlags.MEM_READ_WRITE, BufferCreateType.BUFFER_CREATE_TYPE_REGION, reg, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
    end;
    
    public constructor(parent: CLMemorySegment; origin, size: UIntPtr);
    begin
      inherited Create( MakeSubNtv(parent.ntv, new cl_buffer_region(origin, size)) );
      self._parent := parent.ntv;
      self.parent_dispose_lock := parent;
    end;
    public constructor(parent: CLMemorySegment; origin, size: UInt32) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    public constructor(parent: CLMemorySegment; origin, size: UInt64) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    
    // For the CLMemorySegment.FromNative
    private constructor(parent, ntv: cl_mem);
    begin
      inherited Create(ntv);
      self.parent_dispose_lock := nil;
      self._parent := parent;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    public property Parent: CLMemorySegment read CLMemorySegment.FromNative(_parent);
    
    {$endregion property's}
    
    {$region IDisposable}
    
    private procedure FinishReleasing(prev_ntv: cl_mem); override :=
    self.parent_dispose_lock := nil;
    
    {$endregion IDisposable}
    
  end;
  
  {$endregion CLMemorySubSegment}
  
  {$region CLValue}
  
  CLValue<T> = partial class(IDisposable)
  where T: record;
    private ntv: cl_mem;
    
    {$region constructor's}
    
    public constructor(c: Context);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE, new UIntPtr(ValueSize), IntPtr.Zero, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      GC.AddMemoryPressure(ValueSize);
    end;
    public constructor(c: Context; val: T);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE + MemFlags.MEM_COPY_HOST_PTR, new UIntPtr(ValueSize), val, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      GC.AddMemoryPressure(ValueSize);
    end;
    
    public constructor := Create(Context.Default);
    public constructor(val: T) := Create(Context.Default, val);
    
    public constructor(ntv: cl_mem);
    begin
      self.ntv := ntv;
      OpenCLABCInternalException.RaiseIfError( cl.RetainMemObject(ntv) );
      GC.AddMemoryPressure(ValueSize);
    end;
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static value_size := Marshal.SizeOf&<T>;
    public static property ValueSize: integer read value_size;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      GC.RemoveMemoryPressure(ValueSize);
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseMemObject(new cl_mem(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    {%ContainerMethods\CLValue\Implicit.Interface!ContainerMethods.pas%}
    
    {%ContainerMethods\CLValue.Get\Implicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  {$endregion CLValue}
  
  {$region CLArray}
  
  CLArray<T> = partial class(IDisposable)
  where T: record;
    private ntv: cl_mem;
    
    {$region constructor's}
    
    private procedure InitByLen(c: Context);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE, new UIntPtr(ByteSize), IntPtr.Zero, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      GC.AddMemoryPressure(ByteSize);
    end;
    private procedure InitByVal(c: Context; var els: T);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE + MemFlags.MEM_COPY_HOST_PTR, new UIntPtr(ByteSize), els, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      GC.AddMemoryPressure(ByteSize);
    end;
    
    public constructor(c: Context; len: integer);
    begin
      self.len := len;
      InitByLen(c);
    end;
    public constructor(len: integer) := Create(Context.Default, len);
    
    public constructor(c: Context; els: array of T);
    begin
      self.len := els.Length;
      InitByVal(c, els[0]);
    end;
    public constructor(els: array of T) := Create(Context.Default, els);
    
    public constructor(c: Context; els_from, len: integer; params els: array of T);
    begin
      self.len := len;
      InitByVal(c, els[els_from]);
    end;
    public constructor(els_from, len: integer; params els: array of T) := Create(Context.Default, els_from, len, els);
    
    public constructor(ntv: cl_mem);
    begin
      
      var byte_size: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(Marshal.SizeOf&<UIntPtr>), byte_size, IntPtr.Zero)
      );
      
      self.len := byte_size.ToUInt64 div Marshal.SizeOf&<T>;
      self.ntv := ntv;
      
      OpenCLABCInternalException.RaiseIfError( cl.RetainMemObject(ntv) );
      GC.AddMemoryPressure(ByteSize);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static item_size := Marshal.SizeOf&<T>;
    public static property ItemSize: integer read item_size;
    
    private len: integer;
    public property Length: integer read len;
    public property ByteSize: int64 read int64(len) * item_size;
    
    private function GetItemProp(ind: integer): T;
    private procedure SetItemProp(ind: integer; value: T);
    public property Item[ind: integer]: T read GetItemProp write SetItemProp; default;
    
    private function GetSliceProp(range: IntRange): array of T;
    private procedure SetSliceProp(range: IntRange; value: array of T);
    public property Slice[range: IntRange]: array of T read GetSliceProp write SetSliceProp;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      GC.RemoveMemoryPressure(ByteSize);
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseMemObject(new cl_mem(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    {%ContainerMethods\CLArray\Implicit.Interface!ContainerMethods.pas%}
    
    {%ContainerMethods\CLArray.Get\Implicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  {$endregion CLArray}
  
  {$endregion OpenCL}
  
  {$endregion Memory}
  
  {$region Common}
  
  {%Wrappers\Common!Wrappers.pas%}
  
  {$endregion Common}
  
  {$region Misc}
  
  Device = partial class
    
    private supported_split_modes: array of DevicePartitionProperty := nil;
    private function GetSSM: array of DevicePartitionProperty;
    begin
      if supported_split_modes=nil then supported_split_modes := {%>Properties.PartitionType!!} nil {%};
      Result := supported_split_modes;
    end;
    
    private function Split(params props: array of DevicePartitionProperty): array of SubDevice;
    begin
      if not GetSSM.Contains(props[0]) then
        raise new NotSupportedException($'%Err:Device:SplitNotSupported%');
      
      var c: UInt32;
      OpenCLABCInternalException.RaiseIfError( cl.CreateSubDevices(self.ntv, props, 0, IntPtr.Zero, c) );
      
      var res := new cl_device_id[int64(c)];
      OpenCLABCInternalException.RaiseIfError( cl.CreateSubDevices(self.ntv, props, c, res[0], IntPtr.Zero) );
      
      Result := res.ConvertAll(sdvc->new SubDevice(self.ntv, sdvc));
    end;
    
    public property CanSplitEqually: boolean read DevicePartitionProperty.DEVICE_PARTITION_EQUALLY in GetSSM;
    public function SplitEqually(CUCount: integer): array of SubDevice;
    begin
      if CUCount <= 0 then raise new ArgumentException($'%Err:Device:SplitCUCount%');
      Result := Split(
        DevicePartitionProperty.DEVICE_PARTITION_EQUALLY,
        DevicePartitionProperty.Create(CUCount),
        DevicePartitionProperty.Create(0)
      );
    end;
    
    public property CanSplitByCounts: boolean read DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS in GetSSM;
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
    
    public property CanSplitByAffinityDomain: boolean read DevicePartitionProperty.DEVICE_PARTITION_BY_AFFINITY_DOMAIN in GetSSM;
    public function SplitByAffinityDomain(affinity_domain: DeviceAffinityDomain) :=
    Split(
      DevicePartitionProperty.DEVICE_PARTITION_BY_AFFINITY_DOMAIN,
      DevicePartitionProperty.Create(new IntPtr(affinity_domain.val)),
      DevicePartitionProperty.Create(0)
    );
    
  end;
  
  {$endregion Misc}
  
  {$endregion Wrappers}
  
  {$region CommandQueue}
  
  {$region ToString}
  
  CommandQueueBase = abstract partial class
    
    private static function DisplayNameForType(t: System.Type): string;
    begin
      Result := t.Name;
      
      if t.IsGenericType then
      begin
        var ind := Result.IndexOf('`');
        Result := Result.Remove(ind) + '<' + t.GenericTypeArguments.Select(TypeToTypeName).JoinToString(', ') + '>';
      end;
      
    end;
    private function DisplayName: string; virtual := DisplayNameForType(self.GetType);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private static function GetValueRuntimeType<T>(val: T) :=
    if typeof(T).IsValueType then
      typeof(T) else
    if val = default(T) then
      nil else val.GetType;
    private static procedure ToStringRuntimeValue<T>(sb: StringBuilder; val: T);
    begin
      var rt := GetValueRuntimeType(val);
      if typeof(T) <> rt then
      begin
        if rt<>nil then sb.Append(TypeToTypeName(rt));
        sb += '{ ';
      end;
      if rt<>nil then
        sb.Append(_ObjectToString(val)) else
        sb += 'nil';
      if typeof(T) <> rt then
        sb += ' }';
    end;
    
    private function ToStringHeader(sb: StringBuilder; index: Dictionary<object,integer>): boolean;
    begin
      sb += DisplayName;
      
      var ind: integer;
      Result := not index.TryGetValue(self, ind);
      
      if Result then
      begin
        ind := index.Count;
        index[self] := ind;
      end;
      
      sb += '#';
      sb.Append(ind);
      
    end;
    private static procedure ToStringWriteDelegate(sb: StringBuilder; d: System.Delegate);
    const lambda='lambda';
    const sugar_begin='<>';
    const par_separator='; ';
    begin
      if d.Target<>nil then
      begin
        sb += _ObjectToString(d.Target);
        sb += ' => ';
      end;
      var mi := d.Method;
      var rt := mi.ReturnType;
      if rt=typeof(Void) then rt := nil;
      
      sb += if rt=nil then 'procedure' else 'function';
      sb += ' ';
      begin
        var name := mi.Name;
        if name.StartsWith(sugar_begin) then
          name := if lambda in name then
            lambda else name.Substring(sugar_begin.Length);
        sb += name;
      end;
      
      var pars := mi.GetParameters;
      if pars.Length<>0 then
      begin
        sb += '(';
        foreach var par in pars do
        begin
          var name := par.Name;
          if name.StartsWith(sugar_begin) then
            name := name.Substring(sugar_begin.Length);
          sb += name;
          sb += ': ';
          sb += TypeToTypeName(par.ParameterType);
          sb += par_separator;
        end;
        sb.Length -= par_separator.Length;
        sb += ')';
      end;
      
      if rt<>nil then
      begin
        sb += ': ';
        sb += TypeToTypeName(rt);
      end;
      
    end;
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
    begin
      delayed.Remove(self);
      
      if write_tabs then sb.Append(#9, tabs);
      ToStringHeader(sb, index);
      ToStringImpl(sb, tabs+1, index, delayed);
      
      if tabs=0 then foreach var q in delayed do
      begin
        sb += #10;
        q.ToString(sb, 0, index, new HashSet<CommandQueueBase>);
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      ToString(sb, 0, new Dictionary<object, integer>, new HashSet<CommandQueueBase>);
      Result := sb.ToString;
    end;
    
    public function Print: CommandQueueBase;
    begin
      Write(self.ToString);
      Result := self;
    end;
    public function Println: CommandQueueBase;
    begin
      Writeln(self.ToString);
      Result := self;
    end;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public function Print: CommandQueueNil;
    begin
      inherited Print;
      Result := self;
    end;
    public function Println: CommandQueueNil;
    begin
      inherited Println;
      Result := self;
    end;
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public function Print: CommandQueue<T>;
    begin
      inherited Print;
      Result := self;
    end;
    public function Println: CommandQueue<T>;
    begin
      inherited Println;
      Result := self;
    end;
    
  end;
  
  {$endregion ToString}
  
  {$region Use/Convert Typed}
  
  ITypedCQUser = interface
    
    procedure UseNil(cq: CommandQueueNil);
    procedure Use<T>(cq: CommandQueue<T>);
    
  end;
  ITypedCQConverter<TRes> = interface
    
    function ConvertNil(cq: CommandQueueNil): TRes;
    function Convert<T>(cq: CommandQueue<T>): TRes;
    
  end;
  
  CommandQueueBase = abstract partial class
    
    public procedure UseTyped(user: ITypedCQUser); abstract;
    public function ConvertTyped<TRes>(converter: ITypedCQConverter<TRes>): TRes; abstract;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public procedure UseTyped(user: ITypedCQUser); override := user.UseNil(self);
    public function ConvertTyped<TRes>(converter: ITypedCQConverter<TRes>): TRes; override := converter.ConvertNil(self);
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public procedure UseTyped(user: ITypedCQUser); override := user.Use(self);
    public function ConvertTyped<TRes>(converter: ITypedCQConverter<TRes>): TRes; override := converter.Convert(self);
    
  end;
  
  {$endregion Use/Convert Typed}
  
  {$region Const}
  
  ConstQueue<T> = sealed partial class(CommandQueue<T>)
    private res: T;
    
    public constructor(o: T) := self.res := o;
    private constructor := raise new OpenCLABCInternalException;
    
    public property Value: T read res write res;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.res);
      sb += #10;
    end;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase) end;
  CommandQueue<T> = abstract partial class
    
    public static function operator implicit(o: T): CommandQueue<T> :=
    new ConstQueue<T>(o);
    
  end;
  
  {$endregion Const}
  
  {$region Parameter}
  
  ParameterQueueSetter = sealed partial class
    private val: object;
    
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  ParameterQueue<T> = sealed partial class(CommandQueue<T>)
    private _name: string;
    private def: T;
    private def_is_set: boolean;
    
    public constructor(name: string);
    begin
      self._name := name;
      self.def_is_set := false;
    end;
    public constructor(name: string; def: T);
    begin
      self.name := name;
      self.def := def;
      self.def_is_set := true;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public property Name: string read _name write _name;
    public property DefaultDefined: boolean read def_is_set;
    
    private function GetDefault: T;
    begin
      if not def_is_set then
        raise new InvalidOperationException($'%Err:Parameter:UnSet%');
      Result := self.def;
    end;
    public property &Default: T read def write
    begin
      self.def := value;
      self.def_is_set := true;
    end;
    
    public function NewSetter(val: T): ParameterQueueSetter;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += '["';
      sb += Name;
      sb += '"]: Default=';
      ToStringRuntimeValue(sb, self.def);
      sb += #10;
    end;
    
  end;
  
  {$endregion Parameter}
  
  {$region Cast}
  
  CommandQueueBase = abstract partial class
    
    public function Cast<T>: CommandQueue<T>;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public function Cast<T>: CommandQueue<T>; where T: class;
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase) end;
  
  {$endregion Cast}
  
  {$region DiscardResult}
  
  CommandQueueBase = abstract partial class
    
    private function DiscardResultBase: CommandQueueNil; abstract;
    public function DiscardResult := DiscardResultBase;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    private function DiscardResultBase: CommandQueueNil; override := DiscardResult;
    public function DiscardResult := self;
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function DiscardResultBase: CommandQueueNil; override := DiscardResult;
    public function DiscardResult: CommandQueueNil;
    
  end;
  
  {$endregion DiscardResult}
  
  {$region ThenConvert}
  
  CommandQueueBase = abstract partial class
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase) end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public function ThenConvert<TOtp>(f: T->TOtp): CommandQueue<TOtp>;
    public function ThenConvert<TOtp>(f: (T, Context)->TOtp): CommandQueue<TOtp>;
    
    public function ThenUse(p: T->()           ): CommandQueue<T>;
    public function ThenUse(p: (T, Context)->()): CommandQueue<T>;
    
    public function ThenQuickConvert<TOtp>(f: T->TOtp): CommandQueue<TOtp>;
    public function ThenQuickConvert<TOtp>(f: (T, Context)->TOtp): CommandQueue<TOtp>;
    
    public function ThenQuickUse(p: T->()           ): CommandQueue<T>;
    public function ThenQuickUse(p: (T, Context)->()): CommandQueue<T>;
    
  end;
  
  {$endregion ThenConvert}
  
  {$region +/*}
  
  CommandQueueBase = abstract partial class
    
    private function  AfterQueueSyncBase(q: CommandQueueBase): CommandQueueBase; abstract;
    private function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; abstract;
    
    public static function operator+(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueSyncBase(q1);
    public static function operator*(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueAsyncBase(q1);
    
    public static procedure operator+=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1*q2;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    private function  AfterQueueSyncBase(q: CommandQueueBase): CommandQueueBase; override := q+self;
    private function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; override := q*self;
    
    public static function operator+(q1: CommandQueueBase; q2: CommandQueueNil): CommandQueueNil;
    public static function operator*(q1: CommandQueueBase; q2: CommandQueueNil): CommandQueueNil;
    
    public static procedure operator+=(var q1: CommandQueueNil; q2: CommandQueueNil) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueueNil; q2: CommandQueueNil) := q1 := q1*q2;
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function AfterQueueSyncBase (q: CommandQueueBase): CommandQueueBase; override := q+self;
    private function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; override := q*self;
    
    public static function operator+(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    public static function operator*(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    
    public static procedure operator+=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1*q2;
    
  end;
  
  {$endregion +/*}
  
  {$region Multiusable}
  
  CommandQueueBase = abstract partial class
    
    private function MultiusableBase: ()->CommandQueueBase; abstract;
    public function Multiusable := MultiusableBase;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    private function MultiusableBase: ()->CommandQueueBase; override := Multiusable() as object as Func<CommandQueueBase>; //TODO #2221
    public function Multiusable: ()->CommandQueueNil;
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function MultiusableBase: ()->CommandQueueBase; override := Multiusable() as object as Func<CommandQueueBase>; //TODO #2221
    public function Multiusable: ()->CommandQueue<T>;
    
  end;
  
  {$endregion Multiusable}
  
  {$region Finally+Handle}
  
  CommandQueueBase = abstract partial class
    
    private function AfterTry(try_do: CommandQueueBase): CommandQueueBase; abstract;
    public static function operator>=(try_do, do_finally: CommandQueueBase) := do_finally.AfterTry(try_do);
    
    private function ConvertErrHandler<TException>(handler: TException->boolean): Exception->boolean; where TException: Exception;
    begin Result := e->(e is TException) and handler(TException(e)) end;
    
    public function HandleWithoutRes<TException>(handler: TException->boolean): CommandQueueNil; where TException: Exception;
    begin Result := HandleWithoutRes(ConvertErrHandler(handler)) end;
    public function HandleWithoutRes(handler: Exception->boolean): CommandQueueNil;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    private function AfterTry(try_do: CommandQueueBase): CommandQueueBase; override := try_do >= self;
    public static function operator>=(try_do: CommandQueueBase; do_finally: CommandQueueNil): CommandQueueNil;
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function AfterTry(try_do: CommandQueueBase): CommandQueueBase; override := try_do >= self;
    public static function operator>=(try_do: CommandQueueBase; do_finally: CommandQueue<T>): CommandQueue<T>;
    
    public function HandleDefaultRes<TException>(handler: TException->boolean; def: T): CommandQueue<T>; where TException: Exception;
    begin Result := HandleDefaultRes(ConvertErrHandler(handler), def) end;
    public function HandleDefaultRes(handler: Exception->boolean; def: T): CommandQueue<T>;
    
    public function HandleReplaceRes(handler: List<Exception> -> T): CommandQueue<T>;
    
  end;
  
  {$endregion Finally+Handle}
  
  {$region Wait}
  
  WaitMarker = abstract partial class
    
    public static function Create: WaitMarker;
    
    public procedure SendSignal; abstract;
    
    public static function operator and(m1, m2: WaitMarker): WaitMarker;
    public static function operator or(m1, m2: WaitMarker): WaitMarker;
    
    private function ConvertToQBase: CommandQueueBase; abstract;
    public static function operator implicit(m: WaitMarker): CommandQueueBase := m.ConvertToQBase;
    
    {$region ToString}
    
    private function ToStringHeader(sb: StringBuilder; index: Dictionary<object,integer>): boolean;
    begin
      sb += DisplayName;
      
      var ind: integer;
      Result := not index.TryGetValue(self, ind);
      
      if Result then
      begin
        ind := index.Count;
        index[self] := ind;
      end;
      
      sb += '#';
      sb.Append(ind);
      
    end;
    private function DisplayName: string; virtual := CommandQueueBase.DisplayNameForType(self.GetType);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
    begin
      if write_tabs then sb.Append(#9, tabs);
      ToStringHeader(sb, index);
      ToStringImpl(sb, tabs+1, index, delayed);
      
      if tabs=0 then foreach var q in delayed do
      begin
        sb += #10;
        q.ToString(sb, 0, index, new HashSet<CommandQueueBase>);
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      ToString(sb, 0, new Dictionary<object, integer>, new HashSet<CommandQueueBase>);
      Result := sb.ToString;
    end;
    
    public function Print: WaitMarker;
    begin
      Write(self.ToString);
      Result := self;
    end;
    public function Println: WaitMarker;
    begin
      Writeln(self.ToString);
      Result := self;
    end;
    
    {$endregion ToString}
    
  end;
  
  DetachedMarkerSignalNil = sealed partial class
    
    private function get_signal_in_finally: boolean;
    public property SignalInFinally: boolean read get_signal_in_finally;
    
    public constructor(q: CommandQueueNil; signal_in_finally: boolean);
    private constructor := raise new OpenCLABCInternalException;
    
    public static function operator implicit(dms: DetachedMarkerSignalNil): WaitMarker;
    
    public procedure SendSignal := WaitMarker(self).SendSignal;
    public static function operator and(m1, m2: DetachedMarkerSignalNil) := WaitMarker(m1) and WaitMarker(m2);
    public static function operator or(m1, m2: DetachedMarkerSignalNil) := WaitMarker(m1) or WaitMarker(m2);
    
  end;
  DetachedMarkerSignal<T> = sealed partial class
    
    private function get_signal_in_finally: boolean;
    public property SignalInFinally: boolean read get_signal_in_finally;
    
    public constructor(q: CommandQueue<T>; signal_in_finally: boolean);
    private constructor := raise new OpenCLABCInternalException;
    
    public static function operator implicit(dms: DetachedMarkerSignal<T>): WaitMarker;
    
    public procedure SendSignal := WaitMarker(self).SendSignal;
    public static function operator and(m1, m2: DetachedMarkerSignal<T>) := WaitMarker(m1) and WaitMarker(m2);
    public static function operator or(m1, m2: DetachedMarkerSignal<T>) := WaitMarker(m1) or WaitMarker(m2);
    
  end;
  
  CommandQueueBase = abstract partial class end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public function ThenMarkerSignal := new DetachedMarkerSignalNil(self, false);
    public function ThenFinallyMarkerSignal := new DetachedMarkerSignalNil(self, true);
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public function ThenMarkerSignal := new DetachedMarkerSignal<T>(self, false);
    public function ThenFinallyMarkerSignal := new DetachedMarkerSignal<T>(self, true);
    
    public function ThenWaitFor(marker: WaitMarker): CommandQueue<T>;
    public function ThenFinallyWaitFor(marker: WaitMarker): CommandQueue<T>;
    
  end;
  
  {$endregion Wait}
  
  {$endregion CommandQueue}
  
  {$region CLTask}
  
  CLTaskBase = abstract partial class
    private org_c: Context;
    private wh := new ManualResetEvent(false);
    private err_lst: List<Exception>;
    
    private function OrgQueueBase: CommandQueueBase; abstract;
    public property OrgQueue: CommandQueueBase read OrgQueueBase;
    
    public property OrgContext: Context read org_c;
    
    public procedure Wait;
    begin
      wh.WaitOne;
      if err_lst.Count=0 then exit;
      raise new AggregateException($'%Err:CLTask:%', err_lst.ToArray);
    end;
    
  end;
  
  CLTaskNil = sealed partial class(CLTaskBase)
    private q: CommandQueueNil;
    
    private constructor := raise new OpenCLABCInternalException;
    
    public property OrgQueue: CommandQueueNil read q; reintroduce;
    private function OrgQueueBase: CommandQueueBase; override := self.OrgQueue;
    
  end;
  
  CLTask<T> = sealed partial class(CLTaskBase)
    private q: CommandQueue<T>;
    
    private constructor := raise new OpenCLABCInternalException;
    
    public property OrgQueue: CommandQueue<T> read q; reintroduce;
    private function OrgQueueBase: CommandQueueBase; override := self.OrgQueue;
    
    public function WaitRes: T;
    
  end;
  
  Context = partial class
    
    public function BeginInvoke(q: CommandQueueBase; params parameters: array of ParameterQueueSetter): CLTaskBase;
    public function BeginInvoke(q: CommandQueueNil; params parameters: array of ParameterQueueSetter): CLTaskNil;
    public function BeginInvoke<T>(q: CommandQueue<T>; params parameters: array of ParameterQueueSetter): CLTask<T>;
    
    public procedure SyncInvoke(q: CommandQueueBase; params parameters: array of ParameterQueueSetter) := BeginInvoke(q, parameters).Wait;
    public procedure SyncInvoke(q: CommandQueueNil; params parameters: array of ParameterQueueSetter) := BeginInvoke(q, parameters).Wait;
    public function SyncInvoke<T>(q: CommandQueue<T>; params parameters: array of ParameterQueueSetter) := BeginInvoke(q, parameters).WaitRes;
    
  end;
  
  {$endregion CLTask}
  
  {$region KernelArg}
  
  KernelArg = abstract partial class
    
    {$region Managed}
    
    {$region Value}
    
    public static function FromValue<TRecord>(val: TRecord): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(val: TRecord): KernelArg; where TRecord: record; begin Result := FromValue(val); end;
    
    public static function FromValueCQ<TRecord>(val_q: CommandQueue<TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(val_q: CommandQueue<TRecord>): KernelArg; where TRecord: record; begin Result := FromValueCQ(val_q); end;
    public static function operator implicit<TRecord>(val_q: ConstQueue<TRecord>): KernelArg; where TRecord: record; begin Result := FromValueCQ(val_q); end;
    public static function operator implicit<TRecord>(val_q: ParameterQueue<TRecord>): KernelArg; where TRecord: record; begin Result := FromValueCQ(val_q); end;
    
    {$endregion Value}
    
    {$region Array}
    
    {$region 1}
    
    public static function FromArray<TRecord>(a: array of TRecord): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a: array of TRecord): KernelArg; where TRecord: record; begin Result := FromArray(a); end;
    
    public static function FromArrayCQ<TRecord>(a_q: CommandQueue<array of TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a_q: CommandQueue<array of TRecord>): KernelArg; where TRecord: record; begin Result := FromArrayCQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ConstQueue<array of TRecord>): KernelArg; where TRecord: record; begin Result := FromArrayCQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ParameterQueue<array of TRecord>): KernelArg; where TRecord: record; begin Result := FromArrayCQ(a_q); end;
    
    {$endregion 1}
    
    {$region 2}
    
    public static function FromArray2<TRecord>(a: array[,] of TRecord): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a: array[,] of TRecord): KernelArg; where TRecord: record; begin Result := FromArray2(a); end;
    
    public static function FromArray2CQ<TRecord>(a_q: CommandQueue<array[,] of TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a_q: CommandQueue<array[,] of TRecord>): KernelArg; where TRecord: record; begin Result := FromArray2CQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ConstQueue<array[,] of TRecord>): KernelArg; where TRecord: record; begin Result := FromArray2CQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ParameterQueue<array[,] of TRecord>): KernelArg; where TRecord: record; begin Result := FromArray2CQ(a_q); end;
    
    {$endregion 2}
    
    {$region 3}
    
    public static function FromArray3<TRecord>(a: array[,,] of TRecord): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a: array[,,] of TRecord): KernelArg; where TRecord: record; begin Result := FromArray3(a); end;
    
    public static function FromArray3CQ<TRecord>(a_q: CommandQueue<array[,,] of TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a_q: CommandQueue<array[,,] of TRecord>): KernelArg; where TRecord: record; begin Result := FromArray3CQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ConstQueue<array[,,] of TRecord>): KernelArg; where TRecord: record; begin Result := FromArray3CQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ParameterQueue<array[,,] of TRecord>): KernelArg; where TRecord: record; begin Result := FromArray3CQ(a_q); end;
    
    {$endregion 3}
    
    {$endregion Array}
    
    {$region ArraySegment}
    
    public static function FromArraySegment<TRecord>(a: ArraySegment<TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a: ArraySegment<TRecord>): KernelArg; where TRecord: record; begin Result := FromArraySegment(a); end;
    
    public static function FromArraySegmentCQ<TRecord>(a_q: CommandQueue<ArraySegment<TRecord>>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a_q: CommandQueue<ArraySegment<TRecord>>): KernelArg; where TRecord: record; begin Result := FromArraySegmentCQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ConstQueue<ArraySegment<TRecord>>): KernelArg; where TRecord: record; begin Result := FromArraySegmentCQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ParameterQueue<ArraySegment<TRecord>>): KernelArg; where TRecord: record; begin Result := FromArraySegmentCQ(a_q); end;
    
    {$endregion ArraySegment}
    
    {$endregion Managed}
    
    {$region Native}
    
    {$region NativeMemoryArea}
    
    public static function FromData(data: NativeMemoryArea): KernelArg;
    public static function operator implicit(data: NativeMemoryArea): KernelArg := FromData(data);
    public static function operator implicit<TRecord>(ptr: ^TRecord): KernelArg; where TRecord: record;
    
    public static function FromDataCQ(data_q: CommandQueue<NativeMemoryArea>): KernelArg;
    public static function operator implicit(data_q: CommandQueue<NativeMemoryArea>): KernelArg := FromDataCQ(data_q);
    
    {$endregion NativeMemoryArea}
    
    {$region NativeValue}
    
    public static function FromNativeValue<TRecord>(val: NativeValue<TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(val: NativeValue<TRecord>): KernelArg; where TRecord: record; begin Result := FromNativeValue(val); end;
    
    public static function FromNativeValueCQ<TRecord>(val_q: CommandQueue<NativeValue<TRecord>>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(val_q: CommandQueue<NativeValue<TRecord>>): KernelArg; where TRecord: record; begin Result := FromNativeValueCQ(val_q); end;
    public static function operator implicit<TRecord>(val_q: ConstQueue<NativeValue<TRecord>>): KernelArg; where TRecord: record; begin Result := FromNativeValueCQ(val_q); end;
    public static function operator implicit<TRecord>(val_q: ParameterQueue<NativeValue<TRecord>>): KernelArg; where TRecord: record; begin Result := FromNativeValueCQ(val_q); end;
    
    {$endregion NativeValue}
    
    {$region NativeArray}
    
    public static function FromNativeArray<TRecord>(a: NativeArray<TRecord>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a: NativeArray<TRecord>): KernelArg; where TRecord: record; begin Result := FromNativeArray(a); end;
    
    public static function FromNativeArrayCQ<TRecord>(a_q: CommandQueue<NativeArray<TRecord>>): KernelArg; where TRecord: record;
    public static function operator implicit<TRecord>(a_q: CommandQueue<NativeArray<TRecord>>): KernelArg; where TRecord: record; begin Result := FromNativeArrayCQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ConstQueue<NativeArray<TRecord>>): KernelArg; where TRecord: record; begin Result := FromNativeArrayCQ(a_q); end;
    public static function operator implicit<TRecord>(a_q: ParameterQueue<NativeArray<TRecord>>): KernelArg; where TRecord: record; begin Result := FromNativeArrayCQ(a_q); end;
    
    {$endregion NativeArray}
    
    {$endregion Native}
    
    {$region OpenCL}
    
    {$region CLMemorySegment}
    
    public static function FromCLMemorySegment(mem: CLMemorySegment): KernelArg;
    public static function operator implicit(mem: CLMemorySegment): KernelArg := FromCLMemorySegment(mem);
    public static function operator implicit(mem: CLMemorySubSegment): KernelArg := FromCLMemorySegment(mem);
    
    public static function FromCLMemorySegmentCQ(mem_q: CommandQueue<CLMemorySegment>): KernelArg;
    public static function operator implicit(mem_q: CommandQueue<CLMemorySegment>): KernelArg := FromCLMemorySegmentCQ(mem_q);
    public static function operator implicit(mem_q: ConstQueue<CLMemorySegment>): KernelArg := FromCLMemorySegmentCQ(mem_q);
    public static function operator implicit(mem_q: ParameterQueue<CLMemorySegment>): KernelArg := FromCLMemorySegmentCQ(mem_q);
    
    {$endregion CLMemorySegment}
    
    {$region CLValue}
    
    public static function FromCLValue<T>(val: CLValue<T>): KernelArg; where T: record;
    public static function operator implicit<T>(val: CLValue<T>): KernelArg; where T: record; begin Result := FromCLValue(val); end;
    
    public static function FromCLValueCQ<T>(val_q: CommandQueue<CLValue<T>>): KernelArg; where T: record;
    public static function operator implicit<T>(val_q: CommandQueue<CLValue<T>>): KernelArg; where T: record; begin Result := FromCLValueCQ(val_q); end;
    public static function operator implicit<T>(val_q: ConstQueue<CLValue<T>>): KernelArg; where T: record; begin Result := FromCLValueCQ(val_q); end;
    public static function operator implicit<T>(val_q: ParameterQueue<CLValue<T>>): KernelArg; where T: record; begin Result := FromCLValueCQ(val_q); end;
    
    {$endregion CLValue}
    
    {$region CLArray}
    
    public static function FromCLArray<T>(a: CLArray<T>): KernelArg; where T: record;
    public static function operator implicit<T>(a: CLArray<T>): KernelArg; where T: record; begin Result := FromCLArray(a); end;
    
    public static function FromCLArrayCQ<T>(a_q: CommandQueue<CLArray<T>>): KernelArg; where T: record;
    public static function operator implicit<T>(a_q: CommandQueue<CLArray<T>>): KernelArg; where T: record; begin Result := FromCLArrayCQ(a_q); end;
    public static function operator implicit<T>(a_q: ConstQueue<CLArray<T>>): KernelArg; where T: record; begin Result := FromCLArrayCQ(a_q); end;
    public static function operator implicit<T>(a_q: ParameterQueue<CLArray<T>>): KernelArg; where T: record; begin Result := FromCLArrayCQ(a_q); end;
    
    {$endregion CLArray}
    
    {$endregion OpenCL}
    
    {$region ToString}
    
    private function DisplayName: string; virtual := CommandQueueBase.DisplayNameForType(self.GetType);
    private static procedure ToStringRuntimeValue<T>(sb: StringBuilder; val: T) := CommandQueueBase.ToStringRuntimeValue(sb, val);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
    begin
      if write_tabs then sb.Append(#9, tabs);
      sb += DisplayName;
      
      ToStringImpl(sb, tabs+1, index, delayed);
      
      if tabs=0 then foreach var q in delayed do
      begin
        sb += #10;
        q.ToString(sb, 0, index, new HashSet<CommandQueueBase>);
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      ToString(sb, 0, new Dictionary<object, integer>, new HashSet<CommandQueueBase>);
      Result := sb.ToString;
    end;
    
    public function Print: KernelArg;
    begin
      Write(self.ToString);
      Result := self;
    end;
    public function Println: KernelArg;
    begin
      Writeln(self.ToString);
      Result := self;
    end;
    
    {$endregion ToString}
    
  end;
  
  {$endregion KernelArg}
  
  {$region CCQ's}
  
  {$region KernelCCQ}
  
  KernelCCQ = sealed partial class
    
    {%ContainerCommon\Kernel\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\Kernel\Explicit.Interface!ContainerMethods.pas%}
    
  end;
  
  Kernel = partial class
    public function NewQueue := new KernelCCQ({%>self%});
  end;
  
  {$endregion KernelCCQ}
  
  {$region MemorySegmentCCQ}
  
  CLMemorySegmentCCQ = sealed partial class
    
    {%ContainerCommon\CLMemorySegment\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLMemorySegment\Explicit.Interface!ContainerMethods.pas%}
    
    {%ContainerMethods\CLMemorySegment.Get\Explicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  CLMemorySegment = partial class
    public function NewQueue := new CLMemorySegmentCCQ({%>self%});
  end;
  
  KernelArg = abstract partial class
    public static function operator implicit(mem_q: CLMemorySegmentCCQ): KernelArg;
  end;
  
  {$endregion MemorySegmentCCQ}
  
  {$region CLValueCCQ}
  
  CLValueCCQ<T> = sealed partial class
  where T: record;
    
    {%ContainerCommon\CLValue\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLValue\Explicit.Interface!ContainerMethods.pas%}
    
    {%ContainerMethods\CLValue.Get\Explicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  CLValue<T> = partial class
    public function NewQueue := new CLValueCCQ<T>({%>self%});
  end;
  
  KernelArg = abstract partial class
    public static function operator implicit<T>(val_q: CLValueCCQ<T>): KernelArg; where T: record;
  end;
  
  {$endregion CLValueCCQ}
  
  {$region CLArrayCCQ}
  
  CLArrayCCQ<T> = sealed partial class
  where T: record;
    
    {%ContainerCommon\CLArray\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLArray\Explicit.Interface!ContainerMethods.pas%}
    
    {%ContainerMethods\CLArray.Get\Explicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  CLArray<T> = partial class
    public function NewQueue := new CLArrayCCQ<T>({%>self%});
  end;
  
  KernelArg = abstract partial class
    public static function operator implicit<T>(a_q: CLArrayCCQ<T>): KernelArg; where T: record;
  end;
  
  {$endregion CLArrayCCQ}
  
  {$endregion CCQ's}
  
{$region Global subprograms}

{$region ConstQueue}

function CQ<T>(o: T): CommandQueue<T>;

{$endregion ConstQueue}

{$region HFQ/HPQ}

function HFQ<T>(f: ()->T): CommandQueue<T>;
function HFQ<T>(f: Context->T): CommandQueue<T>;
function HFQQ<T>(f: ()->T): CommandQueue<T>;
function HFQQ<T>(f: Context->T): CommandQueue<T>;

function HPQ(p: ()->()): CommandQueueNil;
function HPQ(p: Context->()): CommandQueueNil;
function HPQQ(p: ()->()): CommandQueueNil;
function HPQQ(p: Context->()): CommandQueueNil;

{$endregion HFQ/HPQ}

{$region Wait}

function WaitAll(params sub_markers: array of WaitMarker): WaitMarker;
function WaitAll(sub_markers: sequence of WaitMarker): WaitMarker;

function WaitAny(params sub_markers: array of WaitMarker): WaitMarker;
function WaitAny(sub_markers: sequence of WaitMarker): WaitMarker;

function WaitFor(marker: WaitMarker): CommandQueueNil;

{$endregion Wait}

{$region CombineQueue's}

{%CombineQueues\Interface!CombineQueues.pas%}

{$endregion CombineQueue's}

{$endregion Global subprograms}

implementation

{$region Properties}

{$region Base}

type
  NtvPropertiesBase<TNtv, TInfo> = abstract class
    protected ntv: TNtv;
    public constructor(ntv: TNtv) := self.ntv := ntv;
    private constructor := raise new OpenCLABCInternalException;
    
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
//    protected function GetValArrArr<T>(id: TInfo; szs: array of UIntPtr): array of array of T;
//    type PT = ^T;
//    begin
//      if szs.Length=0 then
//      begin
//        SetLength(Result,0);
//        exit;
//      end;
//      
//      var res := new IntPtr[szs.Length];
//      SetLength(Result, szs.Length);
//      
//      for var i := 0 to szs.Length-1 do res[i] := Marshal.AllocHGlobal(IntPtr(pointer(szs[i])));
//      try
//        
//        FillVal(id, new UIntPtr(szs.Length*Marshal.SizeOf&<IntPtr>), res[0]);
//        
//        var tsz := Marshal.SizeOf&<T>;
//        for var i := 0 to szs.Length-1 do
//        begin
//          Result[i] := new T[uint64(szs[i]) div tsz];
//          //To Do более эффективное копирование
//          for var i2 := 0 to Result[i].Length-1 do
//            Result[i][i2] := PT(pointer(res[i]+tsz*i2))^;
//        end;
//        
//      finally
//        for var i := 0 to szs.Length-1 do Marshal.FreeHGlobal(res[i]);
//      end;
//      
//    end;
    
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
    
  end;
  
{$endregion Base}

{%WrapperProperties\Implementation!WrapperProperties.pas%}

{$endregion Properties}

{$region Wrappers}

{$region Device}

static function Device.FromNative(ntv: cl_device_id): Device;
begin
  
  var parent: cl_device_id;
  OpenCLABCInternalException.RaiseIfError(
    cl.GetDeviceInfo(ntv, DeviceInfo.DEVICE_PARENT_DEVICE, new UIntPtr(cl_device_id.Size), parent, IntPtr.Zero)
  );
  
  if parent=cl_device_id.Zero then
    Result := new Device(ntv) else
    Result := new SubDevice(parent, ntv);
  
end;

{$endregion Device}

{$region CLMemorySegment}

static function CLMemorySegment.FromNative(ntv: cl_mem): CLMemorySegment;
begin
  var t: MemObjectType;
  OpenCLABCInternalException.RaiseIfError(
    cl.GetMemObjectInfo(ntv, MemInfo.MEM_TYPE, new UIntPtr(sizeof(MemObjectType)), t, IntPtr.Zero)
  );
  
  if t<>MemObjectType.MEM_OBJECT_BUFFER then
    raise new ArgumentException($'%Err:CLMemorySegment:WrongNtvType%');
  
  var parent: cl_mem;
  OpenCLABCInternalException.RaiseIfError(
    cl.GetMemObjectInfo(ntv, MemInfo.MEM_ASSOCIATED_MEMOBJECT, new UIntPtr(cl_mem.Size), parent, IntPtr.Zero)
  );
  
  if parent=cl_mem.Zero then
  begin
    Result := new CLMemorySegment(ntv);
    GC.AddMemoryPressure(Result.Size64);
  end else
    Result := new CLMemorySubSegment(parent, ntv);
  
end;

{$endregion CLMemorySegment}

{$region CLArray}

function CLArray<T>.GetItemProp(ind: integer): T :=
{%>GetValue(ind)!!} default(T) {%};
procedure CLArray<T>.SetItemProp(ind: integer; value: T) :=
{%>WriteValue(value, ind)!!} exit() {%};

function CLArray<T>.GetSliceProp(range: IntRange): array of T;
begin
  Result := new T[range.High-range.Low+1];
  {%>ReadArray(Result, 0,Result.Length, range.Low);%}
end;
procedure CLArray<T>.SetSliceProp(range: IntRange; value: array of T) :=
{%>WriteArray(value, range.Low, range.High-range.Low+1, 0)!!} exit() {%};

{$endregion CLArray}

{$endregion Wrappers}

{$region Util type's}

{$region Blittable}

type
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
      
      foreach var fld in t.GetFields(System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.Public or System.Reflection.BindingFlags.NonPublic) do
        if fld.FieldType<>t then
        begin
          Result := Blame(fld.FieldType);
          if Result<>nil then break;
        end;
      
      if Result=nil then
      begin
        var o := System.Activator.CreateInstance(t);
        try
          GCHandle.Alloc(o, GCHandleType.Pinned).Free;
        except
          on System.ArgumentException do
            Result := t;
        end;
      end;
      
      blittable_cache[t] := Result;
    end;
    
    public static procedure RaiseIfBad(t: System.Type; source_name: string);
    begin
      var blame := BlittableHelper.Blame(t);
      if blame=nil then exit;
      raise new BlittableException(t, blame, source_name);
    end;
    
  end;
  
  NativeValue<T> = partial class
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(T), '%Err:Blittable:Source:NativeValue%');
  end;
  NativeArray<T> = partial class
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(T), '%Err:Blittable:Source:NativeArray%');
  end;
  
  CLValue<T> = partial class
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(T), '%Err:Blittable:Source:CLValue%');
  end;
  CLArray<T> = partial class
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(T), '%Err:Blittable:Source:CLArray%');
  end;
  
{$endregion Blittable}

{$region InterlockedBoolean}

type
  InterlockedBoolean = record
    private val := 0;
    
    public function TrySet(b: boolean): boolean;
    begin
      var prev := integer(not b);
      var curr := integer(b);
      Result := Interlocked.CompareExchange(val, curr, prev)=prev;
    end;
    
    public static function operator implicit(b: InterlockedBoolean): boolean := b.val<>0;
    
  end;
  
{$endregion InterlockedBoolean}

{$region NativeUtils}

type
  NativeUtils = static class
    
    public static function AsPtr<T>(p: pointer): ^T := p;
    public static function AsPtr<T>(p: IntPtr) := AsPtr&<T>(pointer(p));
    
    public static function CopyToUnm<TRecord>(a: TRecord): IntPtr; where TRecord: record;
    begin
      Result := Marshal.AllocHGlobal(Marshal.SizeOf&<TRecord>);
      AsPtr&<TRecord>(Result)^ := a;
    end;
    
    public static function StartNewBgThread(p: Action): Thread;
    begin
      Result := new Thread(p);
      Result.IsBackground := true;
      Result.Start;
    end;
    
  end;
  
{$endregion NativeUtils}

{$region CLTaskErrHandler}

type
  CLTaskErrHandler = abstract class
    private local_err_lst := new List<Exception>;
    
    {$region AddErr}
    
    protected procedure AddErr(e: Exception);
    begin
      if e is OpenCLABCInternalException then
        // Внутренние ошибки не регестрируем
        System.Runtime.ExceptionServices.ExceptionDispatchInfo.Capture(e).Throw;
      // HPQ(()->exit()) + HPQ(()->raise)
      // Тут сначала вычисляет HadError как false, а затем переключает на true
      had_error_cache := true;
      local_err_lst += e;
    end;
    
    {$endregion AddErr}
    
    function get_local_err_lst: List<Exception>;
    begin
      had_error_cache := nil;
      Result := local_err_lst;
    end;
    
    private had_error_cache := default(boolean?);
    protected function HadErrorInPrev: boolean; abstract;
    public function HadErrorWithoutCache: boolean;
    begin
      if had_error_cache<>nil then
      begin
        Result := had_error_cache.Value;
        exit;
      end;
      Result := (local_err_lst.Count<>0) or HadErrorInPrev;
    end;
    public function HadError: boolean;
    begin
      Result := HadErrorWithoutCache;
      had_error_cache := Result;
    end;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; abstract;
    protected function TryRemoveErrors(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean;
    begin
      Result := false;
      if had_error_cache=false then exit;
      
      Result := TryRemoveErrorsInPrev(origin_cache, handler);
      
      Result := (local_err_lst.RemoveAll(handler)<>0) or Result;
      if Result then had_error_cache := nil;
    end;
    public procedure TryRemoveErrors(handler: Exception->boolean) :=
    TryRemoveErrors(new Dictionary<CLTaskErrHandler, boolean>, handler);
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); abstract;
    protected procedure FillErrLst(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>);
    begin
      {$ifndef DEBUG}
      if not HadError then exit;
      {$endif DEBUG}
      
      FillErrLstWithPrev(origin_cache, lst);
      
      lst.AddRange(local_err_lst);
    end;
    public procedure FillErrLst(lst: List<Exception>) :=
    FillErrLst(new HashSet<CLTaskErrHandler>, lst);
    
    public procedure SanityCheck(err_lst: List<Exception>);
    begin
      
      // QErr*QErr - second cache wouldn't be calculated
//      if had_error_cache=nil then
//        raise new OpenCLABCInternalException($'SanityCheck expects all had_error_cache to exist');
      
      begin
        var had_error := self.HadError;
        if had_error <> (err_lst.Count<>0) then
          raise new OpenCLABCInternalException($'{had_error} <> {err_lst.Count}');
      end;
      
    end;
    
  end;
  
  CLTaskErrHandlerEmpty = sealed class(CLTaskErrHandler)
    
    public constructor := exit;
    
    protected function HadErrorInPrev: boolean; override := false;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override := false;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override := exit;
    
  end;
  
  CLTaskErrHandlerBranchBase = sealed class(CLTaskErrHandler)
    private origin: CLTaskErrHandler;
    
    public constructor(origin: CLTaskErrHandler) := self.origin := origin;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function HadErrorInPrev: boolean; override := origin.HadError;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      if origin_cache.TryGetValue(origin, Result) then exit;
      // Can't remove from here, because "A + B*C.Handle" would otherwise consume error in A
      // Instead CLTaskErrHandlerBranchCombinator handles origin
//      Result := origin.TryRemoveErrors(origin_cache, handler);
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      if origin_cache.Contains(origin) then exit;
      origin.FillErrLst(origin_cache, lst);
    end;
    
  end;
  CLTaskErrHandlerBranchCombinator = sealed class(CLTaskErrHandler)
    private origin: CLTaskErrHandler;
    private branches: array of CLTaskErrHandler;
    
    public constructor(origin: CLTaskErrHandler; branches: array of CLTaskErrHandler);
    begin
      self.origin := origin;
      self.branches := branches;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function HadErrorInPrev: boolean; override;
    begin
      Result := origin.HadError;
      if Result then exit;
      foreach var h in branches do
      begin
        Result := h.HadError;
        if Result then exit;
      end;
    end;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      Result := origin.TryRemoveErrors(origin_cache, handler);
      origin_cache.Add(origin, Result);
      foreach var h in branches do
        Result := h.TryRemoveErrors(origin_cache, handler) or Result;
      origin_cache.Remove(origin);
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      origin.FillErrLst(origin_cache, lst);
      {$ifdef DEBUG}if not{$endif}origin_cache.Add(origin)
      {$ifdef DEBUG}then
        raise new OpenCLABCInternalException($'Origin added multiple times');
      {$endif DEBUG};
      foreach var h in branches do
        h.FillErrLst(origin_cache, lst);
      origin_cache.Remove(origin);
    end;
    
  end;
  
  CLTaskErrHandlerThiefBase = abstract class(CLTaskErrHandler)
    protected victim: CLTaskErrHandler;
    
    public constructor(victim: CLTaskErrHandler) := self.victim := victim;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function CanSteal: boolean; abstract;
    public procedure StealPrevErrors;
    begin
      if victim=nil then exit;
      if CanSteal then
        victim.FillErrLst(self.local_err_lst);
      victim := nil;
    end;
    
    protected function HadErrorInVictim: boolean :=
    (victim<>nil) and victim.HadError;
    
  end;
  CLTaskErrHandlerThief = sealed class(CLTaskErrHandlerThiefBase)
    
    protected function CanSteal: boolean; override := true;
    
    protected function HadErrorInPrev: boolean; override := HadErrorInVictim;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      StealPrevErrors;
      Result := false;
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      StealPrevErrors;
    end;
    
  end;
  /// Repeats first handler, but also steals errors from second, if first is OK
  CLTaskErrHandlerThiefRepeater = sealed class(CLTaskErrHandlerThiefBase)
    private prev_handler: CLTaskErrHandler;
    
    public constructor(prev_handler, victim: CLTaskErrHandler);
    begin
      inherited Create(victim);
      self.prev_handler := prev_handler;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function CanSteal: boolean; override :=
    not prev_handler.HadError;
    
    protected function HadErrorInPrev: boolean; override :=
    // mu_handler.HadError would be called more often,
    // so it's more likely to already have cache
    HadErrorInVictim or prev_handler.HadError;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      Result := prev_handler.TryRemoveErrors(origin_cache, handler);
      if CanSteal then StealPrevErrors;
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      var prev_c := lst.Count;
      prev_handler.FillErrLst(lst);
      if prev_c=lst.Count then StealPrevErrors;
    end;
    
  end;
  
{$endregion CLTaskErrHandler}

{$region EventList}

type
  AttachCallbackData = sealed class
    public work: Action;
    {$ifdef EventDebug}
    public reason: string;
    {$endif EventDebug}
    
    public constructor(work: Action{$ifdef EventDebug}; reason: string{$endif});
    begin
      self.work := work;
      {$ifdef EventDebug}
      self.reason := reason;
      {$endif EventDebug}
    end;
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  MultiAttachCallbackData = sealed class
    public work: Action;
    public left_c: integer;
    {$ifdef EventDebug}
    public reason: string;
    public all_evs: sequence of cl_event;
    {$endif EventDebug}
    
    public constructor(work: Action; left_c: integer{$ifdef EventDebug}; reason: string; all_evs: sequence of cl_event{$endif});
    begin
      self.work := work;
      self.left_c := left_c;
      {$ifdef EventDebug}
      self.reason := reason;
      self.all_evs := all_evs;
      {$endif EventDebug}
    end;
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  EventList = record
    public evs: array of cl_event;
    public count := 0;
    
    {$region Misc}
    
    public property Item[i: integer]: cl_event read evs[i]; default;
    
    public static function operator=(l1, l2: EventList): boolean;
    begin
      Result := false;
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
    
    {$endregion Misc}
    
    {$region constructor's}
    
    public constructor(count: integer) :=
    self.evs := new cl_event[count];
    public constructor := raise new OpenCLABCInternalException;
    public static Empty := default(EventList);
    
    public static function operator implicit(ev: cl_event): EventList;
    begin
      if ev=cl_event.Zero then
        Result := Empty else
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
    
    {$endregion constructor's}
    
    {$region operator+}
    
    public static procedure operator+=(var l: EventList; ev: cl_event);
    begin
      l.evs[l.count] := ev;
      l.count += 1;
    end;
    
    public static procedure operator+=(var l: EventList; ev: EventList);
    begin
      for var i := 0 to ev.count-1 do
        l += ev[i];
    end;
    
    public static function operator+(l1, l2: EventList): EventList;
    begin
      Result := new EventList(l1.count+l2.count);
      Result += l1;
      Result += l2;
    end;
    
    public static function operator+(l: EventList; ev: cl_event): EventList;
    begin
      Result := new EventList(l.count+1);
      Result += l;
      Result += ev;
    end;
    
    private static function Combine<TList>(evs: TList): EventList; where TList: IList<EventList>;
    begin
      Result := EventList.Empty;
      var count := 0;
      
      //TODO #2589
      for var i := 0 to (evs as IList<EventList>).Count-1 do
        count += evs.Item[i].count;
      if count=0 then exit;
      
      Result := new EventList(count);
      //TODO #2589
      for var i := 0 to (evs as IList<EventList>).Count-1 do
        Result += evs.Item[i];
      
    end;
    
    {$endregion operator+}
    
    {$region AttachCallback}
    
    private static procedure CheckEvErr(ev: cl_event{$ifdef EventDebug}; reason: string{$endif});
    begin
      {$ifdef EventDebug}
      EventDebug.CheckExists(ev, reason);
      {$endif EventDebug}
      var st: CommandExecutionStatus;
      var ec := cl.GetEventInfo(ev, EventInfo.EVENT_COMMAND_EXECUTION_STATUS, new UIntPtr(sizeof(CommandExecutionStatus)), st, IntPtr.Zero);
      OpenCLABCInternalException.RaiseIfError(ec);
      OpenCLABCInternalException.RaiseIfError(st);
    end;
    
    private static procedure InvokeAttachedCallback(ev: cl_event; st: CommandExecutionStatus; data: IntPtr);
    begin
      var hnd := GCHandle(data);
      var cb_data := AttachCallbackData(hnd.Target);
      // st копирует значение переданное в cl.SetEventCallback, поэтому он не подходит
      CheckEvErr(ev{$ifdef EventDebug}, cb_data.reason{$endif});
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(ev, $'released in callback, working on {cb_data.reason}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseEvent(ev) );
      hnd.Free;
      cb_data.work();
    end;
    private static attachable_callback: EventCallback := InvokeAttachedCallback;
    
    public static procedure AttachCallback(ev: cl_event; work: Action{$ifdef EventDebug}; reason: string{$endif});
    begin
      var cb_data := new AttachCallbackData(work{$ifdef EventDebug}, reason{$endif});
      var ec := cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, attachable_callback, GCHandle.ToIntPtr(GCHandle.Alloc(cb_data)));
      OpenCLABCInternalException.RaiseIfError(ec);
    end;
    
    {$endregion AttachCallback}
    
    {$region MultiAttachCallback}
    
    private static procedure InvokeMultiAttachedCallback(ev: cl_event; st: CommandExecutionStatus; data: IntPtr);
    begin
      var hnd := GCHandle(data);
      var cb_data := MultiAttachCallbackData(hnd.Target);
      // st копирует значение переданное в cl.SetEventCallback, поэтому он не подходит
      CheckEvErr(ev{$ifdef EventDebug}, cb_data.reason{$endif});
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(ev, $'released in multi-callback, working on {cb_data.reason}, together with evs: {cb_data.all_evs.JoinToString}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError(cl.ReleaseEvent(ev));
      if Interlocked.Decrement(cb_data.left_c) <> 0 then exit;
      hnd.Free;
      cb_data.work();
    end;
    private static multi_attachable_callback: EventCallback := InvokeMultiAttachedCallback;
    
    public procedure MultiAttachCallback(work: Action{$ifdef EventDebug}; reason: string{$endif}) :=
    case self.count of
      0: work;
      1: AttachCallback(self.evs[0], work{$ifdef EventDebug}, reason{$endif});
      else
      begin
        var cb_data := new MultiAttachCallbackData(work, self.count{$ifdef EventDebug}, reason, evs.Take(count){$endif});
        var hnd_ptr := GCHandle.ToIntPtr(GCHandle.Alloc(cb_data));
        for var i := 0 to count-1 do
        begin
          var ec := cl.SetEventCallback(evs[i], CommandExecutionStatus.COMPLETE, multi_attachable_callback, hnd_ptr);
          OpenCLABCInternalException.RaiseIfError(ec);
        end;
      end;
    end;
    
    {$endregion MultiAttachCallback}
    
    {$region Retain/Release}
    
    public procedure Retain({$ifdef EventDebug}reason: string{$endif}) :=
    for var i := 0 to count-1 do
    begin
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(evs[i], $'{reason}, together with evs: {evs.Take(count).JoinToString}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError( cl.RetainEvent(evs[i]) );
    end;
    
    public procedure Release({$ifdef EventDebug}reason: string{$endif}) :=
    for var i := 0 to count-1 do
    begin
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(evs[i], $'{reason}, together with evs: {evs.Take(count).JoinToString}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseEvent(evs[i]) );
    end;
    
    // cl.WaitForEvents uses processor time to wait
    // so if we need to wait it's better to use ManualResetEvent
    public function ToMRE({$ifdef EventDebug}reason: string{$endif}): ManualResetEvent;
    begin
      Result := nil;
      if self.count=0 then exit;
      Result := new ManualResetEvent(false);
      var mre := Result;
      self.MultiAttachCallback(()->mre.Set(){$ifdef EventDebug}, $'setting mre for {reason}'{$endif});
    end;
    
    {$endregion Retain/Release}
    
  end;
  
{$endregion EventList}

{$region CLTaskGlobalData}

type
  IParameterQueue = interface
    
    property Name: string read;
    
  end;
  ParameterQueueSetter = sealed partial class
    par_q: IParameterQueue;
    
    public constructor(par_q: IParameterQueue; val: object);
    begin
      self.par_q := par_q;
      self.val := val;
    end;
    
    public property Name: string read par_q.Name;
    
  end;
  ParameterQueue<T> = sealed partial class(CommandQueue<T>, IParameterQueue)
    
  end;
  
//TODO #????
function ParameterQueue<T>.NewSetter(val: T) := new ParameterQueueSetter(self as object as IParameterQueue, val);

type
  CLTaskParameterData = record
    val: object;
    state: (TPS_Empty, TPS_Default, TPS_Set);
    
    public constructor :=
    self.state := TPS_Empty;
    public constructor(def: object);
    begin
      self.val := def;
      self.state := TPS_Default;
    end;
    
    public function &Set(name: string; val: object): CLTaskParameterData;
    begin
      if self.state=TPS_Set then
        raise new ArgumentException($'%Err:Parameter:SetAgain%');
      Result.val := val;
      Result.state := TPS_Set;
    end;
    
    public procedure TestSet(name: string) :=
    if self.state=TPS_Empty then
      raise new ArgumentException($'%Err:Parameter:UnSet%');
    
  end;
  
  CLTaskGlobalData = sealed partial class
    public tsk: CLTaskBase;
    
    public c: Context;
    public cl_c: cl_context;
    public cl_dvc: cl_device_id;
    
    private curr_inv_cq := cl_command_queue.Zero;
    private outer_cq := cl_command_queue.Zero;
    private free_cqs := new System.Collections.Concurrent.ConcurrentBag<cl_command_queue>;
    
    public curr_err_handler: CLTaskErrHandler := new CLTaskErrHandlerEmpty;
    
    private constructor := raise new OpenCLABCInternalException;
    
    public function GetCQ(async_enqueue: boolean := false): cl_command_queue;
    begin
      Result := curr_inv_cq;
      
      if Result=cl_command_queue.Zero then
      begin
        if outer_cq<>cl_command_queue.Zero then
        begin
          Result := outer_cq;
          outer_cq := cl_command_queue.Zero;
        end else
        if free_cqs.TryTake(Result) then
          else
        begin
          var ec: ErrorCode;
          Result := cl.CreateCommandQueue(cl_c, cl_dvc, CommandQueueProperties.NONE, ec);
          OpenCLABCInternalException.RaiseIfError(ec);
        end;
      end;
      
      curr_inv_cq := if async_enqueue then cl_command_queue.Zero else Result;
    end;
    
    public procedure ReturnCQ(cq: cl_command_queue);
    begin
      free_cqs.Add(cq);
      {$ifdef QueueDebug}
      QueueDebug.Add(cq, '----- return -----');
      {$endif QueueDebug}
    end;
    
    public parameters := new Dictionary<IParameterQueue, CLTaskParameterData>;
    public procedure ApplyParameters(pars: array of ParameterQueueSetter);
    begin
      foreach var par in pars do
      begin
        if not parameters.ContainsKey(par.par_q) then
          raise new ArgumentException($'%Err:Parameter:NotFound%');
        parameters[par.par_q] := parameters[par.par_q].Set(par.Name, par.val);
      end;
      foreach var kvp in self.parameters do
        kvp.Value.TestSet(kvp.Key.Name);
    end;
    
  end;
  
{$endregion CLTaskGlobalData}

{$region UserEvent}

type
  UserEvent = sealed class
    private uev: cl_event;
    private done := new InterlockedBoolean;
    
    {$region constructor's}
    
    private constructor(c: cl_context{$ifdef EventDebug}; reason: string{$endif});
    begin
      var ec: ErrorCode;
      self.uev := cl.CreateUserEvent(c, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(self.uev, $'Created for {reason}');
      {$endif EventDebug}
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public static function StartBackgroundWork(after: EventList; work: Action; c: cl_context{$ifdef EventDebug}; reason: string{$endif}): UserEvent;
    begin
      var res := new UserEvent(c
        {$ifdef EventDebug}, $'BackgroundWork, executing {reason}, after waiting on: {after.evs?.JoinToString}'{$endif}
      );
      
      var mre := after.ToMRE({$ifdef EventDebug}$'Background work with res_ev={res}'{$endif});
      NativeUtils.StartNewBgThread(()->
      begin
        if mre<>nil then mre.WaitOne;
        
        try
          work;
        finally
          res.SetComplete;
        end;
      end);
      
      Result := res;
    end;
    
    {$endregion constructor's}
    
    {$region Status}
    
    /// True если статус получилось изменить
    public function SetStatus(st: CommandExecutionStatus): boolean;
    begin
      Result := done.TrySet(true);
      if Result then OpenCLABCInternalException.RaiseIfError(
        cl.SetUserEventStatus(uev, st)
      );
    end;
    public function SetComplete := SetStatus(CommandExecutionStatus.COMPLETE);
    
    {$endregion Status}
    
    {$region operator's}
    
    public static function operator implicit(ev: UserEvent): cl_event := ev.uev;
    public static function operator implicit(ev: UserEvent): EventList := ev.uev;
    
    //TODO #????
//    public static function operator+(ev1: EventList; ev2: UserEvent): EventList;
//    begin
//      Result := ev1 + ev2.uev;
//      Result.abortable := true;
//    end;
//    public static procedure operator+=(ev1: EventList; ev2: UserEvent);
//    begin
//      ev1 += ev2.uev;
//      ev1.abortable := true;
//    end;
    
    public function ToString: string; override := $'UserEvent[{uev.val}]';
    
    {$endregion operator's}
    
  end;
  
{$endregion UserEvent}

{$region QueueResAction}

type
  QueueResAction = Context->();
  QueueResSetter<T> = Context->T;
  
  QueueResActionUtils = static class
    
    static function HandlerWrap(err_handler: CLTaskErrHandler; d: QueueResAction): QueueResAction := c->
    if not err_handler.HadError then
    try
      d(c);
    except
      on e: Exception do err_handler.AddErr(e);
    end;
    static function HandlerWrap<T>(err_handler: CLTaskErrHandler; d: QueueResSetter<T>): QueueResSetter<T> := c->
    if not err_handler.HadError then
    try
      Result := d(c);
    except
      on e: Exception do err_handler.AddErr(e);
    end;
    static function HandlerWrapStrip<T>(err_handler: CLTaskErrHandler; d: QueueResSetter<T>): QueueResAction := c->
    if not err_handler.HadError then
    try
      d(c);
    except
      on e: Exception do err_handler.AddErr(e);
    end;
    
    static function HandlerWrap<T>(err_handler: CLTaskErrHandler; d: (T,Context)->()): (T,Context)->() := (o,c)->
    if not err_handler.HadError then
    try
      d(o,c);
    except
      on e: Exception do err_handler.AddErr(e);
    end;
    static function HandlerWrap<T,TRes>(err_handler: CLTaskErrHandler; d: (T,Context)->TRes): (T,Context)->TRes := (o,c)->
    if not err_handler.HadError then
    try
      Result := d(o,c);
    except
      on e: Exception do err_handler.AddErr(e);
    end;
    static function HandlerWrapStrip<T,TRes>(err_handler: CLTaskErrHandler; d: (T,Context)->TRes): (T,Context)->() := (o,c)->
    if not err_handler.HadError then
    try
      d(o,c);
    except
      on e: Exception do err_handler.AddErr(e);
    end;
    
  end;
  
  [StructLayout(LayoutKind.Auto)]
  QueueResComplDelegateData = record
    private call_list: array of QueueResAction := nil;
    private count := 0;
    
    private const initial_cap = 4;
    
    public constructor := exit;
    public constructor(d: QueueResAction);
    begin
      call_list := new QueueResAction[initial_cap];
      call_list[0] := d;
      count := 1;
    end;
    
    public procedure AddAction(d: QueueResAction);
    begin
      if call_list=nil then
        call_list := new QueueResAction[initial_cap] else
      if count=call_list.Length then
        System.Array.Resize(call_list, call_list.Length * 4);
      call_list[count] := d;
      count += 1;
    end;
    
    {$ifdef DEBUG}
    private was_invoked := false;
    {$endif DEBUG}
    public procedure Invoke(c: Context);
    begin
      {$ifdef DEBUG}
      if was_invoked then raise new System.InvalidProgramException($'{self.GetType}: {System.Environment.StackTrace}');
      was_invoked := true;
      {$endif DEBUG}
      for var i := 0 to count-1 do
        call_list[i](c);
    end;
    
  end;
  
{$endregion QueueResAction}

{$region CLTaskLocalData}

type
  [StructLayout(LayoutKind.Auto)]
  CLTaskLocalData = record
    public prev_delegate := default(QueueResComplDelegateData);
    public prev_ev := EventList.Empty;
    
    public constructor := exit;
    public constructor(ev: EventList) := self.prev_ev := ev;
    
    public function ShouldInstaCallAction: boolean;
    begin
      // Only const can have not events
      Result := prev_ev.count=0;
      {$ifdef DEBUG}
      if Result and (prev_delegate.count<>0) then raise new OpenCLABCInternalException($'Broken Quick.Invoke detected');
      {$endif DEBUG}
    end;
    
  end;
  
{$endregion CLTaskLocalData}

{$region QueueRes}

type
  {$region Base}
  
  IQueueRes = interface
    
    property ResEv: EventList read;
    
    procedure AddAction(d: QueueResAction);
    property HasActions: boolean read;
    procedure InvokeActions(c: Context);
    function ShouldInstaCallAction: boolean;
    
  end;
  
  IQueueResBaseFactory<TR> = interface
    where TR: IQueueRes;
    
    function MakeDelayed(l: CLTaskLocalData): TR;
    function MakeDelayed(make_l: TR->CLTaskLocalData): TR;
    
  end;
  
  [StructLayout(LayoutKind.Auto)]
  QueueResData = record
    private complition_delegate  := default(QueueResComplDelegateData);
    private ev                   := EventList.Empty;
    
    public static function operator implicit(base: QueueResData): CLTaskLocalData;
    begin
      Result := new CLTaskLocalData(base.ev);
      Result.prev_delegate := base.complition_delegate;
    end;
    
    public property ResEv: EventList read ev;
    
    public procedure AddAction(d: QueueResAction);
    begin
      {$ifdef DEBUG}
      if ShouldInstaCallAction then raise new OpenCLABCInternalException($'Broken Quick.Invoke detected');
      {$endif DEBUG}
      complition_delegate.AddAction(d);
    end;
    
    public procedure InvokeActions(c: Context) := complition_delegate.Invoke(c);
    
    public function ShouldInstaCallAction := CLTaskLocalData(self).ShouldInstaCallAction;
    
    protected procedure Finalize; override;
    begin
      {$ifdef DEBUG}
      if not complition_delegate.was_invoked then raise new System.InvalidProgramException($'{self.GetType}');
      {$endif DEBUG}
    end;
    
  end;
  
  {$endregion Base}
  
  {$region Nil}
  
  [StructLayout(LayoutKind.Auto)]
  QueueResNil = record(IQueueRes)
    private base: QueueResData;
    
    public constructor(l: CLTaskLocalData);
    begin
      base.ev := l.prev_ev;
      base.complition_delegate := l.prev_delegate;
    end;
    public constructor := raise new OpenCLABCInternalException;
    
    public property ResEv: EventList read base.ResEv;
    
    public procedure AddAction(d: QueueResAction) := base.AddAction(d);
    public property HasActions: boolean read base.complition_delegate.count<>0;
    public procedure InvokeActions(c: Context) := base.InvokeActions(c);
    public function ShouldInstaCallAction := base.ShouldInstaCallAction;
    
  end;
  QueueResNilFactory = record(IQueueResBaseFactory<QueueResNil>)
    
    function MakeDelayed(l: CLTaskLocalData) := new QueueResNil(l);
    function MakeDelayed(make_l: QueueResNil->CLTaskLocalData) := new QueueResNil(make_l(default(QueueResNil)));
    
  end;
  
  {$endregion Nil}
  
  {$region <T>}
  
  {$region General}
  
  QueueResT = abstract partial class(IQueueRes)
    private base: QueueResData;
    private res_const: boolean; // Whether res can be read before event completes
    {$ifdef DEBUG}
    private res_setter_exists := false;
    {$endif DEBUG}
    
    public property ResEv: EventList read; abstract;
    
    public procedure AddAction(d: QueueResAction) := base.AddAction(d);
    public property HasActions: boolean read base.complition_delegate.count<>0;
    public procedure InvokeActions(c: Context) := base.InvokeActions(c);
    public function ShouldInstaCallAction := base.ShouldInstaCallAction;
    
    public function TakeBaseOut: QueueResData;
    begin
      Result := self.base;
      self.base := default(QueueResData);
    end;
    
  end;
  
  QueueRes<T> = abstract partial class(QueueResT) end;
  IQueueResFactory<T,TR> = interface(IQueueResBaseFactory<TR>)
    where TR: QueueRes<T>;
    
    function MakeConst(l: CLTaskLocalData; res: T): TR;
    
  end;
  
  QueueRes<T> = abstract partial class(QueueResT)
    
    protected procedure InitDelayed(l: CLTaskLocalData);
    begin
      {$ifdef DEBUG}
      if l.prev_ev.count=0 then raise new OpenCLABCInternalException($'Delayed QueueRes, but it is not delayed');
      {$endif DEBUG}
      base.ev := l.prev_ev;
      base.complition_delegate := l.prev_delegate;
    end;
    
    protected procedure InitConst(l: CLTaskLocalData; res: T);
    begin
      base.ev := l.prev_ev;
      base.complition_delegate := l.prev_delegate;
      SetResDirect(res);
      res_const := true;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function WrapResult<TR>(factory: IQueueResFactory<T,TR>; new_ev: EventList): TR; where TR: QueueRes<T>;
    begin
      // It is expected that new_ev would have actions already attached
      var l := new CLTaskLocalData(new_ev);
      if res_const then
        Result := factory.MakeConst(l, self.GetResDirect) else
      begin
        Result := factory.MakeDelayed(l);
        Result.AddResSetter(c->self.GetResDirect);
      end;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function TransformResult<T2,TR>(factory: IQueueResFactory<T2,TR>; c: Context; can_insta_call: boolean; transform: (T,Context)->T2): TR; where TR: QueueRes<T2>;
    begin
      var res_l := CLTaskLocalData(self.TakeBaseOut);
      
      if res_l.ShouldInstaCallAction or (res_const and can_insta_call) then
        Result := factory.MakeConst(res_l, transform(self.GetResDirect, c)) else
      begin
        Result := factory.MakeDelayed(res_l);
        Result.AddResSetter(c->transform(self.GetResDirect, c));
      end;
      
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function TransformResultErrWrap<T2,TR>(factory: IQueueResFactory<T2,TR>; g: CLTaskGlobalData; can_insta_call: boolean; transform: (T,Context)->T2): TR; where TR: QueueRes<T2>;
    begin
      //TODO #2644: &<>
      transform := QueueResActionUtils.HandlerWrap&<T,T2>(g.curr_err_handler, transform);
      Result := TransformResult(factory, g.c, can_insta_call, transform);
    end;
    
    public property ResEv: EventList read base.ResEv; override;
    
    public property IsConst: boolean read res_const;
    
    public procedure AddResSetter(d: Context->T);
    begin
      {$ifdef DEBUG}
      if res_const then raise new OpenCLABCInternalException($'Result setter action on const qr');
      if res_setter_exists then raise new OpenCLABCInternalException($'Multiple result setter actions');
      res_setter_exists := true;
      {$endif DEBUG}
      AddAction(c->self.SetRes(d(c)));
    end;
    public procedure SetRes(res: T);
    begin
      {$ifdef DEBUG}
      if res_const then raise new OpenCLABCInternalException($'');
      {$endif DEBUG}
      SetResDirect(res);
    end;
    protected procedure SetResDirect(res: T); abstract;
    public function GetRes(c: Context): T;
    begin
      InvokeActions(c);
      Result := GetResDirect;
    end;
    protected function GetResDirect: T; abstract;
    
  end;
  
  {$endregion General}
  
  {$region Val}
  
  QueueResVal<T> = sealed class(QueueRes<T>)
    private res: T;
    
    public constructor(l: CLTaskLocalData) := InitDelayed(l);
    public constructor(make_l: QueueResVal<T>->CLTaskLocalData) := InitDelayed(make_l(self));
    
    public constructor(l: CLTaskLocalData; res: T) := InitConst(l, res);
    public constructor(make_l: QueueResVal<T>->CLTaskLocalData; res: T) := InitConst(make_l(self), res);
    
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure SetResDirect(res: T); override := self.res := res;
    protected function GetResDirect: T; override := self.res;
    
  end;
  QueueResValFactory<T> = record(IQueueResFactory<T, QueueResVal<T>>)
    
    public function MakeConst(l: CLTaskLocalData; res: T) := new QueueResVal<T>(l, res);
    
    public function MakeDelayed(l: CLTaskLocalData) := new QueueResVal<T>(l);
    public function MakeDelayed(make_l: QueueResVal<T>->CLTaskLocalData) := new QueueResVal<T>(make_l);
    
  end;
  QueueRes<T> = abstract partial class(QueueResT)
    public static val_factory := new QueueResValFactory<T>;
  end;
  
  {$endregion Val}
  
  {$region Ptr}
  
  QueueResPtr<T> = sealed class(QueueRes<T>)
    private res: ^T := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<T>));
    
    static constructor := BlittableHelper.RaiseIfBad(typeof(T), '%Err:Blittable:Source:QueueResPtr%');
    
    public constructor(l: CLTaskLocalData) := InitDelayed(l);
    public constructor(make_l: QueueResPtr<T>->CLTaskLocalData) := InitDelayed(make_l(self));
    
    public constructor(l: CLTaskLocalData; res: T) := InitConst(l, res);
    public constructor(make_l: QueueResPtr<T>->CLTaskLocalData; res: T) := InitConst(make_l(self), res);
    
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure Finalize; override;
    begin
      Marshal.FreeHGlobal(new IntPtr(res));
      inherited;
    end;
    
    protected procedure SetResDirect(res: T); override := self.res^ := res;
    protected function GetResDirect: T; override := self.res^;
    
  end;
  QueueResPtrFactory<T> = record(IQueueResFactory<T, QueueResPtr<T>>)
    
    public function MakeConst(l: CLTaskLocalData; res: T) := new QueueResPtr<T>(l, res);
    
    public function MakeDelayed(l: CLTaskLocalData) := new QueueResPtr<T>(l);
    public function MakeDelayed(make_l: QueueResPtr<T>->CLTaskLocalData) := new QueueResPtr<T>(make_l);
    
  end;
  QueueRes<T> = abstract partial class(QueueResT)
    public static ptr_factory := new QueueResPtrFactory<T>;
  end;
  
  {$endregion Ptr}
  
  {$endregion <T>}
  
//TODO #????
procedure TODO := exit;

[MethodImpl(MethodImplOptions.AggressiveInlining)]
function AttachInvokeActions(self: IQueueRes; g: CLTaskGlobalData): EventList; extensionmethod;
begin
  if not self.HasActions then
  begin
    Result := self.ResEv;
    exit;
  end else
  {$ifdef DEBUG}
  if self.ShouldInstaCallAction then // auto raise
  {$endif DEBUG}
    ;
  
  var uev := new UserEvent(g.cl_c{$ifdef EventDebug}, $'res_ev for {self.GetType}.ThenAttachInvokeActions, after [{self.ResEv.evs?.JoinToString}]'{$endif});
  Result := uev;
  
  var c := g.c;
  self.ResEv.MultiAttachCallback(()->
  begin
    self.InvokeActions(c);
    uev.SetComplete;
  end{$ifdef EventDebug}, $'body of {self.GetType}.ThenAttachInvokeActions with res_ev={uev}'{$endif});
  
end;
//TODO #????
function AttachInvokeActions<T>(self: QueueRes<T>; g: CLTaskGlobalData); extensionmethod := (self as IQueueRes).AttachInvokeActions(g);

{$endregion QueueRes}

{$region MultiusableBase}

type
  IMultiusableCommandQueueHub = interface end;
  [StructLayout(LayoutKind.Auto)]
  MultiuseableResultData = record
    public qres: IQueueRes;
    public ev: EventList;
    public err_handler: CLTaskErrHandler;
    
    public constructor(qres: IQueueRes; ev: EventList; err_handler: CLTaskErrHandler);
    begin
      self.qres := qres;
      self.ev := ev;
      self.err_handler := err_handler;
    end;
    
  end;
  
{$endregion MultiusableBase}

{$region CLTaskGlobalData/BkanchInvoker}

type
  CLTaskBranchInvoker = sealed class
    private g: CLTaskGlobalData;
    private prev_ev: EventList?;
    private prev_cq := cl_command_queue.Zero;
    private branch_handlers := new List<CLTaskErrHandler>;
    private make_base_err_handler: ()->CLTaskErrHandler;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    constructor(g: CLTaskGlobalData; prev_ev: EventList?; capacity: integer);
    begin
      self.g := g;
      self.prev_ev := prev_ev;
      
      if g.curr_inv_cq<>cl_command_queue.Zero then
      begin
        {$ifdef DEBUG}
        if g.outer_cq<>cl_command_queue.Zero then raise new OpenCLABCInternalException($'outer_cq should be taken when curr_inv_cq is not Zero');
        {$endif DEBUG}
        
        // Make outer only if ParallelInvoke is said to wait for event of current cq
        // Otherwise command parameters would be added to outer cq, causing them to wait anyway
        if prev_ev<>nil then
        begin
          {$ifdef DEBUG}
          if prev_ev.Value.count=0 then raise new OpenCLABCInternalException($'prev_ev should not be Zero when curr_inv_cq is not Zero');
          {$endif DEBUG}
          g.outer_cq := g.curr_inv_cq;
        end else
          self.prev_cq := g.curr_inv_cq;
        
        g.curr_inv_cq := cl_command_queue.Zero;
      end;
      
      self.branch_handlers.Capacity := capacity;
      if prev_ev=nil then
        self.make_base_err_handler := ()->new CLTaskErrHandlerEmpty else
      begin
        var origin_handler := g.curr_err_handler;
        self.make_base_err_handler := ()->new CLTaskErrHandlerBranchBase(origin_handler);
      end;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeBranch<TR>(branch: (CLTaskGlobalData, CLTaskLocalData)->TR): TR; where TR: IQueueRes;
    begin
      g.curr_err_handler := make_base_err_handler();
      var l := if self.prev_ev=nil then
        new CLTaskLocalData else
        new CLTaskLocalData(self.prev_ev.Value);
      
      Result := branch(g, l);
      
      var cq := g.curr_inv_cq;
      if cq<>cl_command_queue.Zero then
      begin
        g.curr_inv_cq := cl_command_queue.Zero;
        if prev_cq=cl_command_queue.Zero then
          prev_cq := cq else
        begin
          OpenCLABCInternalException.RaiseIfError( cl.Flush(cq) );
          Result.AddAction(c->self.g.ReturnCQ(cq));
        end;
      end;
      
      branch_handlers += g.curr_err_handler;
    end;
    
  end;
  
  CLTaskGlobalData = sealed partial class
    
    public mu_res := new Dictionary<IMultiusableCommandQueueHub, MultiuseableResultData>;
    
    public constructor(tsk: CLTaskBase);
    begin
      self.tsk := tsk;
      
      self.c := tsk.OrgContext;
      self.cl_c := c.ntv;
      self.cl_dvc := c.main_dvc.ntv;
      
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ParallelInvoke(l: CLTaskLocalData?; capacity: integer; use: Action<CLTaskBranchInvoker>);
    begin
      var prev_ev := default(EventList?);
      if l<>nil then
      begin
        var ev := QueueResNil.Create(l.Value).AttachInvokeActions(self);
        if ev.count<>0 then loop capacity-1 do
          ev.Retain({$ifdef EventDebug}$'for all async branches'{$endif});
        prev_ev := ev;
      end;
      
      var invoker := new CLTaskBranchInvoker(self, prev_ev, capacity);
      var origin_handler := self.curr_err_handler;
      
      use(invoker);
      
      {$ifdef DEBUG}
      if invoker.branch_handlers.Count<>capacity then
        raise new OpenCLABCInternalException($'{invoker.branch_handlers.Count} <> {capacity}');
      {$endif DEBUG}
      self.curr_err_handler := new CLTaskErrHandlerBranchCombinator(origin_handler, invoker.branch_handlers.ToArray);
      
      self.curr_inv_cq := invoker.prev_cq;
      if outer_cq<>cl_command_queue.Zero then self.GetCQ(false);
    end;
    
    public procedure FinishInvoke;
    begin
      
      // mu выполняют лишний .Retain, чтобы ивент не удалился пока очередь ещё запускается
      foreach var mrd in mu_res.Values do
        mrd.ev.Release({$ifdef EventDebug}$'excessive mu ev'{$endif});
      mu_res := nil;
      
    end;
    
    public procedure FinishExecution(var err_lst: List<Exception>);
    begin
      
      if curr_inv_cq<>cl_command_queue.Zero then
      begin
        OpenCLABCInternalException.RaiseIfError( cl.Flush(curr_inv_cq) );
        ReturnCQ(curr_inv_cq);
      end;
      
      foreach var cq in free_cqs do
        OpenCLABCInternalException.RaiseIfError( cl.ReleaseCommandQueue(cq) );
      
      err_lst := new List<Exception>;
      curr_err_handler.FillErrLst(err_lst);
      {$ifdef DEBUG}
      curr_err_handler.SanityCheck(err_lst);
      {$endif DEBUG}
    end;
    
  end;
  
{$endregion CLTaskData}

{$endregion Util type's}

{$region CommandQueue}

{$region Base}

type
  CommandQueueBase = abstract partial class
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); abstract;
    
    protected static qr_nil_factory := new QueueResNilFactory;
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; abstract;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    protected static qr_val_factory := QueueRes&<T>.val_factory;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; abstract;
    
    protected static qr_ptr_factory := QueueRes&<T>.ptr_factory;
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; abstract;
    
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<T>; virtual := InvokeToVal(g, l);
    
  end;
  
  CommandQueueInvoker<TR> = (CLTaskGlobalData,CLTaskLocalData)->TR;
  
{$endregion Base}

{$region Const}

type
  ConstQueue<T> = sealed partial class(CommandQueue<T>)
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := new QueueResNil(l);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := new QueueResVal<T>(l, self.res);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := new QueueResPtr<T>(l, self.res);
    
  end;
  
{$endregion Const}

{$region Parameter}

type
  ParameterQueue<T> = sealed partial class(CommandQueue<T>, IParameterQueue)
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override;
    begin
      //TODO #????
      if g.parameters.ContainsKey(self as object as IParameterQueue) then exit;
      //TODO #????
      g.parameters[self as object as IParameterQueue] := if self.def_is_set then
        new CLTaskParameterData(self.def) else
        new CLTaskParameterData;
    end;
    
    private function GetParVal(g: CLTaskGlobalData) :=
    //TODO #????
    T(g.parameters[self as object as IParameterQueue].val);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := new QueueResNil(l);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := new QueueResVal<T>(l, self.GetParVal(g));
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := new QueueResPtr<T>(l, self.GetParVal(g));
    
  end;
  
{$endregion Parameter}

{$endregion CommandQueue}

{$region CLTask}

type
  CLTaskBase = abstract partial class
    
  end;
  
  CLTaskNil = sealed partial class(CLTaskBase)
    
    private constructor(q: CommandQueueNil; c: Context; pars: array of ParameterQueueSetter);
    begin
      self.q := q;
      self.org_c := c;
      
      var g := new CLTaskGlobalData(self);
      
      q.InitBeforeInvoke(g, new HashSet<IMultiusableCommandQueueHub>);
      g.ApplyParameters(pars);
      var qr := q.InvokeToNil(g, new CLTaskLocalData);
      g.FinishInvoke;
      
      var mre := qr.ResEv.ToMRE({$ifdef EventDebug}$'CLTaskNil.FinishExecution'{$endif});
      NativeUtils.StartNewBgThread(()->
      begin
        if mre<>nil then mre.WaitOne;
        qr.InvokeActions(self.org_c);
        g.FinishExecution(self.err_lst);
        self.wh.Set;
      end);
      
    end;
    
  end;
  CLTask<T> = sealed partial class(CLTaskBase)
    private res: T;
    
    private constructor(q: CommandQueue<T>; c: Context; pars: array of ParameterQueueSetter);
    begin
      self.q := q;
      self.org_c := c;
      
      var g := new CLTaskGlobalData(self);
      
      q.InitBeforeInvoke(g, new HashSet<IMultiusableCommandQueueHub>);
      g.ApplyParameters(pars);
      var qr := q.InvokeToAny(g, new CLTaskLocalData);
      g.FinishInvoke;
      
      var mre := qr.ResEv.ToMRE({$ifdef EventDebug}$'CLTask<{typeof(T)}>.FinishExecution'{$endif});
      NativeUtils.StartNewBgThread(()->
      begin
        if mre<>nil then mre.WaitOne;
        self.res := qr.GetRes(self.org_c);
        g.FinishExecution(self.err_lst);
        self.wh.Set;
      end);
      
    end;
    
  end;
  
  CLTaskFactory = record(ITypedCQConverter<CLTaskBase>)
    private c: Context;
    private pars: array of ParameterQueueSetter;
    public constructor(c: Context; pars: array of ParameterQueueSetter);
    begin
      self.c := c;
      self.pars := pars;
    end;
    public constructor := raise new OpenCLABCInternalException;
    
    public function ConvertNil(cq: CommandQueueNil): CLTaskBase := new CLTaskNil(cq, c, pars);
    public function Convert<T>(cq: CommandQueue<T>): CLTaskBase := new CLTask<T>(cq, c, pars);
    
  end;
  
function Context.BeginInvoke(q: CommandQueueBase; params parameters: array of ParameterQueueSetter) := q.ConvertTyped(new CLTaskFactory(self, parameters));
function Context.BeginInvoke(q: CommandQueueNil; params parameters: array of ParameterQueueSetter) := new CLTaskNil(q, self, parameters);
function Context.BeginInvoke<T>(q: CommandQueue<T>; params parameters: array of ParameterQueueSetter) := new CLTask<T>(q, self, parameters);

function CLTask<T>.WaitRes: T;
begin
  Wait;
  Result := self.res;
end;

{$endregion CLTask}

{$region Queue converter's}

{$region Cast}

type
  TypedNilQueue<T> = sealed class(CommandQueue<T>)
    private static nil_val := default(T);
    private q: CommandQueueNil;
    
    static constructor;
    begin
      if object(nil_val)<>nil then
        raise new System.InvalidCastException($'%Err:Cast:nil->T%');
    end;
    public constructor(q: CommandQueueNil) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := q.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := new QueueResVal<T>(q.InvokeToNil(g, l).base, nil_val);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := new QueueResPtr<T>(q.InvokeToNil(g, l).base, nil_val);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CastQueueBase<TRes> = abstract class(CommandQueue<TRes>)
    
    public property SourceBase: CommandQueueBase read; abstract;
    
  end;
  
  CastQueue<TInp, TRes> = sealed class(CastQueueBase<TRes>)
    private q: CommandQueue<TInp>;
    
    static constructor;
    begin
      if typeof(TInp)=typeof(object) then exit;
      try
        var res := TRes(object(default(TInp)));
        System.GC.KeepAlive(res);
      except
        raise new System.InvalidCastException($'%Err:Cast:TInp->TRes%');
      end;
    end;
    public constructor(q: CommandQueue<TInp>) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    public property SourceBase: CommandQueueBase read q as CommandQueueBase; override;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    q.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: QueueRes<TRes>;
    begin
      var prev_qr := q.InvokeToAny(g,l);
      Result := prev_qr.TransformResultErrWrap(qr_factory, g, true, (o,c)->TRes(object(o)));
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CastQueueFactory<TRes> = record(ITypedCQConverter<CommandQueue<TRes>>)
    
    public function ConvertNil(cq: CommandQueueNil): CommandQueue<TRes> := new TypedNilQueue<TRes>(cq);
    public function Convert<TInp>(cq: CommandQueue<TInp>): CommandQueue<TRes>;
    begin
      if cq is CastQueueBase<TInp>(var cqb) then
        Result := cqb.SourceBase.Cast&<TRes> else
        Result := new CastQueue<TInp, TRes>(cq);
    end;
    
  end;
  
function CommandQueueBase.Cast<T>: CommandQueue<T>;
begin
  if self is CommandQueue<T>(var tcq) then
    Result := tcq else
  try
    Result := self.ConvertTyped(new CastQueueFactory<T>);
  except
    on e: TypeInitializationException do
      raise e.InnerException;
    on e: InvalidCastException do
      raise e;
  end;
end;

function CommandQueueNil.Cast<T> := new TypedNilQueue<T>(self);

{$endregion Cast}

{$region DiscardResult}

type
  CommandQueueDiscardResult<T> = sealed class(CommandQueueNil)
    private q: CommandQueue<T>;
    
    public constructor(q: CommandQueue<T>) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    q.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function CommandQueue<T>.DiscardResult :=
new CommandQueueDiscardResult<T>(self);

{$endregion DiscardResult}

{$region BackgroundConvertQueue}

type
  BackgroundConvertQueue<TInp,TRes> = abstract class(CommandQueue<TRes>)
    
    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<TInp>; abstract;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; abstract;
    
    private function MakeNilBody    (prev_qr: QueueRes<TInp>; err_handler: CLTaskErrHandler; c: Context; own_qr: QueueResNil): Action := ()->
    begin
      var inp := prev_qr.GetRes(c);
      if err_handler.HadError then exit;
      try
        ExecFunc(inp, c);
      except
        on e: Exception do err_handler.AddErr(e);
      end;
    end;
    private function MakeResBody<TR>(prev_qr: QueueRes<TInp>; err_handler: CLTaskErrHandler; c: Context; own_qr: TR): Action; where TR: QueueRes<TRes>;
    begin
      Result := ()->
      begin
        var inp := prev_qr.GetRes(c);
        if err_handler.HadError then exit;
        var res: TRes;
        try
          res := ExecFunc(inp, c);
        except
          on e: Exception do err_handler.AddErr(e);
        end;
        own_qr.SetRes(res);
      end;
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResBaseFactory<TR>; make_body: (QueueRes<TInp>,CLTaskErrHandler,Context,TR)->Action): TR; where TR: IQueueRes;
    begin
      var prev_qr := InvokeSubQs(g, l);
      
      Result := qr_factory.MakeDelayed(qr->new CLTaskLocalData(UserEvent.StartBackgroundWork(
        prev_qr.ResEv, make_body(prev_qr, g.curr_err_handler, g.c, qr), g.cl_c
        {$ifdef EventDebug}, $'body of {self.GetType}'{$endif}
      )));
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory, MakeNilBody);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override := Invoke(g, l, qr_val_factory, MakeResBody&<QueueResVal<TRes>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory, MakeResBody&<QueueResPtr<TRes>>);
    
  end;
  
{$endregion BackgroundConvertQueue}

{$region ThenBackgroundConvert}

type
  CommandQueueThenBackgroundConvertBase<TInp, TRes, TFunc> = abstract class(BackgroundConvertQueue<TInp, TRes>)
  where TFunc: Delegate;
    private q: CommandQueue<TInp>;
    private f: TFunc;
    
    public constructor(q: CommandQueue<TInp>; f: TFunc);
    begin
      self.q := q;
      self.f := f;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    q.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<TInp>; override := q.InvokeToAny(g, l);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, f);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueThenBackgroundConvert<TInp, TRes> = sealed class(CommandQueueThenBackgroundConvertBase<TInp, TRes, TInp->TRes>)
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o);
    
  end;
  CommandQueueThenBackgroundConvertC<TInp, TRes> = sealed class(CommandQueueThenBackgroundConvertBase<TInp, TRes, (TInp, Context)->TRes>)
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
function CommandQueue<T>.ThenConvert<TOtp>(f: T->TOtp) :=
new CommandQueueThenBackgroundConvert<T, TOtp>(self, f);

function CommandQueue<T>.ThenConvert<TOtp>(f: (T, Context)->TOtp) :=
new CommandQueueThenBackgroundConvertC<T, TOtp>(self, f);

{$endregion ThenBackgroundConvert}

{$region ThenBackgroundUse}

type
  CommandQueueThenBackgroundUseBase<T, TProc> = abstract class(CommandQueue<T>)
  where TProc: Delegate;
    private q: CommandQueue<T>;
    private p: TProc;
    
    public constructor(q: CommandQueue<T>; p: TProc);
    begin
      self.q := q;
      self.p := p;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    q.InitBeforeInvoke(g, inited_hubs);
    
    protected procedure ExecProc(o: T; c: Context); abstract;
    
    private function MakeNilBody    (prev_qr: QueueRes<T>; err_handler: CLTaskErrHandler; c: Context): Action := ()->
    begin
      var res := prev_qr.GetRes(c);
      if err_handler.HadError then exit;
      try
        ExecProc(res, c);
      except
        on e: Exception do err_handler.AddErr(e);
      end;
    end;
    private function MakeResBody<TR>(prev_qr: QueueRes<T>; err_handler: CLTaskErrHandler; c: Context; own_qr: TR): Action; where TR: QueueRes<T>;
    begin
      Result := ()->
      begin
        var res := prev_qr.GetRes(c);
        if err_handler.HadError then exit;
        try
          ExecProc(res, c);
        except
          on e: Exception do err_handler.AddErr(e);
        end;
        own_qr.SetRes(res);
      end;
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var prev_qr := q.InvokeToAny(g, l);
      
      Result := new QueueResNil(new CLTaskLocalData(UserEvent.StartBackgroundWork(
        prev_qr.ResEv, MakeNilBody(prev_qr, g.curr_err_handler, g.c), g.cl_c
        {$ifdef EventDebug}, $'nil body of {self.GetType}'{$endif}
      )));
      
    end;
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var prev_qr := q.InvokeToAny(g, l);
      
      Result := if prev_qr.IsConst then
        qr_factory.MakeConst(
          new CLTaskLocalData(UserEvent.StartBackgroundWork(
            prev_qr.ResEv, MakeNilBody(prev_qr, g.curr_err_handler, g.c), g.cl_c
            {$ifdef EventDebug}, $'const body of {self.GetType}'{$endif}
          )), prev_qr.GetResDirect
        ) else
        qr_factory.MakeDelayed(
          qr->new CLTaskLocalData(UserEvent.StartBackgroundWork(
            prev_qr.ResEv, MakeResBody(prev_qr, g.curr_err_handler, g.c, qr), g.cl_c
            {$ifdef EventDebug}, $'delayed body of {self.GetType}'{$endif}
          ))
        );
      
    end;
    
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, p);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueThenBackgroundUse<T> = sealed class(CommandQueueThenBackgroundUseBase<T, T->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o);
    
  end;
  CommandQueueThenBackgroundUseC<T> = sealed class(CommandQueueThenBackgroundUseBase<T, (T, Context)->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o, c);
    
  end;
  
function CommandQueue<T>.ThenUse(p: T->()): CommandQueue<T> :=
new CommandQueueThenBackgroundUse<T>(self, p);

function CommandQueue<T>.ThenUse(p: (T, Context)->()): CommandQueue<T> :=
new CommandQueueThenBackgroundUseC<T>(self, p);

{$endregion ThenBackgroundUse}

{$region ThenQuickConvert}

type
  CommandQueueThenQuickConvertBase<TInp, TRes, TFunc> = abstract class(CommandQueue<TRes>)
  where TFunc: Delegate;
    private q: CommandQueue<TInp>;
    private f: TFunc;
    
    public constructor(q: CommandQueue<TInp>; f: TFunc);
    begin
      self.q := q;
      self.f := f;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := q.InitBeforeInvoke(g, inited_hubs);
    
    protected function ExecFunc(o: TInp; c: Context): TRes; abstract;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var prev_qr := q.InvokeToAny(g, l);
      Result := new QueueResNil(prev_qr.TakeBaseOut);
      
      var d := QueueResActionUtils.HandlerWrapStrip(g.curr_err_handler, ExecFunc);
      if Result.ShouldInstaCallAction then
        d(prev_qr.GetResDirect, g.c) else
        Result.AddAction(c->d(prev_qr.GetResDirect,c));
      
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: QueueRes<TRes>;
    begin
      var prev_qr := q.InvokeToAny(g, l);
      Result := prev_qr.TransformResultErrWrap(qr_factory, g, false, ExecFunc);
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, f);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueThenQuickConvert<TInp, TRes> = sealed class(CommandQueueThenQuickConvertBase<TInp, TRes, TInp->TRes>)
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o);
    
  end;
  CommandQueueThenQuickConvertC<TInp, TRes> = sealed class(CommandQueueThenQuickConvertBase<TInp, TRes, (TInp, Context)->TRes>)
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
function CommandQueue<T>.ThenQuickConvert<TOtp>(f: T->TOtp) :=
new CommandQueueThenQuickConvert<T, TOtp>(self, f);

function CommandQueue<T>.ThenQuickConvert<TOtp>(f: (T, Context)->TOtp) :=
new CommandQueueThenQuickConvertC<T, TOtp>(self, f);

{$endregion ThenQuickConvert}

{$region ThenQuickUse}

type
  CommandQueueThenQuickUseBase<T, TProc> = abstract class(CommandQueue<T>)
  where TProc: Delegate;
    private q: CommandQueue<T>;
    private p: TProc;
    
    public constructor(q: CommandQueue<T>; p: TProc);
    begin
      self.q := q;
      self.p := p;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := q.InitBeforeInvoke(g, inited_hubs);
    
    protected procedure ExecProc(o: T; c: Context); abstract;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AddUse<TR1, TR2>(prev_qr: TR1; own_qr: TR2; g: CLTaskGlobalData): TR2; where TR1: QueueRes<T>; where TR2: IQueueRes;
    begin
      Result := own_qr;
      
      var d := QueueResActionUtils.HandlerWrap(g.curr_err_handler, ExecProc);
      if Result.ShouldInstaCallAction then
        d(prev_qr.GetResDirect, g.c) else
        Result.AddAction(c->d(prev_qr.GetResDirect, c));
      
    end;
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AddUse<TR>(qr: TR; g: CLTaskGlobalData): TR; where TR: QueueRes<T>;
    begin
      Result := AddUse(qr,qr, g);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var prev_qr := q.InvokeToAny(g, l);
      Result := AddUse(prev_qr, new QueueResNil(prev_qr.TakeBaseOut), g);
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := AddUse(q.InvokeToVal(g, l), g);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := AddUse(q.InvokeToPtr(g, l), g);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, p);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueThenQuickUse<T> = sealed class(CommandQueueThenQuickUseBase<T, T->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o);
    
  end;
  CommandQueueThenQuickUseC<T> = sealed class(CommandQueueThenQuickUseBase<T, (T, Context)->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o, c);
    
  end;
  
function CommandQueue<T>.ThenQuickUse(p: T->()) :=
new CommandQueueThenQuickUse<T>(self, p);

function CommandQueue<T>.ThenQuickUse(p: (T, Context)->()) :=
new CommandQueueThenQuickUseC<T>(self, p);

{$endregion ThenQuickUse}

{$region +/*}

{$region Simple}

type
  SimpleQueueArrayCommon<TQ> = record
  where TQ: CommandQueueBase;
    public qs: array of CommandQueueBase;
    public last: TQ;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function GetQS: sequence of CommandQueueBase := qs.Append&<CommandQueueBase>(last);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>);
    begin
      foreach var q in qs do q.InitBeforeInvoke(g, inited_hubs);
      last.InitBeforeInvoke(g, inited_hubs);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeSync<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_last: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      for var i := 0 to qs.Length-1 do
        l := qs[i].InvokeToNil(g, l).base;
      
      Result := invoke_last(g, l);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeAsync<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_last: CommandQueueInvoker<TR>): ValueTuple<TR, EventList>; where TR: IQueueRes;
    begin
      var evs := new EventList[qs.Length+1];
      
      var res: TR;
      g.ParallelInvoke(l, qs.Length+1, invoker->
      begin
        for var i := 0 to qs.Length-1 do
          //TODO #2610
          evs[i] := invoker.InvokeBranch&<IQueueRes>((g,l)->
            qs[i].InvokeToNil(g, l)
          ).AttachInvokeActions(g);
        var l_res := invoker.InvokeBranch(invoke_last);
        res := l_res;
        evs[qs.Length] := l_res.AttachInvokeActions(g);
      end);
      
      Result := ValueTuple.Create(res, EventList.Combine(evs));
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      foreach var q in qs do
        q.ToString(sb, tabs, index, delayed);
      last.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  ISimpleQueueArray = interface
    function GetQS: sequence of CommandQueueBase;
  end;
  ISimpleSyncQueueArray = interface(ISimpleQueueArray) end;
  ISimpleAsyncQueueArray = interface(ISimpleQueueArray) end;
  
  SimpleQueueArrayNil = abstract class(CommandQueueNil, ISimpleQueueArray)
    protected data := new SimpleQueueArrayCommon< CommandQueueNil >;
    
    public constructor(qs: array of CommandQueueBase; last: CommandQueueNil);
    begin
      data.qs := qs;
      data.last := last;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function GetQS: sequence of CommandQueueBase := data.GetQS;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    data.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  SimpleSyncQueueArrayNil = sealed class(SimpleQueueArrayNil, ISimpleSyncQueueArray)
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    data.InvokeSync(g, l, data.last.InvokeToNil);
  end;
  SimpleAsyncQueueArrayNil = sealed class(SimpleQueueArrayNil, ISimpleAsyncQueueArray)
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    new QueueResNil(new CLTaskLocalData( data.InvokeAsync(g, l, data.last.InvokeToNil).Item2 ));
  end;
  
  SimpleQueueArray<T> = abstract class(CommandQueue<T>, ISimpleQueueArray)
    protected data := new SimpleQueueArrayCommon< CommandQueue<T> >;
    
    public constructor(qs: array of CommandQueueBase; last: CommandQueue<T>);
    begin
      data.qs := qs;
      data.last := last;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function GetQS: sequence of CommandQueueBase := data.GetQS;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    data.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  SimpleSyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleSyncQueueArray)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := data.InvokeSync(g, l, data.last.InvokeToNil);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := data.InvokeSync(g, l, data.last.InvokeToVal);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.InvokeSync(g, l, data.last.InvokeToPtr);
    
  end;
  SimpleAsyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleAsyncQueueArray)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    new QueueResNil(new CLTaskLocalData( data.InvokeAsync(g, l, data.last.InvokeToNil).Item2 ));
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var (prev_qr, ev) := data.InvokeAsync(g, l, data.last.InvokeToAny);
      Result := prev_qr.WrapResult(qr_factory, ev);
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
{$endregion Simple}

{$region Conv}

{$region Generic}

type
  
  {$region Background}
  
  {$region Base}
  
  BackgroundConvQueueArrayBase<TInp, TRes, TFunc> = abstract class(BackgroundConvertQueue<array of TInp, TRes>)
  where TFunc: Delegate;
    protected qs: array of CommandQueue<TInp>;
    protected f: TFunc;
    
    public constructor(qs: array of CommandQueue<TInp>; f: TFunc);
    begin
      self.qs := qs;
      self.f := f;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    foreach var q in qs do q.InitBeforeInvoke(g, inited_hubs);
    
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function CombineQRs(qrs: array of QueueRes<TInp>; l: CLTaskLocalData): QueueResVal<array of TInp>;
    begin
      if qrs.All(qr->qr.IsConst) then
      begin
        var res := qrs.ConvertAll(qr->qr.GetResDirect);
        Result := new QueueResVal<array of TInp>(l, res);
      end else
      begin
        Result := new QueueResVal<array of TInp>(l);
        Result.AddResSetter(c->qrs.ConvertAll(qr->qr.GetResDirect));
      end;
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      foreach var q in qs do
        q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, f);
      sb += #10;
    end;
    
  end;
  
  {$endregion Base}
  
  {$region Sync}
  
  BackgroundConvSyncQueueArrayBase<TInp, TRes, TFunc> = abstract class(BackgroundConvQueueArrayBase<TInp, TRes, TFunc>)
  where TFunc: Delegate;
    
    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<array of TInp>; override;
    begin
      var qrs := new QueueRes<TInp>[qs.Length];
      
      for var i := 0 to qs.Length-1 do
      begin
        var qr := qs[i].InvokeToAny(g, l);
        l := qr.TakeBaseOut;
        qrs[i] := qr;
      end;
      
      Result := CombineQRs(qrs, l);
    end;
    
  end;
  
  BackgroundConvSyncQueueArray<TInp, TRes> = sealed class(BackgroundConvSyncQueueArrayBase<TInp, TRes, Func<array of TInp, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o);
    
  end;
  BackgroundConvSyncQueueArrayC<TInp, TRes> = sealed class(BackgroundConvSyncQueueArrayBase<TInp, TRes, Func<array of TInp, Context, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
  {$endregion Sync}
  
  {$region Async}
  
  BackgroundConvAsyncQueueArrayBase<TInp, TRes, TFunc> = abstract class(BackgroundConvQueueArrayBase<TInp, TRes, TFunc>)
  where TFunc: Delegate;
    
    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<array of TInp>; override;
    begin
      var qrs := new QueueRes<TInp>[qs.Length];
      var evs := new EventList[qs.Length];
      
      g.ParallelInvoke(l, qs.Length, invoker->
      for var i := 0 to qs.Length-1 do
      begin
        var qr := invoker.InvokeBranch(qs[i].InvokeToAny);
        qrs[i] := qr;
        evs[i] := qr.AttachInvokeActions(g);
      end);
      
      var res_ev := EventList.Combine(evs);
      Result := CombineQRs(qrs, new CLTaskLocalData(res_ev));
    end;
    
  end;
  
  BackgroundConvAsyncQueueArray<TInp, TRes> = sealed class(BackgroundConvAsyncQueueArrayBase<TInp, TRes, Func<array of TInp, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o);
    
  end;
  BackgroundConvAsyncQueueArrayC<TInp, TRes> = sealed class(BackgroundConvAsyncQueueArrayBase<TInp, TRes, Func<array of TInp, Context, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
  {$endregion Async}
  
  {$endregion Background}
  
  {$region Quick}
  
  {$region Base}
  
  QuickConvQueueArrayBase<TInp, TRes, TFunc> = abstract class(CommandQueue<TRes>)
  where TFunc: Delegate;
    protected qs: array of CommandQueue<TInp>;
    protected f: TFunc;
    
    public constructor(qs: array of CommandQueue<TInp>; f: TFunc);
    begin
      self.qs := qs;
      self.f := f;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    foreach var q in qs do q.InitBeforeInvoke(g, inited_hubs);
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; abstract;
    
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function CombineQRsNil(qrs: array of QueueRes<TInp>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;
    begin
      Result := new QueueResNil(l);
      var d := QueueResActionUtils.HandlerWrapStrip(g.curr_err_handler, ExecFunc);
      if l.ShouldInstaCallAction then
        d(qrs.ConvertAll(qr->qr.GetResDirect), g.c) else
        Result.AddAction(c->d(qrs.ConvertAll(qr->qr.GetResDirect), c));
    end;
    
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function CombineQRsRes<TF,TR>(qrs: array of QueueRes<TInp>; g: CLTaskGlobalData; l: CLTaskLocalData): TR; where TF: IQueueResFactory<TRes,TR>, constructor; where TR: QueueRes<TRes>;
    begin
      //TODO #2644: &<>
      var d := QueueResActionUtils.HandlerWrap&<array of TInp, TRes>(g.curr_err_handler, ExecFunc);
      if l.ShouldInstaCallAction then
      begin
        var res := d(qrs.ConvertAll(qr->qr.GetResDirect), g.c);
        Result := TF.Create.MakeConst(l, res);
      end else
      begin
        Result := TF.Create.MakeDelayed(l);
        Result.AddResSetter(c->d(qrs.ConvertAll(qr->qr.GetResDirect), c));
      end;
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      foreach var q in qs do
        q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, f);
      sb += #10;
    end;
    
  end;
  
  {$endregion Base}
  
  {$region Sync}
  
  QuickConvSyncQueueArrayBase<TInp, TRes, TFunc> = abstract class(QuickConvQueueArrayBase<TInp, TRes, TFunc>)
  where TFunc: Delegate;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TF,TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory_sample: TF; CombineQRs: Func<array of QueueRes<TInp>, CLTaskGlobalData, CLTaskLocalData, TR>): TR; where TF: IQueueResBaseFactory<TR>, constructor; where TR: IQueueRes;
    begin
      var qrs := new QueueRes<TInp>[qs.Length];
      
      for var i := 0 to qs.Length-1 do
      begin
        var qr := qs[i].InvokeToAny(g, l);
        l := qr.TakeBaseOut;
        qrs[i] := qr;
      end;
      
      Result := CombineQRs(qrs, g, l);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory, CombineQRsNil);
    //TODO #????
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override := Invoke&<QueueResValFactory<TRes>,QueueResVal<TRes>>(g, l, qr_val_factory, CombineQRsRes&<QueueResValFactory<TRes>,QueueResVal<TRes>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke&<QueueResPtrFactory<TRes>,QueueResPtr<TRes>>(g, l, qr_ptr_factory, CombineQRsRes&<QueueResPtrFactory<TRes>,QueueResPtr<TRes>>);
    
  end;
  
  QuickConvSyncQueueArray<TInp, TRes> = sealed class(QuickConvSyncQueueArrayBase<TInp, TRes, Func<array of TInp, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o);
    
  end;
  QuickConvSyncQueueArrayC<TInp, TRes> = sealed class(QuickConvSyncQueueArrayBase<TInp, TRes, Func<array of TInp, Context, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
  {$endregion Sync}
  
  {$region Async}
  
  QuickConvAsyncQueueArrayBase<TInp, TRes, TFunc> = abstract class(QuickConvQueueArrayBase<TInp, TRes, TFunc>)
  where TFunc: Delegate;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TF,TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory_sample: TF; CombineQRs: Func<array of QueueRes<TInp>, CLTaskGlobalData, CLTaskLocalData, TR>): TR; where TF: IQueueResBaseFactory<TR>, constructor; where TR: IQueueRes;
    begin
      var qrs := new QueueRes<TInp>[qs.Length];
      var evs := new EventList[qs.Length];
      
      g.ParallelInvoke(l, qs.Length, invoker->
      for var i := 0 to qs.Length-1 do
      begin
        var qr := invoker.InvokeBranch(qs[i].InvokeToAny);
        evs[i] := qr.AttachInvokeActions(g);
        qrs[i] := qr;
      end);
      
      var res_ev := EventList.Combine(evs);
      Result := CombineQRs(qrs, g, new CLTaskLocalData(res_ev));
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory, CombineQRsNil);
    //TODO #????
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override := Invoke&<QueueResValFactory<TRes>,QueueResVal<TRes>>(g, l, qr_val_factory, CombineQRsRes&<QueueResValFactory<TRes>,QueueResVal<TRes>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke&<QueueResPtrFactory<TRes>,QueueResPtr<TRes>>(g, l, qr_ptr_factory, CombineQRsRes&<QueueResPtrFactory<TRes>,QueueResPtr<TRes>>);
    
  end;
  
  QuickConvAsyncQueueArray<TInp, TRes> = sealed class(QuickConvAsyncQueueArrayBase<TInp, TRes, Func<array of TInp, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o);
    
  end;
  QuickConvAsyncQueueArrayC<TInp, TRes> = sealed class(QuickConvAsyncQueueArrayBase<TInp, TRes, Func<array of TInp, Context, TRes>>)
    
    protected function ExecFunc(o: array of TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
  {$endregion Async}
  
  {$endregion Quick}
  
{$endregion Generic}

{%ConvQueue\AllStaticArrays!ConvQueueStaticArray.pas%}

{$endregion Conv}

{$region Utils}

type
  QueueArrayFlattener<TArray> = sealed class(ITypedCQUser)
  where TArray: ISimpleQueueArray;
    public qs := new List<CommandQueueBase>;
    private has_next := false;
    
    public procedure ProcessSeq(s: sequence of CommandQueueBase);
    begin
      var enmr := s.GetEnumerator;
      if not enmr.MoveNext then raise new System.ArgumentException('%Err:FlattenQueueArray:InpEmpty%');
      
      var upper_had_next := self.has_next;
      while true do
      begin
        var curr := enmr.Current;
        var l_has_next := enmr.MoveNext;
        self.has_next := upper_had_next or l_has_next;
        curr.UseTyped(self);
        if not l_has_next then break;
      end;
      self.has_next := upper_had_next;
      
    end;
    
    public procedure ITypedCQUser.UseNil(cq: CommandQueueNil);
    begin
      // Нельзя пропускать - тут можно быть HPQ, WaitFor и т.п. работа без результата
//      if has_next then exit;
      qs.Add(cq);
    end;
    public procedure ITypedCQUser.Use<T>(cq: CommandQueue<T>);
    begin
      if has_next then
      begin
        if cq is ConstQueue<T> then exit;
        if cq is ParameterQueue<T> then exit;
        if cq is CastQueueBase<T>(var cqb) then
        begin
          cqb.SourceBase.UseTyped(self);
          exit;
        end;
      end;
      if cq is TArray(var sqa) then
        ProcessSeq(sqa.GetQs) else
        qs.Add(cq);
    end;
    
  end;
  
  QueueArrayConstructorBase = abstract class
    private body: array of CommandQueueBase;
    
    public constructor(body: array of CommandQueueBase) := self.body := body;
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  QueueArraySyncConstructor = sealed class(QueueArrayConstructorBase, ITypedCQConverter<CommandQueueBase>)
    public function ConvertNil(last: CommandQueueNil): CommandQueueBase := new SimpleSyncQueueArrayNil(body, last);
    public function Convert<T>(last: CommandQueue<T>): CommandQueueBase := new SimpleSyncQueueArray<T>(body, last);
  end;
  QueueArrayAsyncConstructor = sealed class(QueueArrayConstructorBase, ITypedCQConverter<CommandQueueBase>)
    public function ConvertNil(last: CommandQueueNil): CommandQueueBase := new SimpleAsyncQueueArrayNil(body, last);
    public function Convert<T>(last: CommandQueue<T>): CommandQueueBase := new SimpleAsyncQueueArray<T>(body, last);
  end;
  
  QueueArrayUtils = static class
    
    public static function FlattenQueueArray<T>(inp: sequence of CommandQueueBase): ValueTuple<List<CommandQueueBase>,CommandQueueBase>; where T: ISimpleQueueArray;
    begin
      var res := new QueueArrayFlattener<T>;
      res.ProcessSeq(inp);
      var last_ind := res.qs.Count-1;
      var last := res.qs[last_ind];
      res.qs.RemoveAt(last_ind);
      Result := ValueTuple.Create(res.qs,last);
    end;
    
    public static function ConstructSync(inp: sequence of CommandQueueBase): CommandQueueBase;
    begin
      var (body,last) := FlattenQueueArray&<ISimpleSyncQueueArray>(inp);
      Result := if body.Count=0 then last else last.ConvertTyped(new QueueArraySyncConstructor(body.ToArray));
    end;
    public static function ConstructSyncNil(inp: sequence of CommandQueueBase) := CommandQueueNil ( ConstructSync(inp) );
    public static function ConstructSync<T>(inp: sequence of CommandQueueBase) := CommandQueue&<T>( ConstructSync(inp) );
    
    public static function ConstructAsync(inp: sequence of CommandQueueBase): CommandQueueBase;
    begin
      var (body,last) := FlattenQueueArray&<ISimpleAsyncQueueArray>(inp);
      Result := if body.Count=0 then last else last.ConvertTyped(new QueueArrayAsyncConstructor(body.ToArray));
    end;
    public static function ConstructAsyncNil(inp: sequence of CommandQueueBase) := CommandQueueNil ( ConstructAsync(inp) );
    public static function ConstructAsync<T>(inp: sequence of CommandQueueBase) := CommandQueue&<T>( ConstructAsync(inp) );
    
  end;
  
{$endregion Utils}

static function CommandQueueNil.operator+(q1: CommandQueueBase; q2: CommandQueueNil) := QueueArrayUtils. ConstructSyncNil(|q1, q2|);
static function CommandQueueNil.operator*(q1: CommandQueueBase; q2: CommandQueueNil) := QueueArrayUtils.ConstructAsyncNil(|q1, q2|);

static function CommandQueue<T>.operator+(q1: CommandQueueBase; q2: CommandQueue<T>) := QueueArrayUtils. ConstructSync&<T>(|q1, q2|);
static function CommandQueue<T>.operator*(q1: CommandQueueBase; q2: CommandQueue<T>) := QueueArrayUtils.ConstructAsync&<T>(|q1, q2|);

{$endregion +/*}

{$region Multiusable}

type
  MultiusableCommandQueueHubCommon<TQ> = abstract class(IMultiusableCommandQueueHub)
  where TQ: CommandQueueBase;
    public q: TQ;
    public constructor(q: TQ) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>) :=
    if inited_hubs.Add(self) then q.InitBeforeInvoke(g, inited_hubs);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_q: CommandQueueInvoker<TR>): ValueTuple<TR, EventList>; where TR: IQueueRes;
    begin
      var res_data: MultiuseableResultData;
      var qr: TR;
      
      // Потоко-безопасно, потому что все .Invoke выполняются синхронно
      //TODO А что будет когда .ThenIf и т.п.?
      if g.mu_res.TryGetValue(self, res_data) then
        qr := TR(res_data.qres) else
      begin
        var prev_err_handler := g.curr_err_handler;
        g.curr_err_handler := new CLTaskErrHandlerEmpty;
        
        qr := invoke_q(g, new CLTaskLocalData);
        var ev := qr.AttachInvokeActions(g);
        
        res_data := new MultiuseableResultData(qr, ev, g.curr_err_handler);
        g.mu_res[self] := res_data;
        
        g.curr_err_handler := prev_err_handler;
      end;
      g.curr_err_handler := new CLTaskErrHandlerThiefRepeater(g.curr_err_handler, res_data.err_handler);
      
      res_data.ev.Retain({$ifdef EventDebug}$'for all mu branches'{$endif});
      Result := ValueTuple.Create( qr, res_data.ev + QueueResNil.Create(l).AttachInvokeActions(g) );
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += ' => ';
      if q.ToStringHeader(sb, index) then
        delayed.Add(q);
      sb += #10;
    end;
    
  end;
  
  MultiusableCommandQueueHubNil = sealed partial class(MultiusableCommandQueueHubCommon< CommandQueueNil >) end;
  MultiusableCommandQueueNodeNil = sealed class(CommandQueueNil)
    public hub: MultiusableCommandQueueHubNil;
    
    public constructor(hub: MultiusableCommandQueueHubNil) := self.hub := hub;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := hub.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var (qr, ev) := hub.Invoke(g, l, hub.q.InvokeToNil);
      Result := new QueueResNil(new CLTaskLocalData(ev));
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    hub.ToString(sb, tabs, index, delayed);
    
  end;
  MultiusableCommandQueueHubNil = sealed partial class
    
    public function MakeNode: CommandQueueNil := new MultiusableCommandQueueNodeNil(self);
    
  end;
  
  MultiusableCommandQueueHub<T> = sealed partial class(MultiusableCommandQueueHubCommon< CommandQueue<T> >) end;
  MultiusableCommandQueueNode<T> = sealed class(CommandQueue<T>)
    public hub: MultiusableCommandQueueHub<T>;
    
    public constructor(hub: MultiusableCommandQueueHub<T>) := self.hub := hub;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := hub.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var (qr, ev) := hub.Invoke(g, l, hub.q.InvokeToAny);
      Result := new QueueResNil(new CLTaskLocalData(ev));
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T, TR>): TR; where TR: QueueRes<T>;
    begin
      var (qr, ev) := hub.Invoke(g, l, hub.q.InvokeToAny);
      Result := qr.WrapResult(qr_factory, ev);
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    hub.ToString(sb, tabs, index, delayed);
    
  end;
  MultiusableCommandQueueHub<T> = sealed partial class
    
    public function MakeNode: CommandQueue<T> := new MultiusableCommandQueueNode<T>(self);
    
  end;
  
function CommandQueueNil.Multiusable: ()->CommandQueueNil := (if self is MultiusableCommandQueueNodeNil(var mucqn) then mucqn.hub else new MultiusableCommandQueueHubNil(self)).MakeNode;
function CommandQueue<T>.Multiusable: ()->CommandQueue<T> := (if self is MultiusableCommandQueueNode<T>(var mucqn) then mucqn.hub else new MultiusableCommandQueueHub<T>(self)).MakeNode;

{$endregion Multiusable}

{$region Wait}

{$region Def}
//TODO Куча дублей кода, особенно в Combination
//TODO data ничего не делает, кроме как для WaitDebug, потому что state хранится в sub_info
// - Лучше передавать self.GetHashCode
//TODO Отписка никогда не происходит - пока не сделал, чтоб перепродумывать как обрабатывать всё при циклах

{$region Base}

type
  WaitMarker = abstract partial class
    
    public procedure InitInnerHandles(g: CLTaskGlobalData); abstract;
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; abstract;
    public function MakeWaitEv(g: CLTaskGlobalData; l: CLTaskLocalData) := MakeWaitEv(g, QueueResNil.Create(l).AttachInvokeActions(g));
    
  end;
  
{$endregion Base}

{$region Outer}

type
  /// wait_handler, который можно встроить в очередь как есть
  WaitHandlerOuter = abstract class
    public uev: UserEvent;
    private state := 0;
    private gc_hnd: GCHandle;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList);
    begin
      
      uev := new UserEvent(g.cl_c{$ifdef EventDebug}, $'Wait result'{$endif});
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Created outer with prev_ev=[ {prev_ev.evs?.JoinToString} ], res_ev={uev}');
      {$endif WaitDebug}
      self.gc_hnd := GCHandle.Alloc(self);
      
      // Code of .ThenFinallyWaitFor expects
      // g.curr_err_handler to not change
      // and no new errors to be added
      var err_handler := g.curr_err_handler;
      prev_ev.MultiAttachCallback(()->
      begin
        if err_handler.HadError then
        begin
          {$ifdef WaitDebug}
          WaitDebug.RegisterAction(self, $'Aborted');
          {$endif WaitDebug}
          uev.SetComplete;
          self.gc_hnd.Free;
        end else
        begin
          {$ifdef WaitDebug}
          WaitDebug.RegisterAction(self, $'Got prev_ev boost');
          {$endif WaitDebug}
          self.IncState;
        end;
      end{$ifdef EventDebug}, $'KeepAlive(handler[{self.GetHashCode}])'{$endif});
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function TryConsume: boolean; abstract;
    
    protected function IncState: boolean;
    begin
      var new_state := Interlocked.Increment(self.state);
      
      {$ifdef DEBUG}
      if not new_state.InRange(1,2) then raise new OpenCLABCInternalException($'WaitHandlerOuter.state={new_state}');
      {$endif DEBUG}
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Advanced to state {new_state}');
      {$endif WaitDebug}
      
      Result := (new_state=2) and TryConsume;
      if Result then self.gc_hnd.Free;
    end;
    protected procedure DecState;
    begin
      {$ifdef DEBUG}
      var new_state :=
      {$endif DEBUG}
      Interlocked.Decrement(self.state);
      
      {$ifdef DEBUG}
      if not new_state.InRange(0,1) then
        raise new OpenCLABCInternalException($'WaitHandlerOuter.state={new_state}');
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Gone back to state {new_state}');
      {$endif WaitDebug}
      
      {$endif DEBUG}
      
    end;
    
  end;
  
{$endregion Outer}

{$region Direct}

type
  IWaitHandlerSub = interface
    
    // Возвращает true, если активацию успешно съели
    function HandleChildInc(data: integer): boolean;
    procedure HandleChildDec(data: integer);
    
  end;
  
  WaitHandlerDirectSubInfo = class
    public threshold, data: integer;
    public state := new InterlockedBoolean;
    public constructor(threshold, data: integer);
    begin
      self.threshold := threshold;
      self.data := data;
    end;
    public constructor := raise new OpenCLABCInternalException;
  end;
  /// Напрямую хранит активации конкретного CLTaskGlobalData
  WaitHandlerDirect = sealed class
    private subs := new ConcurrentDictionary<IWaitHandlerSub, WaitHandlerDirectSubInfo>;
    private activations := 0;
    private reserved := 0;
    
    public procedure Subscribe(sub: IWaitHandlerSub; info: WaitHandlerDirectSubInfo);
    begin
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got new sub {sub.GetHashCode}');
      {$endif WaitDebug}
      
      if not subs.TryAdd(sub, info) then
      begin
        {$ifdef DEBUG}
        raise new OpenCLABCInternalException($'Sub added twice');
        {$endif DEBUG}
      end else
      if activations>=info.threshold then
        if info.state.TrySet(true) then
        begin
          {$ifdef WaitDebug}
          WaitDebug.RegisterAction(self, $'Add immidiatly inced sub {sub.GetHashCode}');
          {$endif WaitDebug}
          // Может выполняться одновременно с AddActivation, в таком случае 
          sub.HandleChildInc(info.data);
        end;
    end;
    
    public procedure AddActivation;
    begin
      {$ifdef WaitDebug}
      var new_act :=
      {$endif WaitDebug}
      Interlocked.Increment(activations);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation =>{new_act}');
      {$endif WaitDebug}
      
      foreach var kvp in subs do
        // activations может изменится, если .HandleChildInc из
        // .AddActivation другого хэндлера или .Subscribe затронет self.activations
        // Поэтому результат Interlocked.Increment использовать нельзя
        if activations>=kvp.Value.threshold then
          if kvp.Value.state.TrySet(true) and kvp.Key.HandleChildInc(kvp.Value.data) then
          begin
            {$ifdef WaitDebug}
            WaitDebug.RegisterAction(self, $'Sub {kvp.Key.GetHashCode} consumed activation =>{activations}');
            {$endif WaitDebug}
            // Если активацию съели - нет смысла продолжать
            break;
          end;
    end;
    
    public function TryReserve(c: integer): boolean;
    begin
      var n_reserved := Interlocked.Add(reserved, c);
      Result := n_reserved<=activations;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Tried to reserve {c}=>{n_reserved}: {Result}');
      {$endif WaitDebug}
      
      // Надо делать там, где было вызвано TryReserve
      // Потому что TryReserve не последняя проверка, есть ещё uev.SetStatus
//      if not Result then ReleaseReserve(c);
    end;
    public procedure ReleaseReserve(c: integer) :=
    if Interlocked.Add(reserved, -c)<0 then
    begin
      {$ifdef DEBUG}
      raise new OpenCLABCInternalException($'reserved={reserved}');
      {$endif DEBUG}
    end else
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Released reserve {c}=>{reserved}');
      {$endif WaitDebug}
    end;
    
    public procedure Comsume(c: integer);
    begin
      var new_act := Interlocked.Add(activations, -c);
      var new_res := Interlocked.Add(reserved, -c);
      {$ifdef DEBUG}
      if (new_act<0) or (new_res<0) then
        raise new OpenCLABCInternalException($'new_act={new_act}, new_res={new_res}');
      {$endif DEBUG}
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Sub consumed {c}, new_act={new_act}, new_res={new_res}');
      {$endif WaitDebug}
      
      foreach var kvp in subs do
        if activations<kvp.Value.threshold then
          if kvp.Value.state.TrySet(false) then
            kvp.Key.HandleChildDec(kvp.Value.data);
    end;
    
  end;
  /// Обёртка WaitHandlerDirect, которая является WaitHandlerOuter
  WaitHandlerDirectWrap = sealed class(WaitHandlerOuter, IWaitHandlerSub)
    private source: WaitHandlerDirect;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList; source: WaitHandlerDirect);
    begin
      inherited Create(g, prev_ev);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'This is DirectWrap for {source.GetHashCode}');
      {$endif WaitDebug}
      self.source := source;
      source.Subscribe(self, new WaitHandlerDirectSubInfo(1,0));
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function IWaitHandlerSub.HandleChildInc(data: integer) := self.IncState;
    public procedure IWaitHandlerSub.HandleChildDec(data: integer) := self.DecState;
    
    protected function TryConsume: boolean; override;
    begin
      Result := source.TryReserve(1) and self.uev.SetComplete;
      if not Result then source.ReleaseReserve(1);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Tried reserving {1} in source[{source.GetHashCode}]: {Result}');
      {$endif WaitDebug}
      
      if Result then source.Comsume(1);
    end;
    
  end;
  
  /// Маркер, не ссылающийся на другие маркеры
  WaitMarkerDirect = abstract class(WaitMarker)
    private handlers := new ConcurrentDictionary<CLTaskGlobalData, WaitHandlerDirect>;
    
    public procedure InitInnerHandles(g: CLTaskGlobalData); override :=
    handlers.GetOrAdd(g, g->
    begin
      Result := new WaitHandlerDirect;
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(Result, $'Created for {self.GetType.Name}[{self.GetHashCode}]');
      {$endif WaitDebug}
    end);
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; override :=
    WaitHandlerDirectWrap.Create(g, prev_ev, handlers[g]).uev;
    
    public procedure SendSignal; override :=
    foreach var h in handlers.Values do
      h.AddActivation;
    
  end;
  
{$endregion Direct}

{$region Combination}

{$region Base}

type
  WaitMarkerCombination<TChild> = abstract class(WaitMarker)
  where TChild: WaitMarker;
    private children: array of TChild;
    
    public constructor(children: array of TChild) := self.children := children;
    public constructor := raise new OpenCLABCInternalException;
    
    public procedure InitInnerHandles(g: CLTaskGlobalData); override :=
    foreach var child in children do child.InitInnerHandles(g);
    
    {$region Disabled override's}
    
    private function ConvertToQBase: CommandQueueBase; override;
    begin
      Result := nil;
      raise new System.InvalidProgramException($'%Err:WaitMarkerCombination.ConvertToQBase%');
    end;
    
    public procedure SendSignal; override :=
    raise new System.InvalidProgramException($'Err:WaitMarkerCombination.SendSignal');
    
    {$endregion Disabled override's}
    
  end;
  
{$endregion Base}

{$region All}

type
  WaitHandlerAllInner<TSub> = sealed class(IWaitHandlerSub)
  where TSub: IWaitHandlerSub;
    private sources: array of WaitHandlerDirect;
    private ref_counts: array of integer;
    private done_c := 0;
    
    private sub: TSub;
    private sub_data: integer;
    
    public constructor(sources: array of WaitHandlerDirect; ref_counts: array of integer; sub: TSub; sub_data: integer);
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Created AllInner for: {sources.Select(s->s.GetHashCode).JoinToString}');
      {$endif WaitDebug}
      self.sources := sources;
      for var i := 0 to sources.Length-1 do
        sources[i].Subscribe(self, new WaitHandlerDirectSubInfo(ref_counts[i], i));
      self.ref_counts := ref_counts;
      self.sub := sub;
      self.sub_data := sub_data;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function IWaitHandlerSub.HandleChildInc(data: integer): boolean;
    begin
      var new_done_c := Interlocked.Increment(done_c);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation from {sources[data].GetHashCode}, new_done_c={new_done_c}/{sources.Length}');
      {$endif WaitDebug}
      
      Result := (new_done_c=sources.Length) and sub.HandleChildInc(sub_data);
    end;
    public procedure IWaitHandlerSub.HandleChildDec(data: integer);
    begin
      var prev_done_c := Interlocked.Decrement(done_c)+1;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got deactivation from {sources[data].GetHashCode}, new_done_c={prev_done_c-1}/{sources.Length}');
      {$endif WaitDebug}
      
      if prev_done_c=sources.Length then sub.HandleChildDec(sub_data);
    end;
    
    public function TryConsume(uev: UserEvent): boolean;
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Trying to reserve');
      {$endif WaitDebug}
      Result := false;
      for var i := 0 to sources.Length-1 do
      begin
        if sources[i].TryReserve(ref_counts[i]) then continue;
        for var prev_i := 0 to i do
          sources[i].ReleaseReserve(ref_counts[i]);
        exit;
      end;
      Result := uev.SetComplete;
      if Result then
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Consuming');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].Comsume(ref_counts[i]);
      end else
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Abort consume');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].ReleaseReserve(ref_counts[i]);
      end;
    end;
    
  end;
  WaitHandlerAllOuter = sealed class(WaitHandlerOuter, IWaitHandlerSub)
    private sources: array of WaitHandlerDirect;
    private ref_counts: array of integer;
    private done_c := 0;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList; sources: array of WaitHandlerDirect; ref_counts: array of integer);
    begin
      inherited Create(g, prev_ev);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'This is AllOuter for: {sources.Select(s->s.GetHashCode).JoinToString}');
      {$endif WaitDebug}
      self.sources := sources;
      for var i := 0 to sources.Length-1 do
        sources[i].Subscribe(self, new WaitHandlerDirectSubInfo(ref_counts[i], i));
      self.ref_counts := ref_counts;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function IWaitHandlerSub.HandleChildInc(data: integer): boolean;
    begin
      var new_done_c := Interlocked.Increment(done_c);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation from {sources[data].GetHashCode}, new_done_c={new_done_c}/{sources.Length}');
      {$endif WaitDebug}
      
      Result := (new_done_c=sources.Length) and self.IncState;
    end;
    public procedure IWaitHandlerSub.HandleChildDec(data: integer);
    begin
      var prev_done_c := Interlocked.Decrement(done_c)+1;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got deactivation from {sources[data].GetHashCode}, new_done_c={prev_done_c-1}/{sources.Length}');
      {$endif WaitDebug}
      
      if prev_done_c=sources.Length then self.DecState;
    end;
    
    protected function TryConsume: boolean; override;
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Trying to reserve');
      {$endif WaitDebug}
      Result := false;
      for var i := 0 to sources.Length-1 do
      begin
        if sources[i].TryReserve(ref_counts[i]) then continue;
        for var prev_i := 0 to i do
          sources[i].ReleaseReserve(ref_counts[i]);
        exit;
      end;
      Result := uev.SetComplete;
      if Result then
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Consuming');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].Comsume(ref_counts[i]);
      end else
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Abort consume');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].ReleaseReserve(ref_counts[i]);
      end;
    end;
    
  end;
  
  WaitMarkerAll = sealed partial class(WaitMarkerCombination<WaitMarkerDirect>)
    private ref_counts: array of integer;
    
    public constructor(children: Dictionary<WaitMarkerDirect, integer>);
    begin
      inherited Create(children.Keys.ToArray);
      self.ref_counts := self.children.ConvertAll(key->children[key]);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      foreach var i in Range(0,children.Length-1).OrderByDescending(i->ref_counts[i]) do
      begin
        children[i].ToString(sb, tabs, index, delayed);
        if ref_counts[i]<>1 then
        begin
          sb.Length -= 1;
          sb += ' * ';
          sb.Append(ref_counts[i]);
          sb += #10;
        end;
      end;
    end;
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; override :=
    WaitHandlerAllOuter.Create(g, prev_ev, children.ConvertAll(m->m.handlers[g]), ref_counts).uev;
    
    private function GetChildrenArr: array of WaitMarkerDirect;
    begin
      Result := new WaitMarkerDirect[ref_counts.Sum];
      var res_ind := 0;
      for var i := 0 to children.Length-1 do
        loop ref_counts[i] do
        begin
          Result[res_ind] := children[i];
          res_ind += 1;
        end;
    end;
    
  end;
  
{$endregion All}

{$region Any}

type
  WaitHandlerAnyOuter = sealed class(WaitHandlerOuter, IWaitHandlerSub)
    private sources: array of WaitHandlerAllInner<WaitHandlerAnyOuter>;
    
    private done_c := 0;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList; markers: array of WaitMarkerAll);
    begin
      inherited Create(g, prev_ev);
      self.sources := new WaitHandlerAllInner<WaitHandlerAnyOuter>[markers.Length];
      for var i := 0 to markers.Length-1 do
        self.sources[i] := new WaitHandlerAllInner<WaitHandlerAnyOuter>(markers[i].children.ConvertAll(m->m.handlers[g]), markers[i].ref_counts, self, i);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'This is AnyOuter for: {sources.Select(s->s.GetHashCode).JoinToString}');
      {$endif WaitDebug}
    end;
    public constructor := raise new OpenCLABCInternalException;
    
    public function IWaitHandlerSub.HandleChildInc(data: integer): boolean;
    begin
      var new_done_c := Interlocked.Increment(done_c);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation from {sources[data].GetHashCode}, new_done_c={new_done_c}/{sources.Length}');
      {$endif WaitDebug}
      
      Result := (new_done_c=1) and self.IncState;
    end;
    public procedure IWaitHandlerSub.HandleChildDec(data: integer);
    begin
      var prev_done_c := Interlocked.Decrement(done_c)+1;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got deactivation from {sources[data].GetHashCode}, new_done_c={prev_done_c-1}/{sources.Length}');
      {$endif WaitDebug}
      
      if prev_done_c=1 then self.DecState;
    end;
    
    protected function TryConsume: boolean; override;
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Trying to consume');
      {$endif WaitDebug}
      Result := false;
      for var i := 0 to sources.Length-1 do
        if sources[i].TryConsume(uev) then
        begin
          Result := true;
          break;
        end;
    end;
    
  end;
  
  WaitMarkerAny = sealed partial class(WaitMarkerCombination<WaitMarkerAll>)
    
    public constructor(sources: array of WaitMarkerAll) := inherited Create(sources);
    private constructor := raise new OpenCLABCInternalException;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      foreach var child in children do
        child.ToString(sb, tabs, index, delayed);
    end;
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; override :=
    WaitHandlerAnyOuter.Create(g, prev_ev, children).uev;
    
  end;
  
{$endregion Any}

{$region public}

type
  WaitMarkerAllFast = sealed class
    private children: Dictionary<WaitMarkerDirect, integer>;
    
    public constructor(c: integer) :=
    children := new Dictionary<WaitMarkerDirect, integer>(c);
    public constructor(m: WaitMarkerDirect);
    begin
      Create(1);
      self.children.Add(m, 1);
    end;
    public constructor(m: WaitMarkerAll);
    begin
      Create(m.children.Length);
      for var i := 0 to m.children.Length-1 do
        self.children.Add(m.children[i], m.ref_counts[i]);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public static function operator in(what, in_what: WaitMarkerAllFast): boolean;
    begin
      Result := false;
      
      if what.children.Count>in_what.children.Count then
        exit;
      foreach var kvp in what.children do
        if in_what.children.Get(kvp.Key) < kvp.Value then
          exit;
      
      Result := true;
    end;
    
    public static function operator+(c1, c2: WaitMarkerAllFast): WaitMarkerAllFast;
    begin
      Result := new WaitMarkerAllFast(c1.children.Count+c2.children.Count);
      foreach var kvp in c1.children do
        Result.children.Add(kvp.Key, kvp.Value);
      foreach var kvp in c2.children do
        Result.children[kvp.Key] := Result.children.Get(kvp.Key) + kvp.Value;
    end;
    
    public static procedure TryAdd(lst: List<WaitMarkerAllFast>; c: WaitMarkerAllFast);
    begin
      
      for var i := 0 to lst.Count-1 do
      begin
        var c0 := lst[i];
        
        if c0 in c then
          lst[i] := c else
        if c in c0 then
          {nothing} else
          continue;
        
        exit;
      end;
      
      lst += c;
    end;
    
    public static function MarkerFromLst(lst: IList<WaitMarkerAllFast>): WaitMarker;
    begin
      if lst.Count>1 then
      begin
        var res := new WaitMarkerAll[lst.Count];
        for var i := 0 to res.Length-1 do
          res[i] := new WaitMarkerAll(lst[i].children);
        Result := new WaitMarkerAny(res);
      end else
      case lst[0].children.Values.Sum of
        0: raise new System.ArgumentException($'%Err:WaitCombine:InpEmpty%');
        1: Result := lst[0].children.Keys.Single;
        else Result := new WaitMarkerAll(lst[0].children);
      end;
    end;
    
  end;
  
function WaitAll(sub_markers: sequence of WaitMarker): WaitMarker;
begin
  var prev := |new WaitMarkerAllFast(0)| as IList<WaitMarkerAllFast>;
  var next := new List<WaitMarkerAllFast>;
  
  foreach var m in sub_markers do
  begin
    
    if m is WaitMarkerAny(var ma) then
    begin
      foreach var child in ma.children do
      begin
        var c2 := new WaitMarkerAllFast(child);
        foreach var c1 in prev do
          WaitMarkerAllFast.TryAdd(next, c1+c2);
      end;
    end else
    begin
      var c2 := if m is WaitMarkerDirect(var md) then
        new WaitMarkerAllFast(md) else
        new WaitMarkerAllFast(WaitMarkerAll(m));
      foreach var c1 in prev do
        next += c1+c2;
    end;
    
    prev := next.ToArray;
    next.Clear;
  end;
  
  Result := WaitMarkerAllFast.MarkerFromLst(prev);
end;
function WaitAll(params sub_markers: array of WaitMarker) := WaitAll(sub_markers.AsEnumerable);

function WaitAny(sub_markers: sequence of WaitMarker): WaitMarker;
begin
  var res := new List<WaitMarkerAllFast>;
  foreach var m in sub_markers do
    if m is WaitMarkerAny(var ma) then
    begin
      foreach var child in ma.children do
        WaitMarkerAllFast.TryAdd(res, new WaitMarkerAllFast(child));
    end else
    begin
      var c := if m is WaitMarkerDirect(var md) then
        new WaitMarkerAllFast(md) else
        new WaitMarkerAllFast(WaitMarkerAll(m));
      WaitMarkerAllFast.TryAdd(res, c);
    end;
  Result := WaitMarkerAllFast.MarkerFromLst(res);
end;
function WaitAny(params sub_markers: array of WaitMarker) := WaitAny(sub_markers.AsEnumerable);

static function WaitMarker.operator and(m1, m2: WaitMarker) := WaitAll(|m1, m2|);
static function WaitMarker.operator or(m1, m2: WaitMarker) := WaitAny(|m1, m2|);

{$endregion public}

{$endregion Combination}

{$endregion Def}

{$region WaitMarkerDummy}

type
  WaitMarkerDummyExecutor = sealed class(CommandQueueNil)
    private m: WaitMarkerDirect;
    
    public constructor(m: WaitMarkerDirect) := self.m := m;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      Result := new QueueResNil(l);
      
      if Result.ShouldInstaCallAction then
      begin
        if not g.curr_err_handler.HadError then
          m.SendSignal;
      end else
      begin
        var err_handler := g.curr_err_handler;
        Result.AddAction(c->if not err_handler.HadError then m.SendSignal);
      end;
      
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      m.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  WaitMarkerDummy = sealed class(WaitMarkerDirect)
    private executor: WaitMarkerDummyExecutor;
    public constructor := executor := new WaitMarkerDummyExecutor(self);
    
    private function ConvertToQBase: CommandQueueBase; override := executor;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := sb += #10;
    
  end;
  
static function WaitMarker.Create := new WaitMarkerDummy;

{$endregion WaitMarkerDummy}

{$region ThenMarkerSignal}

type
  DetachedMarkerSignalWrapCommon<TQ> = abstract class(WaitMarkerDirect)
  where TQ: CommandQueueBase;
    protected org: TQ;
    
    public constructor(org: TQ) := self.org := org;
    private constructor := raise new OpenCLABCInternalException;
    
    private function ConvertToQBase: CommandQueueBase; override := org;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      sb.Append(#9, tabs);
      org.ToStringHeader(sb, index);
      sb += #10;
      
    end;
    
  end;
  
  DetachedMarkerSignalCommon<TQ> = record
  where TQ: CommandQueueBase;
    public q: TQ;
    public wrap: DetachedMarkerSignalWrapCommon<TQ>;
    public signal_in_finally: boolean;
    
    public procedure Init(q: TQ; wrap: DetachedMarkerSignalWrapCommon<TQ>; signal_in_finally: boolean);
    begin
      self.q := q;
      self.wrap := wrap;
      self.signal_in_finally := signal_in_finally;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>) := q.InitBeforeInvoke(g, inited_hubs);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(prev_qr: TR; err_handler: CLTaskErrHandler): TR; where TR: IQueueRes;
    begin
      if prev_qr.ShouldInstaCallAction then
      begin
        if signal_in_finally or not err_handler.HadError then
          wrap.SendSignal;
      end else
      if signal_in_finally then
        prev_qr.AddAction(c->wrap.SendSignal()) else
        prev_qr.AddAction(c->if not err_handler.HadError then wrap.SendSignal);
      Result := prev_qr;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      
      sb.Append(#9, tabs);
      wrap.ToStringHeader(sb, index);
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  DetachedMarkerSignalWrapperNil = sealed class(DetachedMarkerSignalWrapCommon<CommandQueueNil>)
    
  end;
  DetachedMarkerSignalNil = sealed partial class(CommandQueueNil)
    data: DetachedMarkerSignalCommon<CommandQueueNil>;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := data.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.Invoke(data.q.InvokeToNil(g,l), g.curr_err_handler);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  DetachedMarkerSignalWrapper<T> = sealed class(DetachedMarkerSignalWrapCommon<CommandQueue<T>>)
    
  end;
  DetachedMarkerSignal<T> = sealed partial class(CommandQueue<T>)
    data: DetachedMarkerSignalCommon<CommandQueue<T>>;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := data.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.Invoke(data.q.InvokeToNil(g,l), g.curr_err_handler);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := data.Invoke(data.q.InvokeToVal(g,l), g.curr_err_handler);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.Invoke(data.q.InvokeToPtr(g,l), g.curr_err_handler);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
function DetachedMarkerSignalNil.get_signal_in_finally := data.signal_in_finally;
function DetachedMarkerSignal<T>.get_signal_in_finally := data.signal_in_finally;

constructor DetachedMarkerSignalNil.Create(q: CommandQueueNil; signal_in_finally: boolean) :=
data.Init(q, new DetachedMarkerSignalWrapperNil(self), signal_in_finally);
constructor DetachedMarkerSignal<T>.Create(q: CommandQueue<T>; signal_in_finally: boolean) :=
data.Init(q, new DetachedMarkerSignalWrapper<T>(self), signal_in_finally);

static function DetachedMarkerSignalNil.operator implicit(dms: DetachedMarkerSignalNil) := dms.data.wrap;
static function DetachedMarkerSignal<T>.operator implicit(dms: DetachedMarkerSignal<T>) := dms.data.wrap;

{$endregion ThenMarkerSignal}

{$region WaitFor}

type
  CommandQueueWaitFor = sealed class(CommandQueueNil)
    public marker: WaitMarker;
    public constructor(marker: WaitMarker) := self.marker := marker;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    marker.InitInnerHandles(g);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    new QueueResNil(new CLTaskLocalData( marker.MakeWaitEv(g,l) ));
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      marker.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function WaitFor(marker: WaitMarker) := new CommandQueueWaitFor(marker);

{$endregion WaitFor}

{$region ThenWaitFor}

type
  CommandQueueThenBaseWaitFor<T> = abstract class(CommandQueue<T>)
    public q: CommandQueue<T>;
    public marker: WaitMarker;
    
    public constructor(q: CommandQueue<T>; marker: WaitMarker);
    begin
      self.q := q;
      self.marker := marker;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override;
    begin
      q.InitBeforeInvoke(g, inited_hubs);
      marker.InitInnerHandles(g);
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
      marker.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CommandQueueThenWaitFor<T> = sealed class(CommandQueueThenBaseWaitFor<T>)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var res_ev := marker.MakeWaitEv(g, q.InvokeToNil(g, l).base );
      Result := new QueueResNil(new CLTaskLocalData(res_ev));
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(prev_qr: QueueRes<T>; g: CLTaskGlobalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var res_ev := marker.MakeWaitEv(g, prev_qr.AttachInvokeActions(g));
      Result := prev_qr.WrapResult(qr_factory, res_ev);
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(q.InvokeToAny(g,l), g, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(q.InvokeToAny(g,l), g, qr_ptr_factory);
    
  end;
  CommandQueueThenFinallyWaitFor<T> = sealed class(CommandQueueThenBaseWaitFor<T>)
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_q: CommandQueueInvoker<TR>): ValueTuple<TR, EventList>; where TR: IQueueRes;
    begin
      
      var pre_q_err_handler := g.curr_err_handler;
      var prev_qr := invoke_q(g, l);
      var post_q_err_handler := g.curr_err_handler;
      
      g.curr_err_handler := pre_q_err_handler;
      var res_ev := marker.MakeWaitEv(g, prev_qr.AttachInvokeActions(g));
      {$ifdef DEBUG}
      if g.curr_err_handler <> pre_q_err_handler then
        raise new OpenCLABCInternalException($'MakeWaitEv should not change g.curr_err_handler');
      // Otherwise, CLTaskErrHandlerBranchBase (like in >=) would be needed
      {$endif DEBUG}
      g.curr_err_handler := post_q_err_handler;
      
      Result := ValueTuple.Create(prev_qr, res_ev);
    end;
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var (prev_qr, ev) := Invoke(g, l, q.InvokeToAny);
      Result := prev_qr.WrapResult(qr_factory, ev);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var (prev_qr, ev) := Invoke(g, l, q.InvokeToNil);
      Result := new QueueResNil(new CLTaskLocalData(ev));
    end;
    
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
function CommandQueue<T>.ThenWaitFor(marker: WaitMarker) := new CommandQueueThenWaitFor<T>(self, marker);
function CommandQueue<T>.ThenFinallyWaitFor(marker: WaitMarker) := new CommandQueueThenFinallyWaitFor<T>(self, marker);

{$endregion ThenWaitFor}

{$endregion Wait}

{$region Finally}

type
  CommandQueueTryFinallyCommon<TQ> = record
  where TQ: CommandQueueBase;
    public try_do: CommandQueueBase;
    public do_finally: TQ;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>);
    begin
      try_do.InitBeforeInvoke(g, inited_hubs);
      do_finally.InitBeforeInvoke(g, inited_hubs);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_finally: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      var origin_err_handler := g.curr_err_handler;
      
      {$region try_do}
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(origin_err_handler);
      l := try_do.InvokeToNil(g, l).base;
      var try_handler := g.curr_err_handler;
      
      {$endregion try_do}
      
      {$region do_finally}
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(origin_err_handler);
      Result := invoke_finally(g, l);
      var fin_handler := g.curr_err_handler;
      
      {$endregion do_finally}
      
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(origin_err_handler, |try_handler, fin_handler|);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      try_do.ToString(sb, tabs, index, delayed);
      do_finally.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CommandQueueTryFinallyNil = sealed class(CommandQueueNil)
    private data := new CommandQueueTryFinallyCommon< CommandQueueNil >;
    
    private constructor(try_do: CommandQueueBase; do_finally: CommandQueueNil);
    begin
      data.try_do := try_do;
      data.do_finally := do_finally;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    data.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.Invoke(g, l, data.do_finally.InvokeToNil);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  CommandQueueTryFinally<T> = sealed class(CommandQueue<T>)
    private data := new CommandQueueTryFinallyCommon< CommandQueue<T> >;
    
    private constructor(try_do: CommandQueueBase; do_finally: CommandQueue<T>);
    begin
      data.try_do := try_do;
      data.do_finally := do_finally;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    data.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := data.Invoke(g, l, data.do_finally.InvokeToNil);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := data.Invoke(g, l, data.do_finally.InvokeToVal);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.Invoke(g, l, data.do_finally.InvokeToPtr);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
static function CommandQueueNil.operator>=(try_do: CommandQueueBase; do_finally: CommandQueueNil) :=
new CommandQueueTryFinallyNil(try_do, do_finally);
static function CommandQueue<T>.operator>=(try_do: CommandQueueBase; do_finally: CommandQueue<T>) :=
new CommandQueueTryFinally<T>(try_do, do_finally);

{$endregion Finally}

{$region Handle}

type
  
  CommandQueueHandleWithoutRes = sealed class(CommandQueueNil)
    private try_do: CommandQueueBase;
    private handler: Exception->boolean;
    
    public constructor(try_do: CommandQueueBase; handler: Exception->boolean);
    begin
      self.try_do := try_do;
      self.handler := handler;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    try_do.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(pre_inv_handler);
      Result := try_do.InvokeToNil(g, l);
      var post_inv_handler := g.curr_err_handler;
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, |post_inv_handler|);
      
      Result.AddAction(c->
      try
        post_inv_handler.TryRemoveErrors(self.handler);
      except
        on e: Exception do post_inv_handler.AddErr(e);
      end);
      
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      try_do.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, handler);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueHandleDefaultRes<T> = sealed class(CommandQueue<T>)
    private try_do: CommandQueue<T>;
    private handler: Exception->boolean;
    private def: T;
    
    public constructor(try_do: CommandQueue<T>; handler: Exception->boolean; def: T);
    begin
      self.try_do := try_do;
      self.handler := handler;
      self.def := def;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    try_do.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(pre_inv_handler);
      Result := try_do.InvokeToNil(g, l);
      var post_inv_handler := g.curr_err_handler;
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, |post_inv_handler|);
      
      Result.AddAction(c->
      try
        post_inv_handler.TryRemoveErrors(self.handler);
      except
        on e: Exception do post_inv_handler.AddErr(e);
      end);
      
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(pre_inv_handler);
      var prev_qr := try_do.InvokeToAny(g, l);
      var post_inv_handler := g.curr_err_handler;
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, |post_inv_handler|);
      
      Result := prev_qr.TransformResult(qr_factory, g.c, true, (prev_res,c)->
      if not post_inv_handler.HadError then
        Result := prev_res else
      try
        post_inv_handler.TryRemoveErrors(self.handler);
        Result := self.def;
      except
        on e: Exception do post_inv_handler.AddErr(e);
      end);
      
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.def);
      sb += #10;
      
      try_do.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, handler);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueHandleReplaceRes<T> = sealed class(CommandQueue<T>)
    private try_do: CommandQueue<T>;
    private handler: List<Exception> -> T;
    
    public constructor(try_do: CommandQueue<T>; handler: List<Exception> -> T);
    begin
      self.try_do := try_do;
      self.handler := handler;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    try_do.InitBeforeInvoke(g, inited_hubs);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(pre_inv_handler);
      Result := try_do.InvokeToNil(g, l);
      var post_inv_handler := new CLTaskErrHandlerThief(g.curr_err_handler);
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, new CLTaskErrHandler[](post_inv_handler));
      
      Result.AddAction(c->
      if post_inv_handler.HadError then
      begin
        post_inv_handler.StealPrevErrors;
        try
          self.handler(post_inv_handler.get_local_err_lst);
        except
          on e: Exception do post_inv_handler.AddErr(e);
        end;
      end);
      
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBase(pre_inv_handler);
      var prev_qr := try_do.InvokeToAny(g, l);
      var post_inv_handler := new CLTaskErrHandlerThief(g.curr_err_handler);
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, new CLTaskErrHandler[](post_inv_handler));
      
      Result := prev_qr.TransformResult(qr_factory, g.c, true, (prev_res,c)->
      if not post_inv_handler.HadError then
        Result := prev_res else
      begin
        post_inv_handler.StealPrevErrors;
        try
          Result := self.handler(post_inv_handler.get_local_err_lst);
        except
          on e: Exception do post_inv_handler.AddErr(e);
        end;
      end);
      
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      try_do.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, handler);
      sb += #10;
      
    end;
    
  end;
  
function CommandQueueBase.HandleWithoutRes(handler: Exception->boolean) :=
new CommandQueueHandleWithoutRes(self, handler);

function CommandQueue<T>.HandleDefaultRes(handler: Exception->boolean; def: T): CommandQueue<T> :=
new CommandQueueHandleDefaultRes<T>(self, handler, def);

function CommandQueue<T>.HandleReplaceRes(handler: List<Exception> -> T) :=
new CommandQueueHandleReplaceRes<T>(self, handler);

{$endregion Handle}

{$endregion Queue converter's}

{$region KernelArg}

{$region Base}

type
  ISetableKernelArg = interface
    procedure SetArg(k: cl_kernel; ind: UInt32);
  end;
  KernelArg = abstract partial class
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; abstract;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); abstract;
    
  end;
  
{$endregion Base}

{$region Const}

{$region Base}

type
  ConstKernelArg = abstract class(KernelArg, ISetableKernelArg)
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    new QueueResVal<ISetableKernelArg>(new CLTaskLocalData, self);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); abstract;
    
  end;
  
{$endregion Base}

{$region Managed}

{$region Value}

type
  KernelArgValue<TRecord> = sealed class(ConstKernelArg)
  where TRecord: record;
    private val: ^TRecord := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<TRecord>));
    
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
    
    public constructor(val: TRecord) := self.val^ := val;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(new IntPtr(val));
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, new UIntPtr(Marshal.SizeOf&<TRecord>), pointer(self.val)) ); 
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.val^);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromValue<TRecord>(val: TRecord) := new KernelArgValue<TRecord>(val);

{$endregion Value}

{$region Array}

type
  KernelArgArray<TRecord, TArray> = sealed class(ConstKernelArg)
  where TRecord: record;
  where TArray: System.Array;
    private hnd: GCHandle;
    private ptr: IntPtr;
    private sz: UIntPtr;
    
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
    
    public constructor(a: TArray);
    begin
      self.hnd := GCHandle.Alloc(a, GCHandleType.Pinned);
      self.ptr := hnd.AddrOfPinnedObject;
      //TODO #2648
      self.sz := new UIntPtr(Marshal.SizeOf&<TRecord> * (a as System.Array).Length);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure Finalize; override :=
    if hnd.IsAllocated then hnd.Free;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, sz, ptr.ToPointer) ); 
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, hnd.Target as TArray);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromArray<TRecord>(a: array of TRecord) := new KernelArgArray<TRecord, array of TRecord>(a);
static function KernelArg.FromArray2<TRecord>(a: array[,] of TRecord) := new KernelArgArray<TRecord, array[,] of TRecord>(a);
static function KernelArg.FromArray3<TRecord>(a: array[,,] of TRecord) := new KernelArgArray<TRecord, array[,,] of TRecord>(a);

{$endregion Array}

{$region ArraySegment}

type
  KernelArgArraySegment<TRecord> = sealed class(ConstKernelArg)
  where TRecord: record;
    private hnd: GCHandle;
    private ptr: IntPtr;
    private sz: UIntPtr;
    
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
    
    public constructor(a: ArraySegment<TRecord>);
    begin
      self.hnd := GCHandle.Alloc(a.Array, GCHandleType.Pinned);
      self.ptr := hnd.AddrOfPinnedObject + a.Offset*Marshal.SizeOf&<TRecord>;
      self.sz := new UIntPtr(Marshal.SizeOf&<TRecord> * a.Count);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure Finalize; override :=
    if hnd.IsAllocated then hnd.Free;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, sz, ptr.ToPointer) ); 
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, new ArraySegment<TRecord>(
        hnd.Target as array of TRecord,
        (ptr.ToInt64-hnd.AddrOfPinnedObject.ToInt64) div Marshal.SizeOf&<TRecord>,
        sz.ToUInt64 div Marshal.SizeOf&<TRecord>
      ));
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromArraySegment<TRecord>(a: ArraySegment<TRecord>) := new KernelArgArraySegment<TRecord>(a);

{$endregion ArraySegment}

{$endregion Managed}

{$region Native}

{$region NativeMemoryArea}

type
  KernelArgData = sealed class(ConstKernelArg)
    private data: NativeMemoryArea;
    
    public constructor(data: NativeMemoryArea) := self.data := data;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, data.sz, data.ptr.ToPointer) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      sb.Append(data);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromData(data: NativeMemoryArea) := new KernelArgData(data);

static function KernelArg.operator implicit<TRecord>(ptr: ^TRecord): KernelArg;
begin
  BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
  Result := KernelArg.FromData(new NativeMemoryArea(
    new IntPtr(ptr), new UIntPtr(Marshal.SizeOf&<TRecord>)
  ));
end;

{$endregion NativeMemoryArea}

{$region NativeValue}

type
  KernelArgNativeValue<TRecord> = sealed class(ConstKernelArg)
  where TRecord: record;
    private val: NativeValue<TRecord>;
    
    public constructor(val: NativeValue<TRecord>) := self.val := val;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, new UIntPtr(Marshal.SizeOf&<TRecord>), self.val.Pointer) ); 
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, val);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromNativeValue<TRecord>(val: NativeValue<TRecord>): KernelArg; where TRecord: record;
begin
  Result := new KernelArgNativeValue<TRecord>(val);
end;

{$endregion NativeValue}

{$region NativeArray}

type
  KernelArgNativeArray<TRecord> = sealed class(ConstKernelArg)
  where TRecord: record;
    private a: NativeArray<TRecord>;
    
    public constructor(a: NativeArray<TRecord>) := self.a := a;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, a.area.sz, a.area.ptr.ToPointer) ); 
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, a);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromNativeArray<TRecord>(a: NativeArray<TRecord>): KernelArg; where TRecord: record;
begin
  Result := new KernelArgNativeArray<TRecord>(a);
end;

{$endregion NativeArray}

{$endregion Native}

{$region OpenCL}

{$region CLMemorySegment}

type
  KernelArgCLMemorySegment = sealed class(ConstKernelArg)
    private mem: CLMemorySegment;
    
    public constructor(mem: CLMemorySegment) := self.mem := mem;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
   OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), mem.ntv) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.mem);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromCLMemorySegment(mem: CLMemorySegment) := new KernelArgCLMemorySegment(mem);

{$endregion CLMemorySegment}

{$region CLValue}

type
  KernelArgCLValue<T> = sealed class(ConstKernelArg)
  where T: record;
    private val: CLValue<T>;
    
    public constructor(val: CLValue<T>) := self.val := val;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), val.ntv) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.val);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromCLValue<T>(val: CLValue<T>): KernelArg; where T: record;
begin
  Result := new KernelArgCLValue<T>(val);
end;

{$endregion CLValue}

{$region CLArray}

type
  KernelArgCLArray<T> = sealed class(ConstKernelArg)
  where T: record;
    private a: CLArray<T>;
    
    public constructor(a: CLArray<T>) := self.a := a;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), a.ntv) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.a);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromCLArray<T>(a: CLArray<T>): KernelArg; where T: record;
begin
  Result := new KernelArgCLArray<T>(a);
end;

{$endregion CLArray}

{$endregion OpenCL}

{$endregion Const}

{$region Invokeable}

{$region Base}

type
  InvokeableKernelArg = abstract class(KernelArg)
    protected static kqr_factory := new QueueResValFactory<ISetableKernelArg>;
  end;
  
{$endregion Base}

{$region Managed}

{$region Value}

type
  KernelArgPtrQr<TRecord> = sealed class(ConstKernelArg)
    public qr: QueueResPtr<TRecord>;
    
    public constructor(qr: QueueResPtr<TRecord>) := self.qr := qr;
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure SetArg(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, new UIntPtr(Marshal.SizeOf&<TRecord>), qr.res) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    raise new System.NotSupportedException;
    
  end;
  
  KernelArgValueCQ<TRecord> = sealed class(InvokeableKernelArg)
  where TRecord: record;
    public val_q: CommandQueue<TRecord>;
    
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
    
    public constructor(val_q: CommandQueue<TRecord>) := self.val_q := val_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override;
    begin
      var prev_qr := val_q.InvokeToPtr(g, l);
      Result := new QueueResVal<ISetableKernelArg>(
        prev_qr.TakeBaseOut,
        new KernelArgPtrQr<TRecord>(prev_qr)
      );
    end;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    val_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      val_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromValueCQ<TRecord>(val_q: CommandQueue<TRecord>) :=
new KernelArgValueCQ<TRecord>(val_q);

{$endregion Value}

{$region Array}

type
  KernelArgArrayCQ<TRecord, TArray> = sealed class(InvokeableKernelArg)
  where TRecord: record;
  where TArray: System.Array;
    public a_q: CommandQueue<TArray>;
    
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
    
    public constructor(a_q: CommandQueue<TArray>) := self.a_q := a_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    a_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (a,c)->new KernelArgArray<TRecord,TArray>(a) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    a_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      a_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromArrayCQ<TRecord>(a_q: CommandQueue<array of TRecord>) :=
new KernelArgArrayCQ<TRecord, array of TRecord>(a_q);
static function KernelArg.FromArray2CQ<TRecord>(a_q: CommandQueue<array[,] of TRecord>) :=
new KernelArgArrayCQ<TRecord, array[,] of TRecord>(a_q);
static function KernelArg.FromArray3CQ<TRecord>(a_q: CommandQueue<array[,,] of TRecord>) :=
new KernelArgArrayCQ<TRecord, array[,,] of TRecord>(a_q);

{$endregion Array}

{$region ArraySegment}

type
  KernelArgArraySegmentCQ<TRecord> = sealed class(InvokeableKernelArg)
  where TRecord: record;
    public a_q: CommandQueue<ArraySegment<TRecord>>;
    
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(TRecord), '%Err:Blittable:Source:KernelArg%');
    
    public constructor(a_q: CommandQueue<ArraySegment<TRecord>>) := self.a_q := a_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    a_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (a,c)->new KernelArgArraySegment<TRecord>(a) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    a_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      a_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromArraySegmentCQ<TRecord>(a_q: CommandQueue<ArraySegment<TRecord>>) :=
new KernelArgArraySegmentCQ<TRecord>(a_q);

{$endregion ArraySegment}

{$endregion Managed}

{$region Native}

{$region NativeMemoryArea}

type
  KernelArgDataCQ = sealed class(InvokeableKernelArg)
    public data_q: CommandQueue<NativeMemoryArea>;
    
    public constructor(data_q: CommandQueue<NativeMemoryArea>) := self.data_q := data_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    data_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (data,c)->new KernelArgData(data) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    data_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      data_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromDataCQ(data_q: CommandQueue<NativeMemoryArea>) :=
new KernelArgDataCQ(data_q);

{$endregion NativeMemoryArea}

{$region NativeValue}

type
  KernelArgNativeValueCQ<TRecord> = sealed class(InvokeableKernelArg)
  where TRecord: record;
    public val_q: CommandQueue<NativeValue<TRecord>>;
    
    public constructor(val_q: CommandQueue<NativeValue<TRecord>>) := self.val_q := val_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    val_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (val,c)->new KernelArgNativeValue<TRecord>(val) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    val_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      val_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromNativeValueCQ<TRecord>(val_q: CommandQueue<NativeValue<TRecord>>): KernelArg; where TRecord: record;
begin
  Result := new KernelArgNativeValueCQ<TRecord>(val_q);
end;

{$endregion NativeValue}

{$region NativeArray}

type
  KernelArgNativeArrayCQ<TRecord> = sealed class(InvokeableKernelArg)
  where TRecord: record;
    public a_q: CommandQueue<NativeArray<TRecord>>;
    
    public constructor(a_q: CommandQueue<NativeArray<TRecord>>) := self.a_q := a_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    a_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (a,c)->new KernelArgNativeArray<TRecord>(a) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    a_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      a_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromNativeArrayCQ<TRecord>(a_q: CommandQueue<NativeArray<TRecord>>): KernelArg; where TRecord: record;
begin
  Result := new KernelArgNativeArrayCQ<TRecord>(a_q);
end;

{$endregion NativeArray}

{$endregion Native}

{$region OpenCL}

{$region CLMemorySegment}

type
  KernelArgCLMemorySegmentCQ = sealed class(InvokeableKernelArg)
    public mem_q: CommandQueue<CLMemorySegment>;
    public constructor(mem_q: CommandQueue<CLMemorySegment>) := self.mem_q := mem_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    mem_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (mem,c)->new KernelArgCLMemorySegment(mem) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    mem_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      mem_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromCLMemorySegmentCQ(mem_q: CommandQueue<CLMemorySegment>) :=
new KernelArgCLMemorySegmentCQ(mem_q);

{$endregion CLMemorySegment}

{$region CLValue}

type
  KernelArgCLValueCQ<T> = sealed class(InvokeableKernelArg)
  where T: record;
    public val_q: CommandQueue<CLValue<T>>;
    public constructor(val_q: CommandQueue<CLValue<T>>) := self.val_q := val_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    val_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (val,c)->new KernelArgCLValue<T>(val) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    val_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      val_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromCLValueCQ<T>(val_q: CommandQueue<CLValue<T>>): KernelArg; where T: record;
begin
  Result := new KernelArgCLValueCQ<T>(val_q);
end;

{$endregion CLValue}

{$region CLArray}

type
  KernelArgCLArrayCQ<T> = sealed class(InvokeableKernelArg)
  where T: record;
    public a_q: CommandQueue<CLArray<T>>;
    public constructor(a_q: CommandQueue<CLArray<T>>) := self.a_q := a_q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<ISetableKernelArg>; override :=
    a_q.InvokeToAny(g, l).TransformResult(kqr_factory, g.c, true, (a,c)->new KernelArgCLArray<T>(a) as ISetableKernelArg);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    a_q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      a_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromCLArrayCQ<T>(a_q: CommandQueue<CLArray<T>>): KernelArg; where T: record;
begin Result := new KernelArgCLArrayCQ<T>(a_q); end;

{$endregion CLArray}

{$endregion OpenCL}

{$endregion Invokeable}

{$endregion KernelArg}

{$region GPUCommand}

{$region Base}

type
  GPUCommandObjInvoker<T> = CommandQueueInvoker<QueueResVal<T>>;
  
  GPUCommand<T> = abstract class
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); abstract;
    
    protected function InvokeObj  (o: T;                              g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; abstract;
    protected function InvokeQueue(o_invoke: GPUCommandObjInvoker<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; abstract;
    
    protected function DisplayName: string; virtual := CommandQueueBase.DisplayNameForType(self.GetType);
    protected static procedure ToStringWriteDelegate(sb: StringBuilder; d: System.Delegate) := CommandQueueBase.ToStringWriteDelegate(sb,d);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb.Append(#9, tabs);
      sb += DisplayName;
      self.ToStringImpl(sb, tabs+1, index, delayed);
    end;
    
  end;
  
  BasicGPUCommand<T> = abstract class(GPUCommand<T>)
    
    protected function DisplayName: string; override;
    begin
      Result := self.GetType.Name;
      Result := Result.Remove(Result.IndexOf('`'));
    end;
    
    public static function MakeQueue(q: CommandQueueBase): BasicGPUCommand<T>;
    
    public static function MakeBackgroundProc(p: T->()): BasicGPUCommand<T>;
    public static function MakeBackgroundProc(p: (T,Context)->()): BasicGPUCommand<T>;
    public static function MakeQuickProc(p: T->()): BasicGPUCommand<T>;
    public static function MakeQuickProc(p: (T,Context)->()): BasicGPUCommand<T>;
    
    public static function MakeWait(m: WaitMarker): BasicGPUCommand<T>;
    
  end;
  
{$endregion Base}

{$region Queue}

type
  QueueCommand<T> = sealed class(BasicGPUCommand<T>)
    public q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData) := q.InvokeToNil(g, l);
    
    protected function InvokeObj  (o: T;                              g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(g, l);
    protected function InvokeQueue(o_invoke: GPUCommandObjInvoker<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(g, l);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    q.InitBeforeInvoke(g, inited_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  QueueCommandFactory<TObj> = sealed class(ITypedCQConverter<BasicGPUCommand<TObj>>)
    
    public function ConvertNil(cq: CommandQueueNil): BasicGPUCommand<TObj> := new QueueCommand<TObj>(cq);
    public function Convert<T>(cq: CommandQueue<T>): BasicGPUCommand<TObj> :=
    if cq is ConstQueue<T> then nil else
    if cq is ParameterQueue<T> then nil else
    if cq is CastQueueBase<T>(var ccq) then
      ccq.SourceBase.ConvertTyped(self) else
      new QueueCommand<TObj>(cq);
    
  end;
  
static function BasicGPUCommand<T>.MakeQueue(q: CommandQueueBase) := q.ConvertTyped(new QueueCommandFactory<T>);

{$endregion Queue}

{$region Proc}

{$region Base}

type
  ProcCommandBase<T, TProc> = abstract class(BasicGPUCommand<T>)
  where TProc: Delegate;
    public p: TProc;
    
    public constructor(p: TProc) := self.p := p;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure ExecProc(o: T; c: Context); abstract;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringWriteDelegate(sb, p);
      sb += #10;
    end;
    
  end;
  
{$endregion Base}

type
  BackgroundProcCommandBase<T, TProc> = abstract class(ProcCommandBase<T, TProc>)
  where TProc: Delegate;
    
    protected function InvokeObj(o: T; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var prev_d := l.prev_delegate;
      var c := g.c;
      var err_handler := g.curr_err_handler;
      new QueueResNil(new CLTaskLocalData(
        UserEvent.StartBackgroundWork(l.prev_ev,
          ()->
          begin
            prev_d.Invoke(c);
            try
              ExecProc(o, c);
            except
              on e: Exception do err_handler.AddErr(e);
            end;
          end,
          g.cl_c{$ifdef EventDebug}, $'const body of {self.GetType}'{$endif}
        )
      ));
    end;
    
    protected function InvokeQueue(o_invoke: GPUCommandObjInvoker<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var o_qr := o_invoke(g, l);
      var c := g.c;
      var err_handler := g.curr_err_handler;
      Result := new QueueResNil(new CLTaskLocalData(
        UserEvent.StartBackgroundWork(o_qr.ResEv,
          ()->
          begin
            var o := o_qr.GetRes(c);
            try
              ExecProc(o, c);
            except
              on e: Exception do err_handler.AddErr(e);
            end;
          end,
          g.cl_c{$ifdef EventDebug}, $'queue body of {self.GetType}'{$endif}
        )
      ));
    end;
    
  end;
  
  BackgroundProcCommand<T> = sealed class(BackgroundProcCommandBase<T, T->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o);
    
  end;
  BackgroundProcCommandC<T> = sealed class(BackgroundProcCommandBase<T, (T,Context)->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o, c);
    
  end;
  
static function BasicGPUCommand<T>.MakeBackgroundProc(p: T->()) := new BackgroundProcCommand<T>(p);
static function BasicGPUCommand<T>.MakeBackgroundProc(p: (T,Context)->()) := new BackgroundProcCommandC<T>(p);

type
  QuickProcCommandBase<T, TProc> = abstract class(ProcCommandBase<T, TProc>)
  where TProc: Delegate;
    
    private function Invoke(prev_qr: QueueRes<T>; g: CLTaskGlobalData): QueueResNil;
    begin
      Result := new QueueResNil(prev_qr.TakeBaseOut);
      
      var d := QueueResActionUtils.HandlerWrap(g.curr_err_handler, ExecProc);
      if Result.ShouldInstaCallAction then
        d(prev_qr.GetResDirect, g.c) else
        Result.AddAction(c->d(prev_qr.GetResDirect, c));
      
    end;
    
    protected function InvokeObj  (o: T;                              g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(new QueueResVal<T>(l, o), g);
    protected function InvokeQueue(o_invoke: GPUCommandObjInvoker<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(o_invoke(g, l), g);
    
  end;
  
  QuickProcCommand<T> = sealed class(QuickProcCommandBase<T, T->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o);
    
  end;
  QuickProcCommandC<T> = sealed class(QuickProcCommandBase<T, (T,Context)->()>)
    
    protected procedure ExecProc(o: T; c: Context); override := p(o, c);
    
  end;
  
static function BasicGPUCommand<T>.MakeQuickProc(p: T->()) := new QuickProcCommand<T>(p);
static function BasicGPUCommand<T>.MakeQuickProc(p: (T,Context)->()) := new QuickProcCommandC<T>(p);

{$endregion Proc}

{$region Wait}

type
  WaitCommand<T> = sealed class(BasicGPUCommand<T>)
    public marker: WaitMarker;
    
    public constructor(marker: WaitMarker) := self.marker := marker;
    private constructor := raise new OpenCLABCInternalException;
    
    private function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData) :=
    new QueueResNil(new CLTaskLocalData( marker.MakeWaitEv(g,l) ));
    
    protected function InvokeObj  (o: T;                              g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(g, l);
    protected function InvokeQueue(o_invoke: GPUCommandObjInvoker<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(g, l);
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    marker.InitInnerHandles(g);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      marker.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function BasicGPUCommand<T>.MakeWait(m: WaitMarker) := new WaitCommand<T>(m);

{$endregion Wait}

{$endregion GPUCommand}

{$region GPUCommandContainer}

{$region Base}

type
  GPUCommandContainer<T> = abstract partial class
    private constructor := raise new OpenCLABCInternalException;
  end;
  GPUCommandContainerCore<T> = abstract class
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); abstract;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>): QueueResNil; abstract;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>): QueueResVal<T>; abstract;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb.Append(#9, tabs);
      
      var tn := self.GetType.Name;
      sb += tn.Remove(tn.IndexOf('`'));
      
      self.ToStringImpl(sb, tabs+1, index, delayed);
    end;
    
  end;
  
  GPUCommandContainer<T> = abstract partial class(CommandQueue<T>)
    protected core: GPUCommandContainerCore<T>;
    protected commands := new List<GPUCommand<T>>;
    // Not nil only when commands are nil
    private commands_in: GPUCommandContainer<T>;
    private old_command_count: integer;
    
    private procedure TakeCommandsBack;
    begin
      if commands_in=nil then exit;
      while commands_in.commands_in<>nil do
        commands_in := commands_in.commands_in;
      self.commands := new List<GPUCommand<T>>(old_command_count);
      for var i := 0 to old_command_count-1 do self.commands += commands_in.commands[i];
      commands_in := nil;
    end;
    
    public function Clone: GPUCommandContainer<T>; abstract;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override;
    begin
      core.InitBeforeInvoke(g, inited_hubs);
      TakeCommandsBack;
      foreach var comm in self.commands do comm.InitBeforeInvoke(g, inited_hubs);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override    := core.InvokeToNil(g, l, self.commands);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := core.InvokeToVal(g, l, self.commands);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override;
    begin
      Result := nil;
      raise new OpenCLABCInternalException($'Err:Invoke:InvalidToPtr');
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      core.ToString(sb, tabs, index, delayed);
      TakeCommandsBack;
      foreach var comm in commands do
        comm.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function AddCommand<TContainer, T>(cc: TContainer; comm: GPUCommand<T>): TContainer; where TContainer: GPUCommandContainer<T>;
begin
  cc.TakeCommandsBack;
  Result := TContainer(cc.Clone);
  cc.commands_in := Result;
  //TODO #????
  cc.old_command_count := (cc as GPUCommandContainer<T>).commands.Count;
  cc.commands := nil;
  Result.commands += comm;
end;

{$endregion Base}

{$region Core}

type
  CCCObj<T> = sealed class(GPUCommandContainerCore<T>)
    public o: T;
    
    public constructor(o: T) := self.o := o;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>; make_qr: (CLTaskLocalData, T)->TR): TR;
    begin
      var o := self.o;
      
      foreach var comm in commands do
        l := comm.InvokeObj(o, g, l).base;
      
      Result := make_qr(l, o);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>): QueueResNil; override    := Invoke(g, l, commands, (l,o)->new QueueResNil(l));
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>): QueueResVal<T>; override := Invoke(g, l, commands, (l,o)->new QueueResVal<T>(l,o));
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      CommandQueueBase.ToStringRuntimeValue(sb, self.o);
      sb += #10;
    end;
    
  end;
  
  CCCQueue<T> = sealed class(GPUCommandContainerCore<T>)
    public hub: MultiusableCommandQueueHub<T>;
    
    public constructor(q: CommandQueue<T>) := self.hub := new MultiusableCommandQueueHub<T>(q);
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override :=
    hub.q.InitBeforeInvoke(g, inited_hubs);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>; make_qr: (GPUCommandObjInvoker<T>,CLTaskGlobalData,CLTaskLocalData)->TR): TR;
    begin
      var invoke_plug: GPUCommandObjInvoker<T> := hub.MakeNode.InvokeToVal;
      
      foreach var comm in commands do
        l := comm.InvokeQueue(invoke_plug, g, l).base;
      
      Result := make_qr(invoke_plug, g, l);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>): QueueResNil;    override := Invoke(g, l, commands, (inv,g,l)->new QueueResNil(l));
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData; commands: List<GPUCommand<T>>): QueueResVal<T>; override := Invoke(g, l, commands, (inv,g,l)->inv(g,l));
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      hub.q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  GPUCommandContainer<T> = abstract partial class
    
    protected constructor(o: T) :=
    self.core := new CCCObj<T>(o);
    
    protected constructor(q: CommandQueue<T>) :=
    self.core := new CCCQueue<T>(q);
    
    protected constructor(ccq: GPUCommandContainer<T>);
    begin
      self.core := ccq.core;
      self.commands := ccq.commands;
    end;
    
  end;
  
{$endregion Core}

{$region Kernel}

type
  KernelCCQ = sealed partial class(GPUCommandContainer<Kernel>)
    
    private constructor(ccq: GPUCommandContainer<Kernel>) := inherited;
    public function Clone: GPUCommandContainer<Kernel>; override := new KernelCCQ(self);
    
  end;
  
{%ContainerCommon\Kernel\Implementation!ContainerCommon.pas%}

{$endregion Kernel}

{$region CLMemorySegment}

type
  CLMemorySegmentCCQ = sealed partial class(GPUCommandContainer<CLMemorySegment>)
    
    private constructor(ccq: GPUCommandContainer<CLMemorySegment>) := inherited;
    public function Clone: GPUCommandContainer<CLMemorySegment>; override := new CLMemorySegmentCCQ(self);
    
  end;
  
static function KernelArg.operator implicit(mem_q: CLMemorySegmentCCQ): KernelArg := FromCLMemorySegmentCQ(mem_q);

{%ContainerCommon\CLMemorySegment\Implementation!ContainerCommon.pas%}

{$endregion CLMemorySegment}

{$region CLValue}

type
  CLValueCCQ<T> = sealed partial class(GPUCommandContainer<CLValue<T>>)
    
    private constructor(ccq: GPUCommandContainer<CLValue<T>>) := inherited;
    public function Clone: GPUCommandContainer<CLValue<T>>; override := new CLValueCCQ<T>(self);
    
  end;
  
static function KernelArg.operator implicit<T>(val_q: CLValueCCQ<T>): KernelArg; where T: record;
//TODO #2550
begin Result := FromCLValueCQ(val_q as object as GPUCommandContainer<CLValue<T>>); end;

{%ContainerCommon\CLValue\Implementation!ContainerCommon.pas%}

{$endregion CLArray}

{$region CLArray}

type
  CLArrayCCQ<T> = sealed partial class(GPUCommandContainer<CLArray<T>>)
    
    private constructor(ccq: GPUCommandContainer<CLArray<T>>) := inherited;
    public function Clone: GPUCommandContainer<CLArray<T>>; override := new CLArrayCCQ<T>(self);
    
  end;
  
static function KernelArg.operator implicit<T>(a_q: CLArrayCCQ<T>): KernelArg; where T: record;
//TODO #2550
begin Result := FromCLArrayCQ(a_q as object as GPUCommandContainer<CLArray<T>>); end;

{%ContainerCommon\CLArray\Implementation!ContainerCommon.pas%}

{$endregion CLArray}

{$endregion GPUCommandContainer}

{$region Enqueueable's}

{$region Core}

type
  EnqEvLst = sealed class
    private evs: array of EventList;
    private c1 := 0;
    private c2 := 0;
    {$ifdef DEBUG}
    private skipped := 0;
    {$endif DEBUG}
    
    public constructor(cap: integer) :=
    evs := new EventList[cap];
    private constructor := raise new OpenCLABCInternalException;
    
    public property Capacity: integer read evs.Length;
    
    public procedure AddL1(ev: EventList);
    begin
      {$ifdef DEBUG}
      if c1+c2+skipped = evs.Length then raise new OpenCLABCInternalException($'Not enough EnqEv capacity');
      {$endif DEBUG}
      if ev.count=0 then
        {$ifdef DEBUG}skipped += 1{$endif} else
      begin
        evs[c1] := ev;
        c1 += 1;
      end;
    end;
    public procedure AddL2(ev: EventList);
    begin
      {$ifdef DEBUG}
      if c1+c2+skipped = evs.Length then raise new OpenCLABCInternalException($'Not enough EnqEv capacity');
      {$endif DEBUG}
      if ev.count=0 then
        {$ifdef DEBUG}skipped += 1{$endif} else
      begin
        c2 += 1;
        evs[evs.Length-c2] := ev;
      end;
    end;
    
    private procedure CheckDone;
    begin
      {$ifdef DEBUG}
      if c1+c2+skipped <> evs.Length then raise new OpenCLABCInternalException($'Too much EnqEv capacity: {c1+c2+skipped}/{evs.Length} used');
      {$endif DEBUG}
    end;
    
    public function MakeLists: ValueTuple<EventList, EventList>;
    begin
      CheckDone;
      Result := ValueTuple.Create(
        EventList.Combine(new ArraySegment<EventList>(evs,0,c1)),
        EventList.Combine(new ArraySegment<EventList>(evs,evs.Length-c2,c2))
      );
    end;
    public function CombineAll: EventList;
    begin
      CheckDone;
      Result := EventList.Combine(evs);
    end;
    
  end;
  
  DirectEnqRes = ValueTuple<cl_event, QueueResAction>;
  EnqRes = ValueTuple<EventList, QueueResAction>;
  EnqueueableEnqFunc<TInvData> = function(inv_data: TInvData; c: Context; cq: cl_command_queue; ev_l2: EventList): DirectEnqRes;
  
  IEnqueueable<TInvData> = interface
    
    function EnqEvCapacity: integer;
    
    function InvokeParams(g: CLTaskGlobalData; enq_evs: EnqEvLst): EnqueueableEnqFunc<TInvData>;
    
  end;
  
  EnqueueableCore = static class
    
    private static function MakeEvList(exp_size: integer; start_ev: EventList): List<EventList>;
    begin
      var need_start_ev := start_ev.count<>0;
      Result := new List<EventList>(exp_size + integer(need_start_ev));
      if need_start_ev then Result += start_ev;
    end;
    
    private static function ExecuteEnqFunc<TInvData>(
      inv_data: TInvData; c: Context; cq: cl_command_queue; ev_l2: EventList;
      enq_f: EnqueueableEnqFunc<TInvData>; err_handler: CLTaskErrHandler
      {$ifdef EventDebug}; q: object{$endif}): EnqRes;
    begin
      Result := new EnqRes(ev_l2, nil);
      try
        var (enq_ev, act) := enq_f(inv_data, c, cq, ev_l2);
        {$ifdef EventDebug}
        EventDebug.RegisterEventRetain(enq_ev, $'Enq by {q.GetType}, waiting on [{ev_l2.evs?.JoinToString}]');
        {$endif EventDebug}
        // 1. ev_l2 can be released only after executing dependant command
        // 2. If event in ev_l2 would receive error, enq_ev would not give descriptive error
        Result := new EnqRes(ev_l2+enq_ev, act);
      except
        on e: Exception do err_handler.AddErr(e);
      end;
    end;
    
    public static function Invoke<TEnq, TInvData>(q: TEnq; inv_data: TInvData; g: CLTaskGlobalData; start_ev: EventList; start_ev_in_l1: boolean): EnqRes; where TEnq: IEnqueueable<TInvData>;
    begin
      var enq_evs := new EnqEvLst(q.EnqEvCapacity+1);
      if start_ev_in_l1 then
        enq_evs.AddL1(start_ev) else
        enq_evs.AddL2(start_ev);
      
      var pre_params_handler := g.curr_err_handler;
      var enq_f := q.InvokeParams(g, enq_evs);
      // After InvokeParams, because parameters
      // should not care about prev events and errors
      if pre_params_handler.HadError then
      begin
        Result := new EnqRes(enq_evs.CombineAll, nil);
        exit;
      end;
      
      var (ev_l1, ev_l2) := enq_evs.MakeLists;
      var need_async_inv := ev_l1.count<>0;
      
      var post_params_handler := g.curr_err_handler;
      // When inv is async, post_params_handler
      // could be appened later, until ev_l2 is completed
      if need_async_inv ? post_params_handler.HadErrorWithoutCache : post_params_handler.HadError then
      begin
        Result := new EnqRes(ev_l2, nil);
        exit;
      end;
      
      // When inv is async, cq needs to be secured for thread safety
      // Otherwise, next command can be written before current one
      var cq := g.GetCQ(need_async_inv);
      {$ifdef QueueDebug}
      QueueDebug.Add(cq, q.GetType.ToString);
      {$endif QueueDebug}
      
      if not need_async_inv then
        Result := ExecuteEnqFunc(inv_data, g.c, cq, ev_l2, enq_f, post_params_handler{$ifdef EventDebug}, q{$endif}) else
      begin
        var res_ev := new UserEvent(g.cl_c
          {$ifdef EventDebug}, $'{q.GetType}, temp for nested AttachCallback: [{ev_l1.evs.JoinToString}], then [{ev_l2.evs?.JoinToString}]'{$endif}
        );
        
        ev_l1.MultiAttachCallback(()->
        begin
          var (enq_ev, enq_act) := ExecuteEnqFunc(inv_data, g.c, cq, ev_l2, enq_f, post_params_handler{$ifdef EventDebug}, q{$endif});
          OpenCLABCInternalException.RaiseIfError( cl.Flush(cq) );
          enq_ev.MultiAttachCallback(()->
          begin
            if enq_act<>nil then enq_act(g.c);
            g.ReturnCQ(cq);
            res_ev.SetComplete;
          end{$ifdef EventDebug}, $'propagating Enq ev of {q.GetType} to res_ev: {res_ev.uev}'{$endif});
        end{$ifdef EventDebug}, $'calling async Enq of {q.GetType}'{$endif});
        
        Result := new EnqRes(res_ev, nil);
      end;
      
    end;
    
  end;
  
{$endregion Core}

{$region GPUCommand}

type
  EnqueueableGPUCommandInvData<T> = record
    qr: QueueRes<T>;
  end;
  EnqueueableGPUCommand<T> = abstract class(GPUCommand<T>, IEnqueueable<EnqueueableGPUCommandInvData<T>>)
    
    public function EnqEvCapacity: integer; abstract;
    
    protected function InvokeParamsImpl(g: CLTaskGlobalData; enq_evs: EnqEvLst): (T, cl_command_queue, EventList)->DirectEnqRes; abstract;
    public function InvokeParams(g: CLTaskGlobalData; enq_evs: EnqEvLst): EnqueueableEnqFunc<EnqueueableGPUCommandInvData<T>>;
    begin
      var enq_f := InvokeParamsImpl(g, enq_evs);
      Result := (data, c, lcq, ev)->enq_f(data.qr.GetRes(c), lcq, ev);
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke(g: CLTaskGlobalData; prev_qr: QueueRes<T>; start_ev: EventList; start_ev_in_l1: boolean): QueueResNil;
    begin
      var inv_data: EnqueueableGPUCommandInvData<T>;
      inv_data.qr  := prev_qr;
      
      var (enq_ev, enq_act) := EnqueueableCore.Invoke(self, inv_data, g, start_ev, start_ev_in_l1);
      var res := new QueueResNil(new CLTaskLocalData(enq_ev));
      if enq_act<>nil then res.AddAction(enq_act);
      
      Result := res;
    end;
    
    protected function InvokeObj(o: T; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    Invoke(g, new QueueResVal<T>(new CLTaskLocalData, o), l.prev_ev, false);
    
    protected function InvokeQueue(o_invoke: GPUCommandObjInvoker<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var prev_qr := o_invoke(g, l);
      Result := Invoke(g, prev_qr, prev_qr.ResEv, not prev_qr.IsConst);
    end;
    
  end;
  
{$endregion GPUCommand}

{$region GetCommand}

type
  EnqueueableGetCommandInvData<TObj, TRes> = record
    prev_qr: QueueRes<TObj>;
    res_qr: QueueRes<TRes>;
  end;
  EnqueueableGetCommand<TObj, TRes> = abstract class(CommandQueue<TRes>, IEnqueueable<EnqueueableGetCommandInvData<TObj, TRes>>)
    protected prev_commands: GPUCommandContainer<TObj>;
    
    public constructor(prev_commands: GPUCommandContainer<TObj>) :=
    self.prev_commands := prev_commands;
    
    public function EnqEvCapacity: integer; abstract;
    
    protected function InvokeParamsImpl(g: CLTaskGlobalData; enq_evs: EnqEvLst): (TObj, cl_command_queue, EventList, QueueRes<TRes>)->DirectEnqRes; abstract;
    public function InvokeParams(g: CLTaskGlobalData; enq_evs: EnqEvLst): EnqueueableEnqFunc<EnqueueableGetCommandInvData<TObj, TRes>>;
    begin
      var enq_f := InvokeParamsImpl(g, enq_evs);
      Result := (data, c, lcq, ev)->enq_f(data.prev_qr.GetRes(c), lcq, ev, data.res_qr);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := new QueueResNil(l);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: QueueRes<TRes>;
    begin
      Result := qr_factory.MakeDelayed(qr->
      begin
        var prev_qr := prev_commands.InvokeToVal(g, l);
        
        var inv_data: EnqueueableGetCommandInvData<TObj, TRes>;
        inv_data.prev_qr  := prev_qr;
        inv_data.res_qr   := qr;
        
        var (enq_ev, enq_act) := EnqueueableCore.Invoke(self, inv_data, g, prev_qr.ResEv, not prev_qr.IsConst);
        Result := new CLTaskLocalData(enq_ev);
        if enq_act<>nil then Result.prev_delegate.AddAction(enq_act);
      end);
    end;
    
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
  EnqueueableGetPtrCommand<TObj, TRes> = abstract class(EnqueueableGetCommand<TObj,TRes>)
    
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<TRes>; override;
    begin
      Result := nil;
      raise new OpenCLABCInternalException($'Err:Invoke:InvalidToVal');
    end;
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := inherited InvokeToPtr(g, l);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<TRes>; override := InvokeToPtr(g,l);
    
  end;
  
{$endregion GetCommand}

{$region Kernel}

{$region Implicit}

{%ContainerMethods\Kernel\Implicit.Implementation!ContainerMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\Kernel\Explicit.Implementation!ContainerMethods.pas%}

{$endregion Explicit}

{$endregion Kernel}

{$region CLMemorySegment}

{$region Implicit}

{%ContainerMethods\CLMemorySegment\Implicit.Implementation!ContainerMethods.pas%}

{%ContainerMethods\CLMemorySegment.Get\Implicit.Implementation!ContainerGetMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLMemorySegment\Explicit.Implementation!ContainerMethods.pas%}

{%ContainerMethods\CLMemorySegment.Get\Explicit.Implementation!ContainerGetMethods.pas%}

{$endregion Explicit}

{$endregion CLMemorySegment}

{$region CLValue}

{$region Implicit}

{%ContainerMethods\CLValue\Implicit.Implementation!ContainerMethods.pas%}

{%ContainerMethods\CLValue.Get\Implicit.Implementation!ContainerGetMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLValue\Explicit.Implementation!ContainerMethods.pas%}

{%ContainerMethods\CLValue.Get\Explicit.Implementation!ContainerGetMethods.pas%}

{$endregion Explicit}

{$endregion CLValue}

{$region CLArray}

{$region Implicit}

{%ContainerMethods\CLArray\Implicit.Implementation!ContainerMethods.pas%}

{%ContainerMethods\CLArray.Get\Implicit.Implementation!ContainerGetMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLArray\Explicit.Implementation!ContainerMethods.pas%}

{%ContainerMethods\CLArray.Get\Explicit.Implementation!ContainerGetMethods.pas%}

{$endregion Explicit}

{$endregion CLArray}

{$endregion Enqueueable's}

{$region Global subprograms}

{$region CQ}

function CQ<T>(o: T) := CommandQueue&<T>(o);

{$endregion CQ}

{$region HFQ/HPQ}

{$region Common}

type
  CommandQueueHostCommon<TDelegate> = record
  where TDelegate: Delegate;
    private d: TDelegate;
    
    public procedure ToString(sb: StringBuilder);
    begin
      sb += ': ';
      CommandQueueBase.ToStringWriteDelegate(sb, d);
      sb += #10;
    end;
    
  end;
  
{$endregion Common}

{$region Backgound}

{$region Func}

type
  CommandQueueHostBackgoundFuncBase<T, TFunc> = abstract class(CommandQueue<T>)
  where TFunc: Delegate;
    private data: CommandQueueHostCommon<TFunc>;
    
    public constructor(f: TFunc) := data.d := f;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    protected function ExecFunc(c: Context): T; abstract;
    
    private function MakeNilBody    (prev_d: QueueResComplDelegateData; c: Context; err_handler: CLTaskErrHandler; own_qr: QueueResNil): Action := ()->
    begin
      prev_d.Invoke(c);
      if err_handler.HadError then exit;
      try
        ExecFunc(c);
      except
        on e: Exception do err_handler.AddErr(e);
      end;
    end;
    private function MakeResBody<TR>(prev_d: QueueResComplDelegateData; c: Context; err_handler: CLTaskErrHandler; own_qr: TR): Action; where TR: QueueRes<T>;
    begin
      Result := ()->
      begin
        prev_d.Invoke(c);
        if err_handler.HadError then exit;
        var res: T;
        try
          res := ExecFunc(c);
        except
          on e: Exception do err_handler.AddErr(e);
        end;
        own_qr.SetRes(res);
      end;
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResBaseFactory<TR>; make_body: (QueueResComplDelegateData,Context,CLTaskErrHandler,TR)->Action): TR; where TR: IQueueRes;
    begin
      Result := qr_factory.MakeDelayed(qr->new CLTaskLocalData(
        UserEvent.StartBackgroundWork(l.prev_ev,
          make_body(l.prev_delegate, g.c, g.curr_err_handler, qr),
          g.cl_c{$ifdef EventDebug}, $'body of {self.GetType}'{$endif}
        )
      ));
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := Invoke(g, l, qr_nil_factory, MakeNilBody);
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory, MakeResBody&<QueueResVal<T>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory, MakeResBody&<QueueResPtr<T>>);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := data.ToString(sb);
    
  end;
  
  CommandQueueHostBackgoundFunc<T> = sealed class(CommandQueueHostBackgoundFuncBase<T, ()->T>)
    
    protected function ExecFunc(c: Context): T; override := data.d();
    
  end;
  CommandQueueHostBackgoundFuncC<T> = sealed class(CommandQueueHostBackgoundFuncBase<T, Context->T>)
    
    protected function ExecFunc(c: Context): T; override := data.d(c);
    
  end;
  
function HFQ<T>(f: ()->T) :=
new CommandQueueHostBackgoundFunc<T>(f);
function HFQ<T>(f: Context->T) :=
new CommandQueueHostBackgoundFuncC<T>(f);

{$endregion Func}

{$region Proc}

type
  CommandQueueHostBackgoundProcBase<TProc> = abstract class(CommandQueueNil)
  where TProc: Delegate;
    private data: CommandQueueHostCommon<TProc>;
    
    public constructor(p: TProc) := data.d := p;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    protected procedure ExecProc(c: Context); abstract;
    private function MakeBody(prev_d: QueueResComplDelegateData; err_handler: CLTaskErrHandler; c: Context): Action := ()->
    begin
      prev_d.Invoke(c);
      if err_handler.HadError then exit;
      try
        ExecProc(c);
      except
        on e: Exception do err_handler.AddErr(e);
      end;
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    new QueueResNil(new CLTaskLocalData(UserEvent.StartBackgroundWork(
      l.prev_ev, MakeBody(l.prev_delegate, g.curr_err_handler, g.c),
      g.cl_c{$ifdef EventDebug}, $'body of {self.GetType}'{$endif}
    )));
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := data.ToString(sb);
    
  end;
  
  CommandQueueHostBackgoundProc = sealed class(CommandQueueHostBackgoundProcBase<()->()>)
    
    protected procedure ExecProc(c: Context); override := data.d();
    
  end;
  CommandQueueHostBackgoundProcC = sealed class(CommandQueueHostBackgoundProcBase<Context->()>)
    
    protected procedure ExecProc(c: Context); override := data.d(c);
    
  end;
  
function HPQ(p: ()->()) :=
new CommandQueueHostBackgoundProc(p);
function HPQ(p: Context->()) :=
new CommandQueueHostBackgoundProcC(p);

{$endregion Proc}

{$endregion Backgound}

{$region Quick}

{$region Func}

type
  CommandQueueHostQuickFuncBase<T, TFunc> = abstract class(CommandQueue<T>)
  where TFunc: Delegate;
    private data: CommandQueueHostCommon<TFunc>;
    
    public constructor(f: TFunc) := data.d := f;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    protected function ExecFunc(c: Context): T; abstract;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      Result := new QueueResNil(l);
      
      var d := QueueResActionUtils.HandlerWrapStrip(g.curr_err_handler, ExecFunc);
      if l.ShouldInstaCallAction then
        d(g.c) else
        Result.AddAction(d);
      
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      
      var d := QueueResActionUtils.HandlerWrap(g.curr_err_handler, ExecFunc);
      if l.ShouldInstaCallAction then
        Result := qr_factory.MakeConst(l, d(g.c)) else
      begin
        Result := qr_factory.MakeDelayed(l);
        Result.AddResSetter(d);
      end;
      
    end;
    protected function InvokeToVal(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResVal<T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := data.ToString(sb);
    
  end;
  
  CommandQueueHostQuickFunc<T> = sealed class(CommandQueueHostQuickFuncBase<T, ()->T>)
    
    protected function ExecFunc(c: Context): T; override := data.d();
    
  end;
  CommandQueueHostQuickFuncC<T> = sealed class(CommandQueueHostQuickFuncBase<T, Context->T>)
    
    protected function ExecFunc(c: Context): T; override := data.d(c);
    
  end;
  
function HFQQ<T>(f: ()->T) :=
new CommandQueueHostQuickFunc<T>(f);
function HFQQ<T>(f: Context->T) :=
new CommandQueueHostQuickFuncC<T>(f);

{$endregion Func}

{$region Proc}

type
  CommandQueueHostQuickProcBase<TProc> = abstract class(CommandQueueNil)
  where TProc: Delegate;
    private data: CommandQueueHostCommon<TProc>;
    
    public constructor(p: TProc) := data.d := p;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueueHub>); override := exit;
    
    protected procedure ExecProc(c: Context); abstract;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      Result := new QueueResNil(l);
      
      var d := QueueResActionUtils.HandlerWrap(g.curr_err_handler, ExecProc);
      if l.ShouldInstaCallAction then
        d(g.c) else
        Result.AddAction(d);
      
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := data.ToString(sb);
    
  end;
  
  CommandQueueHostQuickProc = sealed class(CommandQueueHostQuickProcBase<()->()>)
    
    protected procedure ExecProc(c: Context); override := data.d();
    
  end;
  CommandQueueHostQuickProcC = sealed class(CommandQueueHostQuickProcBase<Context->()>)
    
    protected procedure ExecProc(c: Context); override := data.d(c);
    
  end;
  
function HPQQ(p: ()->()) :=
new CommandQueueHostQuickProc(p);
function HPQQ(p: Context->()) :=
new CommandQueueHostQuickProcC(p);

{$endregion Proc}

{$endregion Quick}

{$endregion HFQ/HPQ}

{$region CombineQueue's}

{%CombineQueues\Implementation!CombineQueues.pas%}

{$endregion CombineQueue's}

{$endregion Global subprograms}

initialization
finalization
  
  {$ifdef EventDebug}
  EventDebug.FinallyReport;
  {$endif EventDebug}
  
  {$ifdef QueueDebug}
  QueueDebug.FinallyReport;
  {$endif QueueDebug}
  
  {$ifdef WaitDebug}
  foreach var whd: WaitHandlerDirect in WaitDebug.WaitActions.Keys.OfType&<WaitHandlerDirect> do
    if whd.reserved<>0 then
      raise new OpenCLABCInternalException($'WaitHandler.reserved in finalization was <>0');
  WaitDebug.FinallyReport;
  {$endif WaitDebug}
  
end.