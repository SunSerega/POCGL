
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

{$region ToDo}

//===================================
// Обязательно сделать до следующей стабильной версии:

//===================================
// Запланированное:

//ToDo q*4 - Повторение очереди 4 раза
// - Всегда можно использовать Combine(ArrFill(4,q))
// - Но тогда внутри будет хранится массив - это лишнее, если все очереди одинаковые

//ToDo Порядок Wait очередей в Wait группах
// - Проверить сочетание с каждой другой фичей

//ToDo Перепродумать MemorySubSegment, в случае перевыделения основного буфера - он плохо себя ведёт...

//ToDo boolean в CLArray<T>
// - Его пытается маршлить как BOOL из C++, который имеет размер 4 байта
// - Проверить происходит ли собственно конверция
//ToDo CLBoolean?
// - boolean запретить не только в CLArray - во всех TRecord
//ToDo С char то же самое
//ToDO А для DateTime и размер посчитать не даёт

//ToDo Преобразование array of T => KernelArg, используя CL_MEM_USE_HOST_PTR
// - #2478

//ToDo HFQ(()->S) не работает как ссылка на S:MemorySegment?

//ToDo Использовать cl.EnqueueMapBuffer
// - В виде .AddMap((MappedArray,Context)->())

//ToDo Пройтись по интерфейсу, порасставлять кидание исключений
//ToDo Проверки и кидания исключений перед всеми cl.*, чтобы выводить норм сообщения об ошибках
// - В том числе проверки с помощью BlittableHelper

//ToDo Синхронные (с припиской Fast, а может Quick) варианты всего работающего по принципу HostQueue
//
//ToDo И асинхронные умнее запускать - помнить значение, указывающее можно ли выполнить их синхронно
// - Может даже можно синхронно выполнить "HPQ(...)+HPQ(...)", в некоторых случаях?
//ToDo Enqueueabl-ы вызывают .Invoke для первого параметра и .InvokeNewQ для остальных
// - А что если все параметры кроме последнего - константы?
// - Надо как то умнее это обрабатывать
//ToDo И сделать наконец нормальный класс-контейнер состояния очереди, параметрами всё не передашь

//ToDo .Cast.ThenWaitMarker.Cast не оптимизируется - а можно было бы и оптимизировать
// - Для этого надо создавать ещё один псевдо-маркер, но давать ему тот же маркер
// - Но тогда маркер будет активироваться даже если первое преобразование неправильное...

//ToDo Проверять ".IsReadOnly" перед запасным копированием коллекций

//ToDo В методах вроде .AddWriteArray1 приходится добавлять &<>

//ToDo Подумать как об этом можно написать в справке (или не в справке):
// - ReadValue отсутствует
// --- В объяснении KernelArg из указателя всё уже сказано
// --- Надо только как то объединить, чтоб текст был не только про KernelArg...
// - FillArray отсутствует
// --- Проблема в том, что нет блокирующего варианта cl.FillArray
// --- Вообще в теории можно написать отдельную мелкую неуправляемую .dll и $resource её
// --- Но это жесть сколько усложнений ради 1 метода...

//ToDo А что если вещи, которые могут привести к утечкам памяти при ThreadAbortException (как конструктор контекста) сувать в finally пустого try?
// - Вообще, поидее, должен быть более красивый способ добиться того же... Что то с контрактами?
// - Обязательно сравнить скорость, перед тем как применять...

//ToDo Можно же сохранять неуправляемые очереди в список внутри CLTask, и затем использовать несколько раз
// - И почему я раньше об этом не подумал...

//ToDo Заполнение Platform.All сейчас вылетит на компе с 0 платформ...
// - Сразу не забыть исправить описание

//ToDo Всё же стоит добавить .ThenUse - аналог .ThenConvert, не изменяющий значение, а только использующий

//ToDo IWaitQueue.CancelWait
//ToDo WaitAny(aborter, WaitAll(...));
// - Что случится с WaitAll если aborter будет первым?
// - Очереди переданные в Wait - вообще не запускаются так
// - Поэтому я и думал про что то типа CancelWait
// - А вообще лучше разрешить выполнять Wait внутри другого Wait
// - И заодно проверить чтобы Abort работало на Wait-ы
// - А вообще всё не то - это костыли
// - Надо специально разрешить передавать какой то маркер аборта
// - И только в WaitAll, другим Wait-ам это не нужно
// - Или можно забыть про всё это и сделать+использовать AbortQueue чтоб убивать и Wait-ы, и всё остальное

//ToDo Создание SubDevice из cl_device_id

//ToDo Очередь-обработчик ошибок
// - .HandleExceptions
// - Сделать легко, надо только вставить свой промежуточный CLTaskBase
// - Единственное - для Wait очереди надо хранить так же оригинальный CLTaskBase
//ToDo И какой то аналог try-finally
// - .ThenFinally ?
//ToDo Раздел справки про обработку ошибок
// - Написать что аналог try-finally стоит использовать на Wait-маркерах для потоко-безопастности
//
//ToDo Когда будут очереди-обработчики - удалить ивенты CLTask-ов. Они, по сути, ограниченная версия.
// - И использование их тут изнутри - в целом говнокод...

//ToDo .Cycle(integer)
//ToDo .Cycle // бесконечность циклов
//ToDo .CycleWhile(***->boolean)
// - Возможность передать свой обработчик ошибок как Exception->Exception
//ToDo В продолжение Cycle: Однако всё ещё остаётся проблема - как сделать ветвление?
// - И если уже делать - стоит сделать и метод CQ.ThenIf(res->boolean; if_true, if_false: CQ)
//ToDo И ещё - AbortQueue, который, по сути, может использоваться как exit, continue или break, если с обработчиками ошибок
// - Или может метод MarkerQueue.Abort?

//ToDo Интегрировать профайлинг очередей

//ToDo Может всё же сделать защиту от дурака для "q.AddQueue(q)"?
// - И в справке тогда убрать параграф...

//===================================
// Сделать когда-нибуть:

//ToDo Пройтись по всем функциям OpenCL, посмотреть функционал каких не доступен из OpenCLABC
// - clGetKernelWorkGroupInfo - свойства кернела на определённом устройстве

//===================================

{$endregion ToDo}

{$region Bugs}

//ToDo Issue компилятора:
//ToDo https://github.com/pascalabcnet/pascalabcnet/issues/{id}
// - #2221
// - #2431
// - #2510

//ToDo Баги NVidia
//ToDo https://developer.nvidia.com/nvidia_bug/{id}
// - NV#3035203

{$endregion}

{$region Debug}{$ifdef DEBUG}

{ $define EventDebug} // Регистрация всех cl.RetainEvent и cl.ReleaseEvent

{$endif DEBUG}{$endregion Debug}

interface

uses System;
uses System.Threading;
uses System.Runtime.InteropServices;
uses System.Collections.ObjectModel;

uses OpenCL;

type
  
  {$region Re-definition's}
  
  OpenCLException         = OpenCL.OpenCLException;
  
  DeviceType              = OpenCL.DeviceType;
  DeviceAffinityDomain    = OpenCL.DeviceAffinityDomain;
  
  {$endregion Re-definition's}
  
  {$region Properties}
  
  {%WrapperProperties\Interface!WrapPropGen.pas%}
  
  {$endregion Properties}
  
  {$region Wrappers}
  // Для параметров команд
  CommandQueue<T> = abstract partial class end;
  KernelArg = abstract partial class end;
  
  {$region Platform}
  
  Platform = partial class
    private ntv: cl_platform_id;
    
    public constructor(ntv: cl_platform_id) := self.ntv := ntv;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    private static _all: IList<Platform>;
    private static function GetAll: IList<Platform>;
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
    public static property All: IList<Platform> read GetAll;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}]';
    
  end;
  
  {$endregion Platform}
  
  {$region Device}
  
  Device = partial class
    private ntv: cl_device_id;
    
    public constructor(ntv: cl_device_id) := self.ntv := ntv;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    private function GetBasePlatform: Platform;
    begin
      var pl: cl_platform_id;
      cl.GetDeviceInfo(self.ntv, DeviceInfo.DEVICE_PLATFORM, new UIntPtr(sizeof(cl_platform_id)), pl, IntPtr.Zero).RaiseIfError;
      Result := new Platform(pl);
    end;
    public property BasePlatform: Platform read GetBasePlatform;
    
    public static function GetAllFor(pl: Platform; t: DeviceType): array of Device;
    begin
      
      var c: UInt32;
      var ec := cl.GetDeviceIDs(pl.ntv, t, 0, IntPtr.Zero, c);
      if ec=ErrorCode.DEVICE_NOT_FOUND then exit;
      ec.RaiseIfError;
      
      var all := new cl_device_id[c];
      cl.GetDeviceIDs(pl.ntv, t, c, all[0], IntPtr.Zero).RaiseIfError;
      
      Result := all.ConvertAll(dvc->new Device(dvc));
    end;
    public static function GetAllFor(pl: Platform) := GetAllFor(pl, DeviceType.DEVICE_TYPE_GPU);
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}]';
    
  end;
  
  {$endregion Device}
  
  {$region SubDevice}
  
  SubDevice = partial class(Device)
    private _parent: Device;
    public property Parent: Device read _parent;
    
    private constructor(dvc: cl_device_id; parent: Device);
    begin
      inherited Create(dvc);
      self._parent := parent;
    end;
    private constructor := inherited;
    
    protected procedure Finalize; override :=
    cl.ReleaseDevice(ntv).RaiseIfError;
    
    public function ToString: string; override :=
    $'{inherited ToString} of {Parent}';
    
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
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] on devices: [{AllDevices.JoinToString('', '')}]; Main device: {MainDevice}';
    
    {$region Default}
    
    private static default_need_init := true;
    private static default_init_lock := new object;
    private static _default: Context;
    
    private static function GetDefault: Context;
    begin
      
      // Теоретически default_init_lock может оказаться nil уже после проверки default_need_init, поэтому "??"
      if default_need_init then lock default_init_lock??new object do if default_need_init then
      begin
        default_need_init := false;
        default_init_lock := nil;
        _default := MakeNewDefaultContext;
      end;
      
      Result := _default;
    end;
    private static procedure SetDefault(new_default: Context);
    begin
      default_need_init := false;
      default_init_lock := nil;
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
    
    protected static procedure CheckMainDevice(main_dvc: Device; dvc_lst: IList<Device>) :=
    if not dvc_lst.Contains(main_dvc) then raise new ArgumentException($'%Err:Context:WrongMainDvc%');
    
    public constructor(dvcs: IList<Device>; main_dvc: Device);
    begin
      CheckMainDevice(main_dvc, dvcs);
      
      var ntv_dvcs := new cl_device_id[dvcs.Count];
      for var i := 0 to ntv_dvcs.Length-1 do
        ntv_dvcs[i] := dvcs[i].ntv;
      
      var ec: ErrorCode;
      //ToDo позволить использовать CL_CONTEXT_INTEROP_USER_SYNC в свойствах
      self.ntv := cl.CreateContext(nil, ntv_dvcs.Count, ntv_dvcs, nil, IntPtr.Zero, ec);
      ec.RaiseIfError;
      
      self.dvcs := if dvcs.IsReadOnly then dvcs else new ReadOnlyCollection<Device>(dvcs.ToArray);
      self.main_dvc := main_dvc;
    end;
    public constructor(params dvcs: array of Device) := Create(dvcs, dvcs[0]);
    
    protected static function GetContextDevices(ntv: cl_context): array of Device;
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
    
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure Dispose :=
    if ntv<>cl_context.Zero then lock self do
    begin
      if ntv=cl_context.Zero then exit;
      cl.ReleaseContext(ntv).RaiseIfError;
      ntv := cl_context.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
  end;
  
  {$endregion Context}
  
  {$region ProgramCode}
  
  ProgramCode = partial class
    private ntv: cl_program;
    
    private _c: Context;
    public property BaseContext: Context read _c;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}]';
    
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
          cl.GetProgramBuildInfo(self.ntv, dvc.ntv, ProgramBuildInfo.PROGRAM_BUILD_LOG, UIntPtr.Zero,IntPtr.Zero,sz).RaiseIfError;
          
          var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
          try
            cl.GetProgramBuildInfo(self.ntv, dvc.ntv, ProgramBuildInfo.PROGRAM_BUILD_LOG, sz,str_ptr,IntPtr.Zero).RaiseIfError;
            sb += Marshal.PtrToStringAnsi(str_ptr);
          finally
            Marshal.FreeHGlobal(str_ptr);
          end;
          
        end;
        
        raise new OpenCLException(ec, sb.ToString);
      end else
        ec.RaiseIfError;
      
    end;
    
    public constructor(c: Context; params file_texts: array of string);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateProgramWithSource(c.ntv, file_texts.Length, file_texts, nil, ec);
      ec.RaiseIfError;
      
      self._c := c;
      self.Build;
    end;
    public constructor(params file_texts: array of string) := Create(Context.Default, file_texts);
    
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
    
    {$region Serialize}
    
    public function Serialize: array of array of byte;
    begin
      var sz: UIntPtr;
      
      cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARY_SIZES, UIntPtr.Zero, nil, sz).RaiseIfError;
      var szs := new UIntPtr[sz.ToUInt64 div sizeof(UIntPtr)];
      cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARY_SIZES, sz, szs[0], IntPtr.Zero).RaiseIfError;
      
      var res := new IntPtr[szs.Length];
      SetLength(Result, szs.Length);
      
      for var i := 0 to szs.Length-1 do res[i] := Marshal.AllocHGlobal(IntPtr(pointer(szs[i])));
      try
        cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARIES, sz, res[0], IntPtr.Zero).RaiseIfError;
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
  
  {$region Kernel}
  
  Kernel = partial class
    private ntv: cl_kernel;
    
    private code: ProgramCode;
    public property CodeContainer: ProgramCode read code;
    
    private k_name: string;
    public property Name: string read k_name;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{Name}:{ntv.val}] from {code}';
    
    {$region constructor's}
    
    protected function MakeNewNtv: cl_kernel;
    begin
      var ec: ErrorCode;
      Result := cl.CreateKernel(code.ntv, k_name, ec);
      ec.RaiseIfError;
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
      cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, new UIntPtr(cl_program.Size), code_ntv, IntPtr.Zero).RaiseIfError;
      self.code := new ProgramCode(code_ntv);
      
      var sz: UIntPtr;
      cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, UIntPtr.Zero, nil, sz).RaiseIfError;
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, sz, str_ptr, IntPtr.Zero).RaiseIfError;
        self.k_name := Marshal.PtrToStringAnsi(str_ptr);
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
    
    {$region UseExclusiveNative}
    
    private exclusive_ntv_lock := new object;
    protected procedure UseExclusiveNative(p: cl_kernel->());
    begin
      var owned := Monitor.TryEnter(exclusive_ntv_lock);
      try
        if owned then
          p(self.ntv) else
        begin
          var k := MakeNewNtv;
          try
            p(k);
          finally
            cl.ReleaseKernel(k).RaiseIfError;
          end;
        end;
      finally
        if owned then Monitor.Exit(exclusive_ntv_lock);
      end;
    end;
    protected function UseExclusiveNative<T>(f: cl_kernel->T): T;
    begin
      var owned := Monitor.TryEnter(exclusive_ntv_lock);
      try
        if owned then
          Result := f(self.ntv) else
        begin
          var k := MakeNewNtv;
          try
            Result := f(k);
          finally
            cl.ReleaseKernel(k).RaiseIfError;
          end;
        end;
      finally
        if owned then Monitor.Exit(exclusive_ntv_lock);
      end;
    end;
    
    {$endregion UseExclusiveNative}
    
    {%ContainerMethods\Kernel\Implicit.Interface!MethodGen.pas%}
    
  end;
  
  ProgramCode = partial class
    
    public property KernelByName[kname: string]: Kernel read new Kernel(self, kname); default;
    
    public function GetAllKernels: array of Kernel;
    begin
      
      var c: UInt32;
      cl.CreateKernelsInProgram(ntv, 0, IntPtr.Zero, c).RaiseIfError;
      
      var res := new cl_kernel[c];
      cl.CreateKernelsInProgram(ntv, c, res[0], IntPtr.Zero).RaiseIfError;
      
      Result := res.ConvertAll(k->new Kernel(k, false));
    end;
    
  end;
  
  {$endregion Kernel}
  
  {$region MemorySegment}
  
  MemorySegment = partial class
    private ntv: cl_mem;
    
    private sz: UIntPtr;
    public property Size: UIntPtr read sz;
    public property Size32: UInt32 read sz.ToUInt32;
    public property Size64: UInt64 read sz.ToUInt64;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] of size {Size}';
    
    {$region constructor's}
    
    public constructor(size: UIntPtr; c: Context);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE, size, IntPtr.Zero, ec);
      ec.RaiseIfError;
      
      GC.AddMemoryPressure(size.ToUInt64);
      
      self.sz := size;
    end;
    public constructor(size: integer; c: Context) := Create(new UIntPtr(size), c);
    public constructor(size: int64; c: Context)   := Create(new UIntPtr(size), c);
    
    public constructor(size: UIntPtr) := Create(size, Context.Default);
    public constructor(size: integer) := Create(new UIntPtr(size));
    public constructor(size: int64)   := Create(new UIntPtr(size));
    
    private constructor(ntv: cl_mem; sz: UIntPtr);
    begin
      self.sz := sz;
      self.ntv := ntv;
    end;
    private static function GetMemSize(ntv: cl_mem): UIntPtr;
    begin
      cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(Marshal.SizeOf&<UIntPtr>), Result, IntPtr.Zero).RaiseIfError;
    end;
    public constructor(ntv: cl_mem);
    begin
      Create(ntv, GetMemSize(ntv));
      cl.RetainMemObject(ntv).RaiseIfError;
      GC.AddMemoryPressure(Size64);
    end;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    {$endregion constructor's}
    
    {%ContainerMethods\MemorySegment\Implicit.Interface!MethodGen.pas%}
    
    {%ContainerMethods\MemorySegment.Get\Implicit.Interface!GetMethodGen.pas%}
    
  end;
  
  {$endregion MemorySegment}
  
  {$region MemorySubSegment}
  
  MemorySubSegment = partial class(MemorySegment)
    
    private _parent: MemorySegment;
    public property Parent: MemorySegment read _parent;
    
    public function ToString: string; override :=
    $'{inherited ToString} inside {Parent}';
    
    {$region constructor's}
    
    private static function MakeSubNtv(ntv: cl_mem; reg: cl_buffer_region): cl_mem;
    begin
      var ec: ErrorCode;
      Result := cl.CreateSubBuffer(ntv, MemFlags.MEM_READ_WRITE, BufferCreateType.BUFFER_CREATE_TYPE_REGION, reg, ec);
      ec.RaiseIfError;
    end;
    private constructor(parent: MemorySegment; reg: cl_buffer_region);
    begin
      inherited Create(MakeSubNtv(parent.ntv, reg), reg.size);
      self._parent := parent;
    end;
    public constructor(parent: MemorySegment; origin, size: UIntPtr) := Create(parent, new cl_buffer_region(origin, size));
    
    public constructor(parent: MemorySegment; origin, size: UInt32) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    public constructor(parent: MemorySegment; origin, size: UInt64) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    
    {$endregion constructor's}
    
  end;
  
  {$endregion MemorySubSegment}
  
  {$region CLArray}
  
  CLArray<T> = partial class
  where T: record;
    private ntv: cl_mem;
    
    private len: integer;
    public property Length: integer read len;
    public property ByteSize: int64 read int64(len) * Marshal.SizeOf&<T>;
    
    public function ToString: string; override :=
    $'{self.GetType.Name.Remove(self.GetType.Name.IndexOf(''`''))}<{typeof(T).Name}>[{ntv.val}] of size {Length}';
    
    {$region constructor's}
    
    private procedure InitByLen(c: Context);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE, new UIntPtr(ByteSize), IntPtr.Zero, ec);
      ec.RaiseIfError;
      
      GC.AddMemoryPressure(ByteSize);
    end;
    private procedure InitByVal(c: Context; var els: T);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, MemFlags.MEM_READ_WRITE + MemFlags.MEM_COPY_HOST_PTR, new UIntPtr(ByteSize), els, ec);
      ec.RaiseIfError;
      
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
      cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(Marshal.SizeOf&<UIntPtr>), byte_size, IntPtr.Zero).RaiseIfError;
      
      self.len := byte_size.ToUInt64 div Marshal.SizeOf&<T>;
      self.ntv := ntv;
      
      cl.RetainMemObject(ntv).RaiseIfError;
      GC.AddMemoryPressure(ByteSize);
    end;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    {$endregion constructor's}
    
    private function GetItemProp(ind: integer): T;
    private procedure SetItemProp(ind: integer; value: T);
    public property Item[ind: integer]: T read GetItemProp write SetItemProp; default;
    
    private function GetSectionProp(range: IntRange): array of T;
    private procedure SetSectionProp(range: IntRange; value: array of T);
    public property Section[range: IntRange]: array of T read GetSectionProp write SetSectionProp;
    
    {%ContainerMethods\CLArray\Implicit.Interface!MethodGen.pas%}
    
    {%ContainerMethods\CLArray.Get\Implicit.Interface!GetMethodGen.pas%}
    
  end;
  
  {$endregion CLArray}
  
  {$region Common}
  
  {%Wrappers\Common!WrapGen.pas%}
  
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
      cl.CreateSubDevices(self.ntv, props, 0, IntPtr.Zero, c).RaiseIfError;
      
      var res := new cl_device_id[int64(c)];
      cl.CreateSubDevices(self.ntv, props, c, res[0], IntPtr.Zero).RaiseIfError;
      
      Result := res.ConvertAll(sdvc->new SubDevice(sdvc, self));
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
  
  MemorySegment = partial class
    
    public procedure Dispose; virtual :=
    if ntv<>cl_mem.Zero then lock self do
    begin
      if self.ntv=cl_mem.Zero then exit; // Во время ожидания lock могли удалить
      {%>self.prop := nil;%}
      GC.RemoveMemoryPressure(Size64);
      cl.ReleaseMemObject(ntv).RaiseIfError;
      ntv := cl_mem.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
  end;
  
  MemorySubSegment = partial class
    
    public procedure Dispose; override :=
    if ntv<>cl_mem.Zero then lock self do
    begin
      if self.ntv=cl_mem.Zero then exit; // Во время ожидания lock могли удалить
      {%>self.prop := nil;%}
      cl.ReleaseMemObject(ntv).RaiseIfError;
      ntv := cl_mem.Zero;
    end;
    
  end;
  
  CLArray<T> = partial class
    
    public procedure Dispose; virtual :=
    if ntv<>cl_mem.Zero then lock self do
    begin
      if self.ntv=cl_mem.Zero then exit; // Во время ожидания lock могли удалить
      {%>self.prop := nil;%}
      GC.RemoveMemoryPressure(ByteSize);
      cl.ReleaseMemObject(ntv).RaiseIfError;
      ntv := cl_mem.Zero;
    end;
    protected procedure Finalize; override := Dispose;
    
  end;
  
  {$endregion Misc}
  
  {$endregion Wrappers}
  
  {$region CommandQueue}
  
  {$region Base}
  
  CommandQueueBase = abstract partial class
    
    {$region ToString}
    
    private static function DisplayNameForType(t: System.Type): string;
    begin
      Result := t.Name;
      
      if t.IsGenericType then
      begin
        var ind := Result.IndexOf('`');
        Result := Result.Remove(ind) + '<' + t.GenericTypeArguments.JoinToString(', ') + '>';
      end;
      
    end;
    private function DisplayName: string; virtual := DisplayNameForType(self.GetType);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private static function GetValueRuntimeType<T>(val: T) :=
    if typeof(T).IsValueType then
      typeof(T) else
    if val = default(T) then
      nil else val.GetType;
    
    private function ToStringHeader(sb: StringBuilder; index: Dictionary<CommandQueueBase,integer>): boolean;
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
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
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
      ToString(sb, 0, new Dictionary<CommandQueueBase, integer>, new HashSet<CommandQueueBase>);
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
    
    {$endregion ToString}
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
  end;
  
  {$endregion Base}
  
  {$region Const}
  
  IConstQueue = interface
    function GetConstVal: Object;
  end;
  ConstQueue<T> = sealed partial class(CommandQueue<T>, IConstQueue)
    private res: T;
    
    public constructor(o: T) := self.res := o;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    
    public function IConstQueue.GetConstVal: object := self.res;
    public property Val: T read self.res;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' ';
      var rt := GetValueRuntimeType(res);
      if typeof(T) <> rt then
        sb.Append(rt);
      sb += '{ ';
      if rt<>nil then
        sb.Append(Val) else
        sb += 'nil';
      sb += ' }'#10;
    end;
    
  end;
  
  CommandQueueBase = abstract partial class
    
    public static function operator implicit(o: object): CommandQueueBase :=
    new ConstQueue<object>(o);
    
  end;
  
  CommandQueue<T> = abstract partial class
    
    public static function operator implicit(o: T): CommandQueue<T> :=
    new ConstQueue<T>(o);
    
  end;
  
  {$endregion Const}
  
  {$region Cast}
  
  CommandQueueBase = abstract partial class
    
    public function Cast<T>: CommandQueue<T>;
    
  end;
  
  {$endregion Cast}
  
  {$region ThenConvert}
  
  CommandQueueBase = partial abstract class
    
    private function ThenConvertBase<TOtp>(f: (object, Context)->TOtp): CommandQueue<TOtp>; virtual;
    
    public function ThenConvert<TOtp>(f: object->TOtp           ) := ThenConvertBase((o,c)->f(o));
    public function ThenConvert<TOtp>(f: (object, Context)->TOtp) := ThenConvertBase(f);
    
  end;
  
  CommandQueue<T> = partial abstract class(CommandQueueBase)
    
    private function ThenConvertBase<TOtp>(f: (object, Context)->TOtp): CommandQueue<TOtp>; override :=
    ThenConvert(f as object as Func2<T, Context, TOtp>); //ToDo #2221
    
    public function ThenConvert<TOtp>(f: T->TOtp): CommandQueue<TOtp> := ThenConvert((o,c)->f(o));
    public function ThenConvert<TOtp>(f: (T, Context)->TOtp): CommandQueue<TOtp>;
    
  end;
  
  {$endregion ThenConvert}
  
  {$region +/*}
  
  CommandQueueBase = partial abstract class
    
    private function AfterQueueSyncBase(q: CommandQueueBase): CommandQueueBase; virtual;
    private function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; virtual;
    
    public static function operator+(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueSyncBase(q1);
    public static function operator*(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueAsyncBase(q1);
    
    public static procedure operator+=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1*q2;
    
  end;
  
  CommandQueue<T> = partial abstract class(CommandQueueBase)
    
    private function AfterQueueSyncBase (q: CommandQueueBase): CommandQueueBase; override := q+self;
    private function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; override := q*self;
    
    public static function operator+(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    public static function operator*(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    
    public static procedure operator+=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1*q2;
    
  end;
  
  {$endregion +/*}
  
  {$region Multiusable}
  
  CommandQueueBase = partial abstract class
    
    private function MultiusableBase: ()->CommandQueueBase; virtual;
    
    public function Multiusable := MultiusableBase;
    
  end;
  
  CommandQueue<T> = partial abstract class(CommandQueueBase)
    
    private function MultiusableBase: ()->CommandQueueBase; override := Multiusable() as object as Func<CommandQueueBase>; //ToDo #2221
    
    public function Multiusable: ()->CommandQueue<T>;
    
  end;
  
  {$endregion Multiusable}
  
  {$region Wait}
  
  WaitMarkerBase = abstract partial class(CommandQueueBase)
    
    public procedure SendSignal;
    
  end;
  
  WaitMarker = sealed partial class(WaitMarkerBase)
    
    public constructor := exit;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override := sb += #10;
    
  end;
  
  PseudoWaitMarker<T> = sealed partial class
    private q: CommandQueue<T>;
    private wrap: WaitMarkerBase;
    
    public constructor(q: CommandQueue<T>);
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public static function operator implicit(pmarker: PseudoWaitMarker<T>): WaitMarkerBase := pmarker.wrap;
    
    public procedure SendSignal := wrap.SendSignal;
    
  end;
  
  CommandQueueBase = abstract partial class
    
    private function ThenWaitMarkerBase: WaitMarkerBase; virtual;
    public function ThenWaitMarker := ThenWaitMarkerBase;
    
    private function ThenWaitForAllBase(markers: sequence of WaitMarkerBase): CommandQueueBase; virtual;
    private function ThenWaitForAnyBase(markers: sequence of WaitMarkerBase): CommandQueueBase; virtual;
    
    public function ThenWaitForAll(params markers: array of WaitMarkerBase) := ThenWaitForAllBase(markers);
    public function ThenWaitForAll(    markers: sequence of WaitMarkerBase) := ThenWaitForAllBase(markers);
    
    public function ThenWaitForAny(params markers: array of WaitMarkerBase) := ThenWaitForAnyBase(markers);
    public function ThenWaitForAny(    markers: sequence of WaitMarkerBase) := ThenWaitForAnyBase(markers);
    
    public function ThenWaitFor(marker: WaitMarkerBase) := ThenWaitForAll(marker);
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function ThenWaitMarkerBase: WaitMarkerBase; override := ThenWaitMarker;
    
    public function ThenWaitMarker := new PseudoWaitMarker<T>(self);
    
    private function ThenWaitForAllBase(markers: sequence of WaitMarkerBase): CommandQueueBase; override := ThenWaitForAll(markers);
    private function ThenWaitForAnyBase(markers: sequence of WaitMarkerBase): CommandQueueBase; override := ThenWaitForAny(markers);
    
    public function ThenWaitForAll(params markers: array of WaitMarkerBase): CommandQueue<T> := ThenWaitForAll(markers.AsEnumerable);
    public function ThenWaitForAll(    markers: sequence of WaitMarkerBase): CommandQueue<T>;
    
    public function ThenWaitForAny(params markers: array of WaitMarkerBase): CommandQueue<T> := ThenWaitForAny(markers.AsEnumerable);
    public function ThenWaitForAny(    markers: sequence of WaitMarkerBase): CommandQueue<T>;
    
    public function ThenWaitFor(marker: WaitMarkerBase) := ThenWaitForAll(marker);
    
  end;
  
  {$endregion Wait}
  
  {$endregion CommandQueue}
  
  {$region CLTask}
  
  CLTaskBase = abstract partial class
    protected wh := new ManualResetEvent(false);
    protected wh_lock := new object;
    
    {$region Property's}
    
    private function OrgQueueBase: CommandQueueBase; abstract;
    public property OrgQueue: CommandQueueBase read OrgQueueBase;
    
    private org_c: Context;
    public property OrgContext: Context read org_c;
    
    {$endregion Property's}
    
    {$region CLTask event's}
    
    public procedure WhenDoneBase(cb: Action<CLTaskBase>); abstract;
    
    public procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); abstract;
    
    public procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); abstract;
    
    /// True если очередь уже завершилась
    protected function AddEventHandler<T>(ev: List<T>; cb: T): boolean; where T: Delegate;
    begin
      lock wh_lock do
      begin
        Result := wh.WaitOne(0);
        if not Result then ev += cb;
      end;
    end;
    
    {$endregion CLTask event's}
    
    {$region Error's}
    protected err_lst := new List<Exception>;
    
    /// lock err_lst do err_lst.ToArray
    protected function GetErrArr: array of Exception;
    begin
      lock err_lst do
        Result := err_lst.ToArray;
    end;
    
    public property Error: AggregateException read err_lst.Count=0 ? nil : new AggregateException($'%Err:CLTask:%', GetErrArr);
    
    {$endregion Error's}
    
    {$region AddErr}
    protected static AbortStatus := new CommandExecutionStatus(integer.MinValue);
    
    protected procedure AddErr(e: Exception);
    
    {%!!} /// True если ошибка есть {%}
    protected function AddErr(ec: ErrorCode): boolean;
    begin
      if not ec.IS_ERROR then exit;
      AddErr(new OpenCLException(ec, $'Внутренняя ошибка OpenCLABC: {ec}{#10}{Environment.StackTrace}'));
      Result := true;
    end;
    {%!!} /// True если ошибка есть {%}
    protected function AddErr(st: CommandExecutionStatus) :=
    (st=AbortStatus) or (st.IS_ERROR and AddErr(ErrorCode(st)));
    
    {$endregion AddErr}
    
    {$region Wait}
    
    public procedure Wait;
    begin
      wh.WaitOne;
      var err := self.Error;
      if err<>nil then raise err;
    end;
    
    private function WaitResBase: object; abstract;
    public function WaitRes := WaitResBase;
    
    {$endregion Wait}
    
  end;
  
  CLTask<T> = sealed partial class(CLTaskBase)
    private q: CommandQueue<T>;
    private q_res: T;
    
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    {$region Property's}
    
    public property OrgQueue: CommandQueue<T> read q; reintroduce;
    protected function OrgQueueBase: CommandQueueBase; override := self.OrgQueue;
    
    {$endregion Property's}
    
    {$region CLTask event's}
    
    private EvDone := new List<Action<CLTask<T>>>;
    public procedure WhenDone(cb: Action<CLTask<T>>); reintroduce :=
    if AddEventHandler(EvDone, cb) then cb(self);
    public procedure WhenDoneBase(cb: Action<CLTaskBase>); override :=
    WhenDone(cb as object as Action<CLTask<T>>); //ToDo #2221
    
    private EvComplete := new List<Action<CLTask<T>, T>>;
    public procedure WhenComplete(cb: Action<CLTask<T>, T>); reintroduce :=
    if AddEventHandler(EvComplete, cb) and (err_lst.Count=0) then cb(self, q_res);
    public procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); override :=
    WhenComplete((tsk,res)->cb(tsk,res)); //ToDo #2221
    
    private EvError := new List<Action<CLTask<T>, array of Exception>>;
    public procedure WhenError(cb: Action<CLTask<T>, array of Exception>); reintroduce :=
    if AddEventHandler(EvError, cb) and (err_lst.Count<>0) then cb(self, GetErrArr);
    public procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); override :=
    WhenError(cb as object as Action<CLTask<T>, array of Exception>); //ToDo #2221
    
    {$endregion CLTask event's}
    
    {$region Wait}
    
    public function WaitRes: T; reintroduce;
    begin
      Wait;
      Result := self.q_res;
    end;
    private function WaitResBase: object; override := WaitRes;
    
    {$endregion Wait}
    
  end;
  
  Context = partial class
    
    public function BeginInvoke<T>(q: CommandQueue<T>): CLTask<T>;
    public function BeginInvoke(q: CommandQueueBase): CLTaskBase;
    
    public function SyncInvoke<T>(q: CommandQueue<T>) := BeginInvoke(q).WaitRes;
    public function SyncInvoke(q: CommandQueueBase) := BeginInvoke(q).WaitRes;
    
  end;
  
  {$endregion CLTask}
  
  {$region KernelArg}
  
  KernelArg = abstract partial class
    
    {$region MemorySegment}
    
    public static function FromMemorySegment(mem: MemorySegment): KernelArg;
    public static function operator implicit(mem: MemorySegment): KernelArg := FromMemorySegment(mem);
    
    public static function FromMemorySegmentCQ(mem_q: CommandQueue<MemorySegment>): KernelArg;
    public static function operator implicit(mem_q: CommandQueue<MemorySegment>): KernelArg := FromMemorySegmentCQ(mem_q);
    
    {$endregion MemorySegment}
    
    {$region CLArray}
    
    public static function FromCLArray<T>(a: CLArray<T>): KernelArg; where T: record;
    public static function operator implicit<T>(a: CLArray<T>): KernelArg; where T: record;
    begin Result := FromCLArray(a); end;
    
    public static function FromCLArrayCQ<T>(a_q: CommandQueue<CLArray<T>>): KernelArg; where T: record;
    public static function operator implicit<T>(a_q: CommandQueue<CLArray<T>>): KernelArg; where T: record;
    begin Result := FromCLArrayCQ(a_q); end;
    
    {$endregion CLArray}
    
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
    
    {$region ToString}
    
    private function DisplayName: string; virtual := CommandQueueBase.DisplayNameForType(self.GetType);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
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
      ToString(sb, 0, new Dictionary<CommandQueueBase, integer>, new HashSet<CommandQueueBase>);
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
  
  {$region KernelCCQ}
  
  KernelCCQ = sealed partial class
    
    {%ContainerCommon\Kernel\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\Kernel\Explicit.Interface!MethodGen.pas%}
    
  end;
  
  Kernel = partial class
    public function NewQueue := new KernelCCQ({%>self%});
  end;
  
  {$endregion KernelCCQ}
  
  {$region MemorySegmentCCQ}
  
  MemorySegmentCCQ = sealed partial class
    
    {%ContainerCommon\MemorySegment\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\MemorySegment\Explicit.Interface!MethodGen.pas%}
    
    {%ContainerMethods\MemorySegment.Get\Explicit.Interface!GetMethodGen.pas%}
    
  end;
  
  MemorySegment = partial class
    public function NewQueue := new MemorySegmentCCQ({%>self%});
  end;
  
  KernelArg = abstract partial class
    public static function operator implicit(mem_q: MemorySegmentCCQ): KernelArg;
  end;
  
  {$endregion MemorySegmentCCQ}
  
  {$region CLArrayCCQ}
  
  CLArrayCCQ<T> = sealed partial class
  where T: record;
    
    {%ContainerCommon\CLArray\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLArray\Explicit.Interface!MethodGen.pas%}
    
    {%ContainerMethods\CLArray.Get\Explicit.Interface!GetMethodGen.pas%}
    
  end;
  
  CLArray<T> = partial class
    public function NewQueue := new CLArrayCCQ<T>({%>self%});
  end;
  
  KernelArg = abstract partial class
    public static function operator implicit<T>(a_q: CLArrayCCQ<T>): KernelArg; where T: record;
  end;
  
  {$endregion CLArrayCCQ}
  
{$region Global subprograms}

{$region HFQ/HPQ}

function HFQ<T>(f: ()->T): CommandQueue<T>;
function HFQ<T>(f: Context->T): CommandQueue<T>;

function HPQ(p: ()->()): CommandQueueBase;
function HPQ(p: Context->()): CommandQueueBase;

{$endregion HFQ/HPQ}

{$region WaitFor}

function WaitForAll(params markers: array of WaitMarkerBase): CommandQueueBase;
function WaitForAll(    markers: sequence of WaitMarkerBase): CommandQueueBase;

function WaitForAny(params markers: array of WaitMarkerBase): CommandQueueBase;
function WaitForAny(    markers: sequence of WaitMarkerBase): CommandQueueBase;

function WaitFor(marker: WaitMarkerBase): CommandQueueBase;

{$endregion WaitFor}

{$region CombineQueue's}

{%Global\CombineQueues\Interface!CombineQueues.pas%}

{$endregion CombineQueue's}

{$endregion Global subprograms}

implementation

{$region Properties}

{$region Base}

type
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

{%WrapperProperties\Implementation!WrapPropGen.pas%}

{$endregion Properties}

{$region Wrappers}

{$region CLArray}

function CLArray<T>.GetItemProp(ind: integer): T :=
{%>GetItem(ind)!!} default(T) {%};
procedure CLArray<T>.SetItemProp(ind: integer; value: T) :=
{%>WriteItem(value, ind)!!} exit() {%};

function CLArray<T>.GetSectionProp(range: IntRange): array of T :=
{%>GetArray(range.Low, range.High-range.Low+1)!!} nil {%};
procedure CLArray<T>.SetSectionProp(range: IntRange; value: array of T) :=
{%>WriteArray(value, range.Low, range.High-range.Low+1, 0)!!} exit() {%};

{$endregion CLArray}

{$endregion Wrappers}

{$region Util type's}

{$region EventDebug}{$ifdef EventDebug}

type
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
    
    private static RefCounter := new Dictionary<cl_event, List<EventRetainReleaseData>>;
    private static function RefCounterFor(ev: cl_event): List<EventRetainReleaseData>;
    begin
      lock RefCounter do
        if not RefCounter.TryGetValue(ev, Result) then
        begin
          Result := new List<EventRetainReleaseData>;
          RefCounter[ev] := Result;
        end;
    end;
    
    public static procedure RegisterEventRetain(ev: cl_event; reason: string);
    begin
      var lst := RefCounterFor(ev);
      lock lst do lst += new EventRetainReleaseData(false, reason);
    end;
    public static procedure RegisterEventRelease(ev: cl_event; reason: string);
    begin
      var lst := RefCounterFor(ev);
      lock lst do lst += new EventRetainReleaseData(true, reason);
    end;
    
    public static procedure ReportRefCounterInfo :=
    lock output do lock RefCounter do
    begin
      
      foreach var ev in RefCounter.Keys do
      begin
        $'Logging state change of {ev}'.Println;
        var lst := RefCounter[ev];
        var c := 0;
        lock lst do
          foreach var act in lst do
          begin
            if act.is_release then
              c -= 1 else
              c += 1;
            $'{c,3} | {act}'.Println;
          end;
        Writeln('-'*30);
      end;
      
      Writeln('='*40);
    end;
    
    {$endregion Retain/Release}
    
  end;
  
{$endif EventDebug}{$endregion EventDebug}

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
    
    public static function GCHndAlloc(o: object) :=
    CopyToUnm(GCHandle.Alloc(o));
    
    public static procedure GCHndFree(gc_hnd_ptr: IntPtr);
    begin
      AsPtr&<GCHandle>(gc_hnd_ptr)^.Free;
      Marshal.FreeHGlobal(gc_hnd_ptr);
    end;
    
    public static function StartNewBgThread(p: Action): Thread;
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
      
      //ToDo Протестировать - может быстрее будет без blittable_cache, потому что всё заинлайнится?
      if blittable_cache.TryGetValue(t, Result) then exit;
      
      foreach var fld in t.GetFields(System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.Public or System.Reflection.BindingFlags.NonPublic) do
        if fld.FieldType<>t then
        begin
          Result := Blame(fld.FieldType);
          if Result<>nil then break;
        end;
      
      blittable_cache[t] := Result;
    end;
    
//    public static function IsBlittable(t: System.Type) := Blame(t)=nil;
    public static procedure RaiseIfNeed(t: System.Type; source_name: string);
    begin
      var blame := BlittableHelper.Blame(t);
      if blame=nil then exit;
      raise new BlittableException(t, blame, source_name);
    end;
    
  end;
  
{$endregion Blittable}

{$region EventList}

type
  EventList = sealed partial class
    public evs: array of cl_event;
    public count := 0;
    public abortable := false; // true только если можно моментально отменить
    
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
    
    public constructor := exit;
    public constructor(count: integer) :=
    if count<>0 then self.evs := new cl_event[count];
    
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
    
    {$endregion constructor's}
    
    {$region operator+}
    
    public static procedure operator+=(l: EventList; ev: cl_event);
    begin
      l.evs[l.count] := ev;
      l.count += 1;
    end;
    
    public static procedure operator+=(l: EventList; ev: EventList);
    begin
      for var i := 0 to ev.count-1 do
        l += ev[i];
      l.abortable := l.abortable or ev.abortable;
    end;
    
    public static function operator+(l1, l2: EventList): EventList;
    begin
      Result := new EventList(l1.count+l2.count);
      Result += l1;
      Result += l2;
      Result.abortable := l1.abortable or l2.abortable;
    end;
    
    public static function operator+(l: EventList; ev: cl_event): EventList;
    begin
      Result := new EventList(l.count+1);
      Result += l;
      Result += ev;
    end;
    
    {$endregion operator+}
    
    {$region cl_event.AttachCallback}
    
    public static procedure AttachNativeCallback(ev: cl_event; cb: EventCallback) :=
    cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, NativeUtils.GCHndAlloc(cb)).RaiseIfError;
    
    private static function DefaultStatusErr(tsk: CLTaskBase; st: CommandExecutionStatus; save_err: boolean): boolean :=
    if save_err then tsk.AddErr(st) else st.IS_ERROR;
    
    public static procedure AttachCallback(ev: cl_event; work: Action; tsk: CLTaskBase; need_ev_release: boolean{$ifdef EventDebug}; reason: string{$endif}; st_err_handler: (CLTaskBase, CommandExecutionStatus, boolean)->boolean := DefaultStatusErr; save_err: boolean := true) :=
    AttachNativeCallback(ev, (ev,st,data)->
    begin
      if need_ev_release then
      begin
        tsk.AddErr(cl.ReleaseEvent(ev));
        {$ifdef EventDebug}
        EventDebug.RegisterEventRelease(ev, $'discarding after use in AttachCallback, working on {reason}');
        {$endif EventDebug}
      end;
      
      if not st_err_handler(tsk, st, save_err) then
      try
        work;
      except
        on e: Exception do tsk.AddErr(e);
      end;
      
      NativeUtils.GCHndFree(data);
    end);
    
    public static procedure AttachFinallyCallback(ev: cl_event; work: Action; tsk: CLTaskBase; need_ev_release: boolean{$ifdef EventDebug}; reason: string{$endif}) :=
    AttachNativeCallback(ev, (ev,st,data)->
    begin
      if need_ev_release then
      begin
        tsk.AddErr(cl.ReleaseEvent(ev));
        {$ifdef EventDebug}
        if reason=nil then raise new InvalidOperationException;
        EventDebug.RegisterEventRelease(ev, $'discarding after use in AttachFinallyCallback, working on {reason}');
        {$endif EventDebug}
      end;
      
      try
        work;
      except
        on e: Exception do tsk.AddErr(e);
      end;
      
      NativeUtils.GCHndFree(data);
    end);
    
    {$endregion cl_event.AttachCallback}
    
    {$region EventList.AttachCallback}
    
    private function ToMarker(c: cl_context; dvc: cl_device_id; var cq: cl_command_queue; expect_smart_status_err: boolean): cl_event;
    begin
      {$ifdef DEBUG}
      if count <= 1 then raise new System.NotSupportedException;
      {$endif DEBUG}
      
      NativeUtils.FixCQ(c, dvc, cq);
      cl.EnqueueMarkerWithWaitList(cq, self.count, self.evs, Result).RaiseIfError;
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(Result, $'enq''ed marker for evs: {evs.JoinToString}');
      {$endif EventDebug}
      if expect_smart_status_err then self.Retain(
        {$ifdef EventDebug}$'making sure ev isn''t deleted until SmartStatusErr'{$endif}
      );
      
    end;
    
    private function SmartStatusErr(tsk: CLTaskBase; org_st: CommandExecutionStatus; save_err: boolean; need_release: boolean): boolean;
    begin
      //ToDo NV#3035203
      //ToDo И добавить использование save_err, когда раскомметирую
//      if not org_st.IS_ERROR then exit;
//      if org_st.val <> ErrorCode.EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST.val then
//        Result := tsk.AddErr(org_st) else
      
      {$ifdef DEBUG}
      if count <= 1 then raise new System.NotSupportedException;
      {$endif DEBUG}
      
      for var i := 0 to count-1 do
      begin
        var st: CommandExecutionStatus;
        var ec := cl.GetEventInfo(
          evs[i], EventInfo.EVENT_COMMAND_EXECUTION_STATUS,
          new UIntPtr(sizeof(CommandExecutionStatus)), st, IntPtr.Zero
        );
        
        if tsk.AddErr(ec) then continue;
        if save_err ? tsk.AddErr(st) : st.IS_ERROR then Result := true;
        
      end;
      
      if need_release then self.Release(
        {$ifdef EventDebug}$'after use in SmartStatusErr'{$endif}
      );
      
      //ToDo NV#3035203 - без бага эта часть не нужна
      if org_st.val <> ErrorCode.EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST.val then
        if save_err ? tsk.AddErr(org_st) : org_st.IS_ERROR then Result := true;
    end;
    
    public procedure AttachCallback(work: Action; tsk: CLTaskBase; c: cl_context; dvc: cl_device_id; var cq: cl_command_queue{$ifdef EventDebug}; reason: string{$endif}; save_err: boolean := true) :=
    case self.count of
      0: work;
      1: AttachCallback(self.evs[0], work, tsk, false{$ifdef EventDebug}, nil{$endif}, DefaultStatusErr, save_err);
      else AttachCallback(self.ToMarker(c, dvc, cq, true), work, tsk, true{$ifdef EventDebug}, reason{$endif}, (tsk,st,save_err)->SmartStatusErr(tsk,st,save_err,true), save_err);
    end;
    
    public procedure AttachFinallyCallback(work: Action; tsk: CLTaskBase; c: cl_context; dvc: cl_device_id; var cq: cl_command_queue{$ifdef EventDebug}; reason: string{$endif}) :=
    case self.count of
      0: work;
      1: AttachFinallyCallback(self.evs[0], work, tsk, false{$ifdef EventDebug}, nil{$endif});
      else AttachFinallyCallback(self.ToMarker(c, dvc, cq, false), work, tsk, true{$ifdef EventDebug}, reason{$endif});
    end;
    
    {$endregion EventList.AttachCallback}
    
    {$region Retain/Release}
    
    public procedure Retain({$ifdef EventDebug}reason: string{$endif}) :=
    for var i := 0 to count-1 do
    begin
      cl.RetainEvent(evs[i]).RaiseIfError;
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(evs[i], $'{reason}, together with evs: {evs.JoinToString}');
      {$endif EventDebug}
    end;
    
    public procedure Release({$ifdef EventDebug}reason: string{$endif}) :=
    for var i := 0 to count-1 do
    begin
      cl.ReleaseEvent(evs[i]).RaiseIfError;
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(evs[i], $'{reason}, together with evs: {evs.JoinToString}');
      {$endif EventDebug}
    end;
    
    /// True если возникла ошибка
    public function WaitAndRelease(tsk: CLTaskBase): boolean;
    begin
      {$ifdef DEBUG}
      if count=0 then raise new NotSupportedException;
      {$endif DEBUG}
      
      var ec := cl.WaitForEvents(self.count, self.evs);
      if count=1 then
        Result := tsk.AddErr(ec) else
        Result := SmartStatusErr(tsk, CommandExecutionStatus(ec), true, false);
      
      self.Release({$ifdef EventDebug}$'discarding after being waited upon'{$endif EventDebug});
    end;
    
    {$endregion Retain/Release}
    
  end;
  
{$endregion EventList}

{$region UserEvent}

type
  UserEvent = sealed class
    private uev: cl_event;
    private done := false;
    
    {$region constructor's}
    
    private constructor(c: cl_context{$ifdef EventDebug}; reason: string{$endif});
    begin
      var ec: ErrorCode;
      self.uev := cl.CreateUserEvent(c, ec);
      ec.RaiseIfError;
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(self.uev, $'Created for {reason}');
      {$endif EventDebug}
    end;
    private constructor := raise new System.InvalidOperationException($'%Err:NoParamCtor%');
    public static function MakeUserEvent(tsk: CLTaskBase; c: cl_context{$ifdef EventDebug}; reason: string{$endif}): UserEvent;
    
    public static function StartBackgroundWork(after: EventList; work: Action; c: cl_context; tsk: CLTaskBase{$ifdef EventDebug}; reason: string{$endif}): UserEvent;
    begin
      var res := MakeUserEvent(tsk, c
        {$ifdef EventDebug}, $'BackgroundWork, executing {reason}, after waiting on: {after?.evs?.JoinToString}'{$endif}
      );
      
      var abort_thr_ev := new AutoResetEvent(false);
      EventList.AttachFinallyCallback(res, ()->abort_thr_ev.Set(), tsk, false{$ifdef EventDebug}, nil{$endif});
      
      var work_thr: Thread;
      var abort_thr := NativeUtils.StartNewBgThread(()->
      begin
        abort_thr_ev.WaitOne; // Изначальная пауза, чтобы work_thr не убили до того как он успеет запуститься и выполнить after.Release
        abort_thr_ev.WaitOne;
        work_thr.Abort;
      end);
      
      work_thr := NativeUtils.StartNewBgThread(()->
      try
        var err := false;
        try
          if (after<>nil) and (after.count<>0) then
          begin
            if not after.abortable then
              after := after + MakeUserEvent(tsk,c
                {$ifdef EventDebug}, $'abortability of BackgroundWork wait on: {after.evs.JoinToString}'{$endif}
              );
            err := after.WaitAndRelease(tsk);
          end;
        finally
          abort_thr_ev.Set;
          // Далее - в любом случае выполняется res.SetStatus, который вызывает
          // содержимое res.AttachFinallyCallback выше
          // Поэтому abort_thr никогда не застрянет
        end;
        
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
          tsk.AddErr(e);
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
        if tsk.AddErr(cl.SetUserEventStatus(uev, st)) then exit;
        done := true;
        Result := true;
      end;
    end;
    public function Abort := SetStatus(CLTaskBase.AbortStatus);
    
    {$endregion Status}
    
    {$region operator's}
    
    public static function operator implicit(ev: UserEvent): cl_event := ev.uev;
    public static function operator implicit(ev: UserEvent): EventList;
    begin
      Result := ev.uev;
      Result.abortable := true;
    end;
    
    public static function operator+(ev1: EventList; ev2: UserEvent): EventList;
    begin
      Result := ev1 + ev2.uev;
      Result.abortable := true;
    end;
    public static procedure operator+=(ev1: EventList; ev2: UserEvent);
    begin
      ev1 += ev2.uev;
      ev1.abortable := true;
    end;
    
    {$endregion operator's}
    
  end;
  
  EventList = sealed partial class
    
    private static function Combine(evs: IList<EventList>; tsk: CLTaskBase; c: cl_context; main_dvc: cl_device_id; var cq: cl_command_queue): EventList;
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
        var uev := UserEvent.MakeUserEvent(tsk, c
          {$ifdef EventDebug}, $'abortability of EventList.Combine of: {Result.evs.Take(Result.count).JoinToString}'{$endif}
        );
        Result.AttachFinallyCallback(()->uev.SetStatus(CommandExecutionStatus.COMPLETE), tsk, c, main_dvc, cq
          {$ifdef EventDebug}, $'setting abort ev: {uev.uev}'{$endif}
        );
        Result += uev.uev; //ToDo #2431 // Result += uev; и abortable не надо ручками
        Result.abortable := true;
      end;
      
    end;
    
  end;
  
{$endregion UserEvent}

{$region QueueRes}

type
  {$region Misc}
  
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
  
  {$endregion Misc}
  
  {$region Base}
  
  QueueRes<T> = abstract partial class end;
  QueueResBase = abstract partial class
    public ev: EventList;
    public can_set_ev := true;
    
    public constructor(ev: EventList) :=
    self.ev := ev;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public function GetResBase: object; abstract;
    public function TrySetEvBase(new_ev: EventList): QueueResBase; abstract;
    
    public function LazyQuickTransformBase<T2>(f: object->T2): QueueRes<T2>; abstract;
    
  end;
  
  QueueRes<T> = abstract partial class(QueueResBase)
    
    public function GetRes: T; abstract;
    public function GetResBase: object; override := GetRes;
    
    public function TrySetEv(new_ev: EventList): QueueRes<T>;
    begin
      if self.ev=new_ev then
        Result := self else
      begin
        Result := if can_set_ev then self else Clone;
        Result.ev := new_ev;
      end;
    end;
    public function TrySetEvBase(new_ev: EventList): QueueResBase; override := TrySetEv(new_ev);
    
    public function Clone: QueueRes<T>; abstract;
    
    public function EnsureAbortability(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue): QueueRes<T>;
    begin
      Result := self;
      if (ev.count<>0) and not ev.abortable then
      begin
        var uev := UserEvent.MakeUserEvent(tsk, c.ntv
          {$ifdef EventDebug}, $'abortability of QueueRes with .ev: {ev.evs.JoinToString}'{$endif}
        );
        ev.AttachFinallyCallback(()->uev.SetStatus(CommandExecutionStatus.COMPLETE), tsk, c.ntv, main_dvc, cq{$ifdef EventDebug}, $'setting abort ev: {uev.uev}'{$endif});
        Result := Result.TrySetEv(ev + uev);
      end;
    end;
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>; abstract;
    public function LazyQuickTransformBase<T2>(f: object->T2): QueueRes<T2>; override :=
    LazyQuickTransform(o->f(o)); //ToDo #2221
    
    /// Должно выполнятся только после ожидания ивентов
    public function ToPtr: IPtrQueueRes<T>; abstract;
    
  end;
  
  {$endregion Base}
  
  {$region Const}
  
  // Результат который просто есть
  QueueResConst<T> = sealed partial class(QueueRes<T>)
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
  
  {$endregion Const}
  
  {$region Func}
  
  // Результат который надо будет сначала дождаться, а потом ещё досчитать
  QueueResFunc<T> = sealed partial class(QueueRes<T>)
    private f: ()->T;
    
    public constructor(f: ()->T; ev: EventList);
    begin
      inherited Create(ev);
      self.f := f;
    end;
    private constructor := inherited;
    
    public function Clone: QueueRes<T>; override := new QueueResFunc<T>(f, ev);
    
    public function GetRes: T; override := f();
    
    public function LazyQuickTransform<T2>(f2: T->T2): QueueRes<T2>; override :=
    new QueueResFunc<T2>(()->f2(self.f), self.ev);
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(self.f());
    
  end;
  
  {$endregion Func}
  
  {$region Delayed}
  
  // Результат который будет сохранён куда то, надо только дождаться
  QueueResDelayedBase<T> = abstract partial class(QueueRes<T>)
    
    // QueueResFunc, потому что результат сохраняется именно в этот объект, а не в клон
    public function Clone: QueueRes<T>; override := new QueueResFunc<T>(self.GetRes, ev);
    
    public procedure SetRes(value: T); abstract;
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>; override :=
    new QueueResFunc<T2>(()->f(self.GetRes()), self.ev);
    
  end;
  
  QueueResDelayedObj<T> = sealed partial class(QueueResDelayedBase<T>)
    private res := default(T);
    
    public constructor := inherited Create(nil);
    
    public function GetRes: T; override := res;
    public procedure SetRes(value: T); override := res := value;
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(res);
    
  end;
  
  QueueResDelayedPtr<T> = sealed partial class(QueueResDelayedBase<T>, IPtrQueueRes<T>)
    private ptr: ^T := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<T>));
    
    public constructor := inherited Create(nil);
    
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
  
  QueueResDelayedBase<T> = abstract partial class(QueueRes<T>)
    
    public static function MakeNew(need_ptr_qr: boolean) :=
    if need_ptr_qr then
      new QueueResDelayedPtr<T> as QueueResDelayedBase<T> else
      new QueueResDelayedObj<T> as QueueResDelayedBase<T>;
    
  end;
  
  {$endregion Delayed}
  
{$endregion QueueRes}

{$region MWEventContainer}

type
  MWEventContainer = sealed class // MW = Multi Wait
    private curr_handlers := new Queue<()->boolean>;
    private cached := 0;
    
    public procedure AddHandler(handler: ()->boolean) := lock self do
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

{$region MultiusableBase}

type
  MultiusableCommandQueueHubBase = abstract class
    
  end;
  
{$endregion MultiusableBase}

{$region CommandQueue}

{$region Base}

type
  CommandQueueBase = abstract partial class
    
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; abstract;
    
    private procedure FinishAfterNewQ(cq: cl_command_queue; ev: EventList; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id);
    begin
      {$ifdef DEBUG}
      if (ev.count<>0) and not ev.abortable then raise new System.NotSupportedException;
      {$endif DEBUG}
      if cq=cl_command_queue.Zero then exit;
      
      ev.AttachFinallyCallback(()->
      begin
        System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(cq)))
      end, tsk, c.ntv, main_dvc, cq{$ifdef EventDebug}, $'cl.ReleaseCommandQueue'{$endif});
      
    end;
    protected function InvokeNewQBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueResBase;
    begin
      var cq := cl_command_queue.Zero;
      Result := InvokeBase(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      FinishAfterNewQ(cq, Result.ev, tsk, c, main_dvc);
    end;
    
    /// Добавление tsk в качестве ключа для всех ожидаемых очередей
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    //ToDo Нет никакой гарантии что Result.ev.abortable будет установлено
    // - Но в нескольких местах, как в FinishAfterNewQ и CLTask.Create, стоит проверка и NotSupportedException
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; override :=
    Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    
    protected function InvokeNewQ(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueRes<T>;
    begin
      var cq := cl_command_queue.Zero;
      Result := Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      FinishAfterNewQ(cq, Result.ev, tsk, c, main_dvc);
    end;
    
  end;
  
{$endregion Base}

{$region Const}

type
  ConstQueue<T> = sealed partial class(CommandQueue<T>, IConstQueue)
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      if prev_ev=nil then prev_ev := new EventList;
      
      if need_ptr_qr then
        Result := new QueueResDelayedPtr<T> (self.res, prev_ev) else
        Result := new QueueResConst<T>      (self.res, prev_ev);
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
  end;
  
{$endregion Const}

{$region WaitMarker}

type
  WaitMarkerBase = abstract partial class(CommandQueueBase)
    private mw_evs := new Dictionary<CLTaskBase, MWEventContainer>;
    
    private procedure RegisterWaiterTask(tsk: CLTaskBase) :=
    lock mw_evs do if not mw_evs.ContainsKey(tsk) then
    begin
      mw_evs[tsk] := new MWEventContainer;
      tsk.WhenDoneBase(tsk->lock mw_evs do mw_evs.Remove(tsk));
    end;
    
    private procedure AddMWHandler(tsk: CLTaskBase; handler: ()->boolean);
    begin
      var cont: MWEventContainer;
      lock mw_evs do cont := mw_evs[tsk];
      cont.AddHandler(handler);
    end;
    
  end;
  
  WaitMarker = sealed partial class(WaitMarkerBase)
    
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; override;
    begin
      {$ifdef DEBUG}
      if need_ptr_qr then raise new System.InvalidOperationException;
      {$endif DEBUG}
      Result := new QueueResConst<object>(nil, prev_ev ?? new EventList);
      Result.ev.AttachCallback(self.SendSignal, tsk, c.ntv, main_dvc, cq{$ifdef EventDebug}, $'ExecuteMWHandlers'{$endif}, false);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
  end;
  
  PseudoWaitMarkerWrapper = sealed class(WaitMarkerBase)
    private org: CommandQueueBase;
    public constructor(org: CommandQueueBase) := self.org := org;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; override :=
    org.InvokeBase(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    org.RegisterWaitables(tsk, prev_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      sb.Append(#9, tabs);
      org.ToStringHeader(sb, index);
      sb += #10;
      
    end;
    
  end;
  PseudoWaitMarker<T> = sealed partial class(CommandQueue<T>)
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := self.q.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      Result.ev.AttachCallback(wrap.SendSignal, tsk, c.ntv, main_dvc, cq{$ifdef EventDebug}, $'ExecuteMWHandlers'{$endif}, false);
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      sb.Append(#9, tabs);
      wrap.ToStringHeader(sb, index);
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
procedure WaitMarkerBase.SendSignal;
begin
  if mw_evs.Count=0 then exit;
  var conts: array of MWEventContainer;
  lock mw_evs do conts := mw_evs.Values.ToArray;
  for var i := 0 to conts.Length-1 do conts[i].ExecuteHandler;
end;

constructor PseudoWaitMarker<T>.Create(q: CommandQueue<T>);
begin
  self.q := q;
  self.wrap := new PseudoWaitMarkerWrapper(self);
end;

function CommandQueueBase.ThenWaitMarkerBase := self.Cast&<object>.ThenWaitMarker.wrap;

{$endregion WaitMarker}

{$region Host}

type
  /// очередь, выполняющая какую то работу на CPU, всегда в отдельном потоке
  HostQueue<TInp,TRes> = abstract class(CommandQueue<TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TInp>; abstract;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; abstract;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TRes>; override;
    begin
      var prev_qr := InvokeSubQs(tsk, c, main_dvc, cq, prev_ev);
      
      var qr := QueueResDelayedBase&<TRes>.MakeNew(need_ptr_qr);
      qr.ev := UserEvent.StartBackgroundWork(prev_qr.ev, ()->qr.SetRes( ExecFunc(prev_qr.GetRes(), c) ), c.ntv, tsk
        {$ifdef EventDebug}, $'body of {self.GetType}'{$endif}
      );
      
      Result := qr;
    end;
    
  end;
  
{$endregion Host}

{$endregion CommandQueue}

{$region CLTask}

type
  CLTaskBase = abstract partial class
    protected mu_res := new Dictionary<MultiusableCommandQueueHubBase, QueueResBase>;
    
    {$region UserEvent's}
    protected user_events := new List<UserEvent>;
    
    protected function MakeUserEvent(c: cl_context{$ifdef EventDebug}; reason: string{$endif}): UserEvent;
    begin
      Result := new UserEvent(c{$ifdef EventDebug}, reason{$endif});
      
      lock user_events do
      begin
        if err_lst.Count<>0 then
          Result.Abort else
          user_events += Result;
      end;
      
    end;
    
    {$endregion UserEvent's}
    
  end;
  
  CLTask<T> = sealed partial class(CLTaskBase)
    
    protected constructor(q: CommandQueue<T>; c: Context);
    begin
      self.q := q;
      self.org_c := c;
      q.RegisterWaitables(self, new HashSet<MultiusableCommandQueueHubBase>);
      
      var cq: cl_command_queue;
      var qr := q.Invoke(self, c, c.MainDevice.ntv, false, cq, nil);
      
      // mu выполняют лишний .Retain, чтобы ивент не удалился пока очередь ещё запускается
      foreach var mu_qr in mu_res.Values do
        mu_qr.ev.Release({$ifdef EventDebug}$'excessive mu ev'{$endif});
      mu_res := nil;
      
      {$ifdef DEBUG}
      //ToDo
//      if (qr.ev.count<>0) and not qr.ev.abortable then raise new NotSupportedException;
      {$endif DEBUG}
      
      //CQ.Invoke всегда выполняет UserEvent.EnsureAbortability, поэтому тут оно не нужно
      qr.ev.AttachFinallyCallback(()->
      begin
        qr.ev.Release({$ifdef EventDebug}$'last ev of CLTask'{$endif});
        if cq<>cl_command_queue.Zero then
          System.Threading.Tasks.Task.Run(()->self.AddErr( cl.ReleaseCommandQueue(cq) ));
        OnQDone(qr);
      end, self, c.ntv, c.MainDevice.ntv, cq{$ifdef EventDebug}, $'CLTask.OnQDone'{$endif});
      
    end;
    
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
    
  end;
  
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
      var qr := q.InvokeBase(self, c, c.MainDevice.ntv, false, cq, nil);
      
      // mu выполняют лишний .Retain, чтобы ивент не удалился пока очередь ещё запускается
      foreach var mu_qr in mu_res.Values do
        mu_qr.ev.Release({$ifdef EventDebug}$'excessive mu ev'{$endif});
      mu_res := nil;
      
      {$ifdef DEBUG}
      if (qr.ev.count<>0) and not qr.ev.abortable then raise new NotSupportedException;
      {$endif DEBUG}
      
      qr.ev.AttachFinallyCallback(()->
      begin
        qr.ev.Release({$ifdef EventDebug}$'last ev of CLTask'{$endif});
        if cq<>cl_command_queue.Zero then
          System.Threading.Tasks.Task.Run(()->self.AddErr( cl.ReleaseCommandQueue(cq) ));
        OnQDone(qr);
      end, self, c.ntv, c.MainDevice.ntv, cq{$ifdef EventDebug}, $'CLTaskResLess.OnQDone'{$endif});
      
    end;
    
    {$region CLTask event's}
    
    protected EvDone := new List<Action<CLTaskBase>>;
    public procedure WhenDoneBase(cb: Action<CLTaskBase>); override :=
    if AddEventHandler(EvDone, cb) then cb(self);
    
    protected EvComplete := new List<Action<CLTaskBase, object>>;
    public procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); override :=
    if AddEventHandler(EvComplete, cb) and (err_lst.Count=0) then cb(self, q_res);
    
    protected EvError := new List<Action<CLTaskBase, array of Exception>>;
    public procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); override :=
    if AddEventHandler(EvError, cb) and (err_lst.Count<>0) then cb(self, GetErrArr);
    
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

procedure CLTaskBase.AddErr(e: Exception) :=
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

static function UserEvent.MakeUserEvent(tsk: CLTaskBase; c: cl_context{$ifdef EventDebug}; reason: string{$endif}) := tsk.MakeUserEvent(c{$ifdef EventDebug}, reason{$endif});

{$endregion CLTask}

{$region Queue converter's}

{$region Cast}

type
  ICastQueue = interface
    function GetQ: CommandQueueBase;
  end;
  CastQueue<T> = sealed class(CommandQueue<T>, ICastQueue)
    private q: CommandQueueBase;
    public function ICastQueue.GetQ := q;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override :=
    q.InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).LazyQuickTransformBase(o->
    try
      Result := T(o);
    except
      on e: Exception do
        tsk.AddErr(e);
    end);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function CommandQueueBase.Cast<T>: CommandQueue<T>;
begin
  var q := self;
  if q is ICastQueue(var cq) then q := cq.GetQ;
  Result :=
    if q is IConstQueue(var cq) then
      new ConstQueue<T>(T(cq.GetConstVal)) else
    if q is CommandQueue<T>(var tcq) then
      tcq else
      new CastQueue<T>(q);
end;

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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(f);
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function CommandQueueBase.ThenConvertBase<TOtp>(f: (object, Context)->TOtp) :=
self.Cast&<object>.ThenConvert(f);

function CommandQueue<T>.ThenConvert<TOtp>(f: (T, Context)->TOtp) :=
new CommandQueueThenConvert<T, TOtp>(self, f);

{$endregion ThenConvert}

{$region +/*}

{$region Simple}

type
  ISimpleQueueArray = interface
    function GetQS: sequence of CommandQueueBase;
  end;
  SimpleQueueArray<T> = abstract class(CommandQueue<T>, ISimpleQueueArray)
    protected qs: array of CommandQueueBase;
    protected last: CommandQueue<T>;
    
    public constructor(params qs: array of CommandQueueBase);
    begin
      self.qs := new CommandQueueBase[qs.Length-1];
      System.Array.Copy(qs, self.qs, qs.Length-1);
      self.last := qs[qs.Length-1].Cast&<T>;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public function GetQS: sequence of CommandQueueBase := qs.Append(last as CommandQueueBase);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      foreach var q in qs do q.RegisterWaitables(tsk, prev_hubs);
      last.RegisterWaitables(tsk, prev_hubs);
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      foreach var q in GetQS do
        q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  ISimpleSyncQueueArray = interface(ISimpleQueueArray) end;
  SimpleSyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleSyncQueueArray)
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      
      for var i := 0 to qs.Length-1 do
        prev_ev := qs[i].InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).ev;
      
      Result := last.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    end;
    
  end;
  
  ISimpleAsyncQueueArray = interface(ISimpleQueueArray) end;
  SimpleAsyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleAsyncQueueArray)
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      if (prev_ev<>nil) and (prev_ev.count<>0) then
        loop qs.Length do prev_ev.Retain({$ifdef EventDebug}$'for all async branches'{$endif});
      var evs := new EventList[qs.Length+1];
      
      for var i := 0 to qs.Length-1 do
        evs[i] := qs[i].InvokeNewQBase(tsk, c, main_dvc, false, prev_ev).ev;
      
      // Используем внешнюю cq, чтобы не создавать лишнюю
      Result := last.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      evs[qs.Length] := Result.ev;
      
      Result := Result.TrySetEv( EventList.Combine(evs, tsk, c.ntv, main_dvc, cq) ?? new EventList );
    end;
    
  end;
  
{$endregion Simple}

{$region Conv}

{$region Generic}

type
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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(f);
      sb += #10;
      foreach var q in qs do
        q.ToString(sb, tabs, index, delayed);
    end;
    
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
      if (prev_ev<>nil) and (prev_ev.count<>0) then loop qs.Length-1 do prev_ev.Retain({$ifdef EventDebug}$'for all async branches'{$endif});
      var qrs := new QueueRes<TInp>[qs.Length];
      var evs := new EventList[qs.Length];
      
      for var i := 0 to qs.Length-2 do
      begin
        var qr := qs[i].InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
        qrs[i] := qr;
        evs[i] := qr.ev;
      end;
      
      // Отдельно, чтобы не создавать лишнюю cq
      var qr := qs[qs.Length-1].Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      qrs[evs.Length-1] := qr;
      evs[evs.Length-1] := qr.ev;
      
      Result := new QueueResFunc<array of TInp>(()->
      begin
        Result := new TInp[qrs.Length];
        for var i := 0 to qrs.Length-1 do
          Result[i] := qrs[i].GetRes;
      end, EventList.Combine(evs, tsk, c.ntv, main_dvc, cq) ?? new EventList);
    end;
    
  end;
  
{$endregion Generic}

{%ConvQueue\AllStaticArrays!ConvQueueStaticArray.pas%}

{$endregion Conv}

{$region Utils}

type
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
        
        if next then
        begin
          if curr is IConstQueue then continue;
          if curr is ICastQueue(var cq) then curr := cq.GetQ;
        end;
        
        if curr is T(var sqa) then
          res.AddRange(sqa.GetQS) else
          res += curr;
        
        if not next then break;
      end;
      
      Result := res.ToArray;
    end;
    
    public static function  FlattenSyncQueueArray(inp: sequence of CommandQueueBase) := FlattenQueueArray&< ISimpleSyncQueueArray>(inp);
    public static function FlattenAsyncQueueArray(inp: sequence of CommandQueueBase) := FlattenQueueArray&<ISimpleAsyncQueueArray>(inp);
    
  end;
  
{$endregion Utils}

function CommandQueueBase. AfterQueueSyncBase(q: CommandQueueBase) := q + self.Cast&<object>;
function CommandQueueBase.AfterQueueAsyncBase(q: CommandQueueBase) := q * self.Cast&<object>;

static function CommandQueue<T>.operator+(q1: CommandQueueBase; q2: CommandQueue<T>) := new  SimpleSyncQueueArray<T>(QueueArrayUtils. FlattenSyncQueueArray(|q1, q2|));
static function CommandQueue<T>.operator*(q1: CommandQueueBase; q2: CommandQueue<T>) := new SimpleAsyncQueueArray<T>(QueueArrayUtils.FlattenAsyncQueueArray(|q1, q2|));

{$endregion +/*}

{$region Multiusable}

type
  MultiusableCommandQueueHub<T> = sealed partial class(MultiusableCommandQueueHubBase)
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
      
      Result.ev.Retain({$ifdef EventDebug}$'for all mu branches'{$endif});
    end;
    
  end;
  
  MultiusableCommandQueueNode<T> = sealed class(CommandQueue<T>)
    public hub: MultiusableCommandQueueHub<T>;
    public constructor(hub: MultiusableCommandQueueHub<T>) := self.hub := hub;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := hub.OnNodeInvoked(tsk, c, main_dvc, need_ptr_qr);
      if prev_ev<>nil then Result := Result.TrySetEv( prev_ev + Result.ev );
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    if prev_hubs.Add(hub) then hub.q.RegisterWaitables(tsk, prev_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      if hub.q.ToStringHeader(sb, index) then
        delayed.Add(hub.q);
      sb += #10;
    end;
    
  end;
  
  MultiusableCommandQueueHub<T> = sealed partial class(MultiusableCommandQueueHubBase)
    
    public function MakeNode: CommandQueue<T> :=
    new MultiusableCommandQueueNode<T>(self);
    
  end;
  
function CommandQueueBase.MultiusableBase := self.Cast&<object>.Multiusable() as object as Func<CommandQueueBase>; //ToDo #2221
function CommandQueue<T>.Multiusable: ()->CommandQueue<T> := MultiusableCommandQueueHub&<T>.Create(self).MakeNode;

{$endregion Multiusable}

{$region Wait}

{$region WCQWaiter}

type
  WCQWaiter = abstract class
    private markers: array of WaitMarkerBase;
    
    public constructor(markers: array of WaitMarkerBase);
    begin
      if markers.Length = 0 then raise new System.ArgumentException($'%Err:0Waitables%');
      for var i := 0 to markers.Length-1 do
        if markers[i] = nil then
          raise new ArgumentNullException($'%Err:Wait(nil)%');
      self.markers := markers;
    end;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure RegisterWaitables(tsk: CLTaskBase) :=
    foreach var marker in markers do marker.RegisterWaiterTask(tsk);
    
    public function GetWaitEv(tsk: CLTaskBase; c: Context): UserEvent; abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb.Append(#9, tabs);
      sb += self.GetType.Name;
      
      if markers.Length=1 then
      begin
        sb += ' => ';
        
        var marker := markers[0];
        if marker.ToStringHeader(sb, index) then
          delayed.Add( marker );
        
        sb += #10;
      end else
      begin
        sb += #10;
        
        foreach var marker in markers.Cast&<CommandQueueBase> do
        begin
          sb.Append(#9, tabs+1);
          if marker.ToStringHeader(sb, index) then
            delayed.Add ( marker );
          sb += #10;
        end;
        
      end;
      
    end;
    
  end;
  
  WCQWaiterAll = sealed class(WCQWaiter)
    
    public function GetWaitEv(tsk: CLTaskBase; c: Context): UserEvent; override;
    begin
      var uev := tsk.MakeUserEvent(c.ntv
        {$ifdef EventDebug}, $'WCQWaiterAll[{waitables.Length}]'{$endif}
      );
      
      var done := 0;
      var total := markers.Length;
      var done_lock := new object;
      
      for var i := 0 to markers.Length-1 do
        markers[i].AddMWHandler(tsk, ()->
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
      var uev := tsk.MakeUserEvent(c.ntv
        {$ifdef EventDebug}, $'WCQWaiterAny[{waitables.Length}]'{$endif}
      );
      
      for var i := 0 to markers.Length-1 do
        markers[i].AddMWHandler(tsk, ()->uev.SetStatus(CommandExecutionStatus.COMPLETE));
      
      Result := uev;
    end;
    
  end;
  
{$endregion WCQWaiter}

{$region ThenWait}

type
  CommandQueueThenWaitFor<T> = sealed class(CommandQueue<T>)
    public q: CommandQueue<T>;
    public waiter: WCQWaiter;
    
    public constructor(q: CommandQueue<T>; waiter: WCQWaiter);
    begin
      self.q := q;
      self.waiter := waiter;
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := q.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      Result := Result.TrySetEv( Result.ev + waiter.GetWaitEv(tsk, c) );
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      q.RegisterWaitables(tsk, prev_hubs);
      waiter.RegisterWaitables(tsk);
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
      waiter.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function CommandQueueBase.ThenWaitForAllBase(markers: sequence of WaitMarkerBase) := self.Cast&<object>.ThenWaitForAll(markers);
function CommandQueueBase.ThenWaitForAnyBase(markers: sequence of WaitMarkerBase) := self.Cast&<object>.ThenWaitForAny(markers);

function CommandQueue<T>.ThenWaitForAll(markers: sequence of WaitMarkerBase) := new CommandQueueThenWaitFor<T>(self, new WCQWaiterAll(markers.ToArray));
function CommandQueue<T>.ThenWaitForAny(markers: sequence of WaitMarkerBase) := new CommandQueueThenWaitFor<T>(self, new WCQWaiterAny(markers.ToArray));

{$endregion ThenWait}

{$region WaitFor}

type
  CommandQueueWaitFor = sealed class(CommandQueue<object>)
    public waiter: WCQWaiter;
    
    public constructor(waiter: WCQWaiter) :=
    self.waiter := waiter;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<object>; override;
    begin
      {$ifdef DEBUG}
      if need_ptr_qr then raise new System.InvalidOperationException;
      {$endif DEBUG}
      var wait_ev := waiter.GetWaitEv(tsk, c);
      Result := new QueueResConst<object>(nil, prev_ev=nil ? wait_ev : prev_ev+wait_ev);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    waiter.RegisterWaitables(tsk);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      waiter.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function WaitForAll(params markers: array of WaitMarkerBase) := WaitForAll(markers.AsEnumerable);
function WaitForAll(    markers: sequence of WaitMarkerBase) := new CommandQueueWaitFor(new WCQWaiterAll(markers.ToArray));

function WaitForAny(params markers: array of WaitMarkerBase) := WaitForAny(markers.AsEnumerable);
function WaitForAny(    markers: sequence of WaitMarkerBase) := new CommandQueueWaitFor(new WCQWaiterAny(markers.ToArray));

function WaitFor(marker: WaitMarkerBase) := WaitForAll(marker);

{$endregion WaitFor}

{$endregion Wait}

{$endregion Queue converter's}

{$region KernelArg}

{$region Base}

type
  ISetableKernelArg = interface
    procedure SetArg(k: cl_kernel; ind: UInt32; c: Context);
  end;
  KernelArg = abstract partial class
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
  end;
  
{$endregion Base}

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

{$region MemorySegment}

type
  KernelArgMemorySegment = sealed class(ConstKernelArg)
    private mem: MemorySegment;
    
    public constructor(mem: MemorySegment) := self.mem := mem;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override :=
    cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), mem.ntv).RaiseIfError;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(mem);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromMemorySegment(mem: MemorySegment) := new KernelArgMemorySegment(mem);

{$endregion MemorySegment}

{$region CLArray}

type
  KernelArgCLArray<T> = sealed class(ConstKernelArg)
  where T: record;
    private a: CLArray<T>;
    
    public constructor(a: CLArray<T>) := self.a := a;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    public procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override :=
    cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), a.ntv).RaiseIfError;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(a);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromCLArray<T>(a: CLArray<T>): KernelArg; where T: record;
begin Result := new KernelArgCLArray<T>(a); end;

{$endregion CLArray}

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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(val^);
      sb += #10;
    end;
    
  end;
  
static function KernelArg.FromRecord<TRecord>(val: TRecord) := new KernelArgRecord<TRecord>(val);

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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(ptr);
      sb += '[';
      sb.Append(sz);
      sb += ']'#10;
    end;
    
  end;
  
static function KernelArg.FromPtr(ptr: IntPtr; sz: UIntPtr) := new KernelArgPtr(ptr, sz);

{$endregion Ptr}

{$endregion Const}

{$region Invokeable}

{$region Base}

type
  InvokeableKernelArg = abstract class(KernelArg) end;
  
{$endregion Base}

{$region MemorySegment}

type
  KernelArgMemorySegmentCQ = sealed class(InvokeableKernelArg)
    public q: CommandQueue<MemorySegment>;
    public constructor(q: CommandQueue<MemorySegment>) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; override :=
    q.InvokeNewQ(tsk, c, main_dvc, false, nil).LazyQuickTransform(mem->new KernelArgMemorySegment(mem) as ISetableKernelArg);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromMemorySegmentCQ(mem_q: CommandQueue<MemorySegment>) :=
new KernelArgMemorySegmentCQ(mem_q);

{$endregion MemorySegment}

{$region CLArray}

type
  KernelArgCLArrayCQ<T> = sealed class(InvokeableKernelArg)
  where T: record;
    public q: CommandQueue<CLArray<T>>;
    public constructor(q: CommandQueue<CLArray<T>>) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id): QueueRes<ISetableKernelArg>; override :=
    q.InvokeNewQ(tsk, c, main_dvc, false, nil).LazyQuickTransform(a->new KernelArgCLArray<T>(a) as ISetableKernelArg);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromCLArrayCQ<T>(a_q: CommandQueue<CLArray<T>>): KernelArg; where T: record;
begin Result := new KernelArgCLArrayCQ<T>(a_q); end;

{$endregion CLArray}

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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromRecordCQ<TRecord>(valq: CommandQueue<TRecord>) :=
new KernelArgRecordCQ<TRecord>(valq);

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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      ptr_q.ToString(sb, tabs, index, delayed);
       sz_q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
static function KernelArg.FromPtrCQ(ptr_q: CommandQueue<IntPtr>; sz_q: CommandQueue<UIntPtr>) :=
new KernelArgPtrCQ(ptr_q, sz_q);

{$endregion Ptr}

{$endregion Invokeable}

{$endregion KernelArg}

{$region GPUCommand}

{$region Base}

type
  GPUCommand<T> = abstract class
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; abstract;
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
    private function DisplayName: string; virtual := CommandQueueBase.DisplayNameForType(self.GetType);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb.Append(#9, tabs);
      sb += DisplayName;
      self.ToStringImpl(sb, tabs+1, index, delayed);
    end;
    
  end;
  
  BasicGPUCommand<T> = abstract class(GPUCommand<T>)
    
    private function DisplayName: string; override;
    begin
      Result := self.GetType.Name;
      Result := Result.Remove(Result.IndexOf('`'));
    end;
    
  end;
  
{$endregion Base}

{$region Queue}

type
  QueueCommand<T> = sealed class(BasicGPUCommand<T>)
    public q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    private function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList) := q.InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).ev;
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := Invoke(tsk, c, main_dvc, cq, prev_ev);
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := Invoke(tsk, c, main_dvc, cq, prev_ev);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
{$endregion Queue}

{$region Proc}

type
  ProcCommand<T> = sealed class(BasicGPUCommand<T>)
    public p: (T,Context)->();
    
    public constructor(p: (T,Context)->()) := self.p := p;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function InvokeObj(o: T; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    UserEvent.StartBackgroundWork(prev_ev, ()->p(o, c), c.ntv, tsk
      {$ifdef EventDebug}, $'const body of {self.GetType}'{$endif}
    );
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override;
    begin
      var o_q_res := o_q().Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      Result := UserEvent.StartBackgroundWork(o_q_res.ev, ()->p(o_q_res.GetRes(), c), c.ntv, tsk
        {$ifdef EventDebug}, $'queue body of {self.GetType}'{$endif}
      );
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(p);
      sb += #10;
    end;
    
  end;
  
{$endregion Proc}

{$region Wait}

type
  WaitCommand<T> = sealed class(BasicGPUCommand<T>)
    public waiter: WCQWaiter;
    
    public constructor(waiter: WCQWaiter) := self.waiter := waiter;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    private function Invoke(tsk: CLTaskBase; c: Context; prev_ev: EventList): EventList;
    begin
      var res := waiter.GetWaitEv(tsk, c);
      Result := if prev_ev=nil then
        res else prev_ev+res;
    end;
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := Invoke(tsk, c, prev_ev);
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override := Invoke(tsk, c, prev_ev);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    waiter.RegisterWaitables(tsk);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      waiter.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
{$endregion Wait}

{$endregion GPUCommand}

{$region GPUCommandContainer}

{$region Base}

type
  GPUCommandContainer<T> = abstract partial class
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
  end;
  GPUCommandContainerCore<T> = abstract class
    private cc: GPUCommandContainer<T>;
    protected constructor(cc: GPUCommandContainer<T>) := self.cc := cc;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>);
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
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override :=
    core.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      core.RegisterWaitables(tsk, prev_hubs);
      foreach var comm in commands do comm.RegisterWaitables(tsk, prev_hubs);
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      core.ToString(sb, tabs, index, delayed);
      foreach var comm in commands do
        comm.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function AddCommand<TContainer, TRes>(cc: TContainer; comm: GPUCommand<TRes>): TContainer; where TContainer: GPUCommandContainer<TRes>;
begin
  cc.commands += comm;
  Result := cc;
end;

{$endregion Base}

{$region Core}

type
  CCCObj<T> = sealed class(GPUCommandContainerCore<T>)
    public o: T;
    
    public constructor(cc: GPUCommandContainer<T>; o: T);
    begin
      inherited Create(cc);
      self.o := o;
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      var res_obj := self.o;
      
      foreach var comm in cc.commands do
        prev_ev := comm.InvokeObj(res_obj, tsk, c, main_dvc, cq, prev_ev);
      
      Result := new QueueResConst<T>(res_obj, prev_ev ?? new EventList);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(o);
      sb += #10;
    end;
    
  end;
  
  CCCQueue<T> = sealed class(GPUCommandContainerCore<T>)
    public hub: MultiusableCommandQueueHub<T>;
    
    public constructor(cc: GPUCommandContainer<T>; q: CommandQueue<T>);
    begin
      inherited Create(cc);
      self.hub := new MultiusableCommandQueueHub<T>(q);
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
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      hub.q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  GPUCommandContainer<T> = abstract partial class
    
    protected constructor(o: T) :=
    self.core := new CCCObj<T>(self, o);
    
    protected constructor(q: CommandQueue<T>) :=
    self.core := new CCCQueue<T>(self, q);
    
  end;
  
{$endregion Core}

{$region Kernel}

type
  KernelCCQ = sealed partial class(GPUCommandContainer<Kernel>)
    
  end;
  
{%ContainerCommon\Kernel\Implementation!ContainerCommon.pas%}

{$endregion Kernel}

{$region MemorySegment}

type
  MemorySegmentCCQ = sealed partial class(GPUCommandContainer<MemorySegment>)
    
  end;
  
static function KernelArg.operator implicit(mem_q: MemorySegmentCCQ): KernelArg := FromMemorySegmentCQ(mem_q);

{%ContainerCommon\MemorySegment\Implementation!ContainerCommon.pas%}

{$endregion MemorySegment}

{$region CLArray}

type
  CLArrayCCQ<T> = sealed partial class(GPUCommandContainer<CLArray<T>>)
    
  end;
  
static function KernelArg.operator implicit<T>(a_q: CLArrayCCQ<T>): KernelArg; where T: record;
begin Result := FromCLArrayCQ(a_q); end;

{%ContainerCommon\CLArray\Implementation!ContainerCommon.pas%}

{$endregion CLArray}

{$endregion GPUCommandContainer}

{$region Enqueueable's}

{$region Core}

type
  IEnqueueable<TInvData> = interface
    
    function NeedThread: boolean;
    
    function ParamCountL1: integer;
    function ParamCountL2: integer;
    
    function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (cl_command_queue, EventList, TInvData)->cl_event;
    
  end;
  EnqueueableCore = static class
    
    private static function MakeEvList(exp_size: integer; start_ev: EventList): List<EventList>;
    begin
      var need_start_ev := (start_ev<>nil) and (start_ev.count<>0);
      Result := new List<EventList>(exp_size + integer(need_start_ev));
      if need_start_ev then Result += start_ev;
    end;
    
    public static function Invoke<TEnq, TInvData>(q: TEnq; inv_data: TInvData; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; l1_start_ev, l2_start_ev: EventList): EventList; where TEnq: IEnqueueable<TInvData>;
    begin
      var need_thread := q.NeedThread;
      
      var evs_l1 := MakeEvList(q.ParamCountL1, l1_start_ev); // Ожидание, перед вызовом  cl.Enqueue*
      var evs_l2 := MakeEvList(q.ParamCountL2, l2_start_ev); // Ожидание, передаваемое в cl.Enqueue*
      
      var enq_f := q.InvokeParams(tsk, c, main_dvc, cq, evs_l1, evs_l2);
      var ev_l1 := EventList.Combine(evs_l1, tsk, c.ntv, main_dvc, cq);
      var ev_l2 := EventList.Combine(evs_l2, tsk, c.ntv, main_dvc, cq) ?? new EventList;
      
      NativeUtils.FixCQ(c.ntv, main_dvc, cq);
      
      if not need_thread and (ev_l1=nil) then
      begin
        var enq_ev := enq_f(cq, ev_l2, inv_data);
        {$ifdef EventDebug}
        EventDebug.RegisterEventRetain(enq_ev, $'Enq by {q.GetType}, waiting on [{ev_l2.evs?.JoinToString}]');
        {$endif EventDebug}
        // 1. ev_l2 можно освобождать только после выполнения команды, ожидающей его
        // 2. Если ивент из ev_l2 завершится с ошибкой - enq_ev скажет только что была ошибка в ev_l2, но не скажет какая
        Result := ev_l2 + enq_ev;
      end else
      begin
        var res_ev: UserEvent;
        
        // Асинхронное Enqueue, придётся пересоздать cq
        var lcq := cq;
        cq := cl_command_queue.Zero;
        
        if need_thread then
          res_ev := UserEvent.StartBackgroundWork(ev_l1, ()->
          begin
            enq_f(lcq, ev_l2, inv_data);
            ev_l2.Release({$ifdef EventDebug}$'after using in blocking enq of {q.GetType}'{$endif});
          end, c.ntv, tsk{$ifdef EventDebug}, $'blocking enq of {q.GetType}, ev_l2 = [{ev_l2.evs?.JoinToString}]'{$endif}) else
        begin
          res_ev := tsk.MakeUserEvent(c.ntv
            {$ifdef EventDebug}, $'{q.GetType}, temp for nested AttachCallback: [{ev_l1?.evs.JoinToString}], then [{ev_l2.evs?.JoinToString}]'{$endif}
          );
          
          //ВНИМАНИЕ "ev_l1=nil" не может случится, из за условий выше
          ev_l1.AttachCallback(()->
          begin
            ev_l1.Release({$ifdef EventDebug}$'after waiting before Enq of {q.GetType}'{$endif});
            var enq_ev := enq_f(lcq, ev_l2, inv_data);
            {$ifdef EventDebug}
            EventDebug.RegisterEventRetain(enq_ev, $'Enq by {q.GetType}, waiting on [{ev_l2.evs?.JoinToString}]');
            {$endif EventDebug}
            var final_ev := ev_l2+enq_ev;
            final_ev.AttachCallback(()->
            begin
              final_ev.Release({$ifdef EventDebug}$'after waiting to set {res_ev.uev} of nested AttachCallback in Enq of {q.GetType}'{$endif});
              res_ev.SetStatus(CommandExecutionStatus.COMPLETE);
            end, tsk, c.ntv, main_dvc, lcq{$ifdef EventDebug}, $'propagating Enq ev of {q.GetType} to res_ev: {res_ev.uev}'{$endif});
          end, tsk, c.ntv, main_dvc, lcq{$ifdef EventDebug}, $'calling Enq of {q.GetType}'{$endif});
          
        end;
        
        EventList.AttachFinallyCallback(res_ev, ()->
        begin
          System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(lcq)));
        end, tsk, false{$ifdef EventDebug}, nil{$endif});
        Result := res_ev;
      end;
      
    end;
    
  end;
  
{$endregion Core}

{$region GPUCommand}

type
  EnqueueableGPUCommandInvData<T> = record
    qr: QueueRes<T>;
    tsk: CLTaskBase;
    c: Context;
  end;
  EnqueueableGPUCommand<T> = abstract class(GPUCommand<T>, IEnqueueable<EnqueueableGPUCommandInvData<T>>)
    
    // Если это True - InvokeParamsImpl должен возращать (...)->cl_event.Zero
    // Иначе останется ивент, который никто не удалил
    public function NeedThread: boolean; virtual := false;
    
    public function ParamCountL1: integer; abstract;
    public function ParamCountL2: integer; abstract;
    
    protected function InvokeParamsImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (T, cl_command_queue, CLTaskBase, Context, EventList)->cl_event; abstract;
    public function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (cl_command_queue, EventList, EnqueueableGPUCommandInvData<T>)->cl_event;
    begin
      var enq_f := InvokeParamsImpl(tsk, c, main_dvc, cq, evs_l1, evs_l2);
      Result := (lcq, ev, data)->enq_f(data.qr.GetRes, lcq, data.tsk, data.c, ev);
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_qr: QueueRes<T>; l2_start_ev: EventList): EventList;
    begin
      var inv_data: EnqueueableGPUCommandInvData<T>;
      inv_data.qr  := prev_qr;
      inv_data.tsk := tsk;
      inv_data.c   := c;
      
      Result := EnqueueableCore.Invoke(self, inv_data, tsk, c, main_dvc, cq, prev_qr.ev, l2_start_ev);
    end;
    
    protected function InvokeObj(o: T; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    Invoke(tsk, c, main_dvc, cq, new QueueResConst<T>(o, nil), prev_ev);
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    Invoke(tsk, c, main_dvc, cq, o_q().Invoke(tsk, c, main_dvc, false, cq, prev_ev), nil);
    
  end;
  
{$endregion GPUCommand}

{$region GetCommand}

type
  EnqueueableGetCommandInvData<TObj, TRes> = record
    prev_qr: QueueRes<TObj>;
    tsk: CLTaskBase;
    res_qr: QueueResDelayedBase<TRes>;
  end;
  EnqueueableGetCommand<TObj, TRes> = abstract class(CommandQueue<TRes>, IEnqueueable<EnqueueableGetCommandInvData<TObj, TRes>>)
    protected prev_commands: GPUCommandContainer<TObj>;
    
    public constructor(prev_commands: GPUCommandContainer<TObj>) :=
    self.prev_commands := prev_commands;
    
    // Если это True - InvokeParamsImpl должен возращать (...)->cl_event.Zero
    // Иначе останется ивент, который никто не удалил
    public function NeedThread: boolean; virtual := false;
    
    public function ParamCountL1: integer; abstract;
    public function ParamCountL2: integer; abstract;
    
    public function ForcePtrQr: boolean; virtual := false;
    
    protected function InvokeParamsImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (TObj, cl_command_queue, CLTaskBase, EventList, QueueResDelayedBase<TRes>)->cl_event; abstract;
    public function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (cl_command_queue, EventList, EnqueueableGetCommandInvData<TObj, TRes>)->cl_event;
    begin
      var enq_f := InvokeParamsImpl(tsk, c, main_dvc, cq, evs_l1, evs_l2);
      Result := (lcq, ev, data)->enq_f(data.prev_qr.GetRes, lcq, data.tsk, ev, data.res_qr);
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TRes>; override;
    begin
      var prev_qr := prev_commands.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      
      var inv_data: EnqueueableGetCommandInvData<TObj, TRes>;
      inv_data.prev_qr  := prev_qr;
      inv_data.tsk      := tsk;
      inv_data.res_qr   := QueueResDelayedBase&<TRes>.MakeNew(need_ptr_qr or ForcePtrQr);
      
      Result := inv_data.res_qr;
      Result.ev := EnqueueableCore.Invoke(self, inv_data, tsk, c, main_dvc, cq, prev_qr.ev, nil);
    end;
    
  end;
  
{$endregion GetCommand}

{$region Kernel}

{$region Implicit}

{%ContainerMethods\Kernel\Implicit.Implementation!MethodGen.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\Kernel\Explicit.Implementation!MethodGen.pas%}

{$endregion Explicit}

{$endregion Kernel}

{$region MemorySegment}

{$region Implicit}

{%ContainerMethods\MemorySegment\Implicit.Implementation!MethodGen.pas%}

{%ContainerMethods\MemorySegment.Get\Implicit.Implementation!GetMethodGen.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\MemorySegment\Explicit.Implementation!MethodGen.pas%}

{%ContainerMethods\MemorySegment.Get\Explicit.Implementation!GetMethodGen.pas%}

{$endregion Explicit}

{$endregion MemorySegment}

{$region CLArray}

{$region Implicit}

{%ContainerMethods\CLArray\Implicit.Implementation!MethodGen.pas%}

{%ContainerMethods\CLArray.Get\Implicit.Implementation!GetMethodGen.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLArray\Explicit.Implementation!MethodGen.pas%}

{%ContainerMethods\CLArray.Get\Explicit.Implementation!GetMethodGen.pas%}

{$endregion Explicit}

{$endregion CLArray}

{$endregion Enqueueable's}

{$region Global subprograms}

{$region HFQ/HPQ}

type
  CommandQueueHostQueueBase<T,TFunc> = abstract class(HostQueue<object,T>)
  where TFunc: Delegate;
    
    private f: TFunc;
    public constructor(f: TFunc) := self.f := f;
    private constructor := raise new InvalidOperationException($'%Err:NoParamCtor%');
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<object>; override :=
    new QueueResConst<Object>(nil, prev_ev ?? new EventList);
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ' => ';
      sb.Append(f);
      sb += #10;
    end;
    
  end;
  
  CommandQueueHostFunc<T> = sealed class(CommandQueueHostQueueBase<T, Context->T>)
    
    protected function ExecFunc(o: object; c: Context): T; override := f(c);
    
  end;
  CommandQueueHostProc = sealed class(CommandQueueHostQueueBase<object, Context->()>)
    
    protected function ExecFunc(o: object; c: Context): object; override;
    begin
      f(c);
      Result := nil;
    end;
    
  end;
  
function HFQ<T>(f: ()->T) :=
new CommandQueueHostFunc<T>(c->f());
function HFQ<T>(f: Context->T) :=
new CommandQueueHostFunc<T>(f);

function HPQ(p: ()->()) :=
new CommandQueueHostProc(c->p());
function HPQ(p: Context->()) :=
new CommandQueueHostProc(p);

{$endregion HFQ/HPQ}

{$region CombineQueue's}

{%Global\CombineQueues\Implementation!CombineQueues.pas%}

{$endregion CombineQueue's}

{$endregion Global subprograms}

end.