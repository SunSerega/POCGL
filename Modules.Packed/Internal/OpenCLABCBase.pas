
//*****************************************************************************************************\\
// Copyright (©) Cergey Latchenko ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\
// Copyright (©) Сергей Латченко ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Этот код распространяется с лицензией Unlicense
// Подробнее в файле LICENSE или тут:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\

/// Модуль для внутренних типов модуля OpenCLABC
unit OpenCLABCBase;

{$region ToDo}

//===================================
// Обязательно сделать до следующего пула:

//ToDo примеры разных KernelArg

//ToDo Удостоверится что в справке сказано про то, что Context.Default только для простого кода. Для профессионального - надо создавать свой контекст

//ToDo Ловить ThreadAbortException всюду перед Exception
// - Даже в колбеках ивентов - их может вызвать синхронно из потока UserEvent.StartBackgroundWork
// - И написать в справке, что любые лямбды пользователя, переданные в этот модуль, могут получить ThreadAbortException

//ToDo Wait очереди:
// - Пока сделал так: если ожидающая очередь абортится - она перестаёт ожидать.
// - Это может создать неопределённое поведение. Но, по моему, это правильней всего.
// - Если так и останется - не забыть добавить в справку

//ToDo Тесты всех фич модуля
//ToDo И в каждом сделать по несколько выполнений, на случай плавающий ошибок

//ToDo IWaitQueue.CancelWait
//ToDo WaitAny(aborter, WaitAll(...));
// - Что случится с WaitAll если aborter будет первым?
// - Очереди переданные в Wait - вообще не запускаются так
// - Поэтому я и думал про что то типа CancelWait

//ToDo Сделать человеческую связь с OpenCL.pas
// - Типы Device и Platform
// - Создание Buffer/Kernel/Context из нативных, с вызовом "cl.Retain*"

//===================================
// Запланированное:

//ToDo Использовать BlittableHelper чтоб выводить хорошие ошибки

//ToDo SubDevice из cl_device_id

//ToDo Потоко-безопастность интерфейса модуля
// - Buffer.Dispose стоит таки за-lock-ать

//ToDo Очереди-маркеры для Wait-очередей
// - чтоб не приходилось использовать константные для этого

//ToDo Очередь-обработчик ошибок
// - .HandleExceptions и какой то аналог try-finally
// - Сделать легко, надо только вставить свой промежуточный CLTaskBase
// - Единственное - для Wait очереди надо хранить так же оригинальный CLTaskBase
//ToDo Раздел справки про обработку ошибок
// - Написать что аналог try-finally стоит использовать на Wait-маркерах для потоко-безопастности

//ToDo cl.SetKernelArg из нескольких потоков одновременно - предусмотреть
// - то есть его надо клонировать

//ToDo Синхронные (с припиской Fast) варианты всего работающего по принципу HostQueue
//ToDo И асинхронные умнее запускать - помнить значение, указывающее можно ли выполнить их синхронно
// - Может даже можно синхронно выполнить "HPQ(...)+HPQ(...)", в некоторых случаях? 

//ToDo Исправить десериализацию ProgramCode

//ToDo CommmandQueueBase.ToString для дебага
// - так же дублирующий protected метод (tabs: integer; index: Dictionary<CommandQueueBase,integer>)

//ToDo ICommandQueue.Cycle(integer)
//ToDo ICommandQueue.Cycle // бесконечность циклов
//ToDo ICommandQueue.CycleWhile(***->boolean)
// - Возможность передать свой обработчик ошибок как Exception->Exception

//ToDo В продолжение Cycle: Однако всё ещё остаётся проблема - как сделать ветвление?
// - И если уже делать - стоит сделать и метод CQ.ThenIf(res->boolean; if_true, if_false: CQ)

//ToDo Read/Write для массивов - надо бы иметь возможность указывать отступ в массиве

//ToDo Сделать методы BufferCommandQueue.AddGet
// - они особенные, потому что возвращают не BufferCommandQueue, а каждый свою очередь
// - полезно, потому что SyncInvoke такой очереди будет возвращать полученное значение

//ToDo Интегрировать профайлинг очередей

//ToDo Запись/чтение безтиповых массивов - всё же стоит удалить NeedThread отовсюду
// - вместо этого надо создавать динамичные методы для каждой размерности массива

//===================================
// Сделать когда-нибуть:

//ToDo У всего, у чего есть .Finalize - проверить чтобы было и .Dispose, если надо
// - и добавить в справку, про то что этот объект можно удалять
// - из .Dispose можно блокировать .Finalize

//ToDo Пройтись по всем функциям OpenCL, посмотреть функционал каких не доступен из OpenCLABC
// - у Kernel.Exec несколько параметров не используются. Стоит использовать
// - clGetKernelWorkGroupInfo - свойства кернела на определённом устройстве

//===================================

//ToDo issue компилятора:
// - #1981
// - #2118
// - #2145
// - #2150
// - #2173

{$endregion ToDo}

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
    private constructor := raise new System.NotSupportedException;
    
    protected procedure GetSizeImpl(id: TInfo; var sz: UIntPtr); abstract;
    protected procedure GetValImpl(id: TInfo; sz: UIntPtr; var res: byte); abstract;
    
    protected function GetSize(id: TInfo): UIntPtr;
    begin GetSizeImpl(id, Result); end;
    
    protected procedure GetVal(id: TInfo; sz: UIntPtr; ptr: IntPtr) :=
    GetValImpl(id, sz, PByte(pointer(ptr))^);
    protected procedure GetVal<T>(id: TInfo; sz: UIntPtr; var res: T) :=
    GetValImpl(id, sz, PByte(pointer(@res))^);
    
    protected function GetVal<T>(id: TInfo): T;
    begin GetVal(id, new UIntPtr(Marshal.SizeOf&<T>), Result); end;
    protected function GetValArr<T>(id: TInfo): array of T;
    begin
      var sz := GetSize(id);
      
      Result := new T[uint64(sz) div Marshal.SizeOf&<T>];
      GetVal(id, sz, Result[0]);
      
    end;
    protected function GetValArrArr<T>(id: TInfo; szs: array of UIntPtr): array of array of T;
    type PT = ^T;
    begin
      
      var res := new IntPtr[szs.Length];
      for var i := 0 to szs.Length-1 do res[i] := Marshal.AllocHGlobal(IntPtr(pointer(szs[i])));
      try
        
        GetVal(id, new UIntPtr(szs.Length*Marshal.SizeOf&<IntPtr>), Result[0]);
        
        SetLength(Result, szs.Length);
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
        GetVal(id, sz, str_ptr);
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
    
    public property Profile:             String read GetString(PlatformInfo.PLATFORM_PROFILE);
    public property Version:             String read GetString(PlatformInfo.PLATFORM_VERSION);
    public property Name:                String read GetString(PlatformInfo.PLATFORM_NAME);
    public property Vendor:              String read GetString(PlatformInfo.PLATFORM_VENDOR);
    public property Extensions:          String read GetString(PlatformInfo.PLATFORM_EXTENSIONS);
    public property HostTimerResolution: UInt64 read GetUInt64(PlatformInfo.PLATFORM_HOST_TIMER_RESOLUTION);
    
  end;
  
  {$endregion Platform}
  
  {$region Device}
  
  DeviceProperties = class(NtvPropertiesBase<cl_device_id, DeviceInfo>)
    
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
    
    public property &Type:                              DeviceType                       read GetDeviceType                (DeviceInfo.DEVICE_TYPE);
    public property VendorId:                           UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_VENDOR_ID);
    public property MaxComputeUnits:                    UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_COMPUTE_UNITS);
    public property MaxWorkItemDimensions:              UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_WORK_ITEM_DIMENSIONS);
    public property MaxWorkItemSizes:                   array of UIntPtr                 read GetUIntPtrArr                (DeviceInfo.DEVICE_MAX_WORK_ITEM_SIZES);
    public property MaxWorkGroupSize:                   UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_MAX_WORK_GROUP_SIZE);
    public property PreferredVectorWidthChar:           UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_CHAR);
    public property PreferredVectorWidthShort:          UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_SHORT);
    public property PreferredVectorWidthInt:            UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_INT);
    public property PreferredVectorWidthLong:           UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_LONG);
    public property PreferredVectorWidthFloat:          UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT);
    public property PreferredVectorWidthDouble:         UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE);
    public property PreferredVectorWidthHalf:           UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_VECTOR_WIDTH_HALF);
    public property NativeVectorWidthChar:              UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_CHAR);
    public property NativeVectorWidthShort:             UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_SHORT);
    public property NativeVectorWidthInt:               UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_INT);
    public property NativeVectorWidthLong:              UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_LONG);
    public property NativeVectorWidthFloat:             UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_FLOAT);
    public property NativeVectorWidthDouble:            UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE);
    public property NativeVectorWidthHalf:              UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_NATIVE_VECTOR_WIDTH_HALF);
    public property MaxClockFrequency:                  UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_CLOCK_FREQUENCY);
    public property AddressBits:                        UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_ADDRESS_BITS);
    public property MaxMemAllocSize:                    UInt64                           read GetUInt64                    (DeviceInfo.DEVICE_MAX_MEM_ALLOC_SIZE);
    public property ImageSupport:                       Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_IMAGE_SUPPORT);
    public property MaxReadImageArgs:                   UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_READ_IMAGE_ARGS);
    public property MaxWriteImageArgs:                  UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_WRITE_IMAGE_ARGS);
    public property MaxReadWriteImageArgs:              UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_READ_WRITE_IMAGE_ARGS);
    public property IlVersion:                          String                           read GetString                    (DeviceInfo.DEVICE_IL_VERSION);
    public property Image2dMaxWidth:                    UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE2D_MAX_WIDTH);
    public property Image2dMaxHeight:                   UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE2D_MAX_HEIGHT);
    public property Image3dMaxWidth:                    UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE3D_MAX_WIDTH);
    public property Image3dMaxHeight:                   UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE3D_MAX_HEIGHT);
    public property Image3dMaxDepth:                    UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE3D_MAX_DEPTH);
    public property ImageMaxBufferSize:                 UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE_MAX_BUFFER_SIZE);
    public property ImageMaxArraySize:                  UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_IMAGE_MAX_ARRAY_SIZE);
    public property MaxSamplers:                        UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_SAMPLERS);
    public property ImagePitchAlignment:                UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_IMAGE_PITCH_ALIGNMENT);
    public property ImageBaseAddressAlignment:          UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_IMAGE_BASE_ADDRESS_ALIGNMENT);
    public property MaxPipeArgs:                        UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_PIPE_ARGS);
    public property PipeMaxActiveReservations:          UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PIPE_MAX_ACTIVE_RESERVATIONS);
    public property PipeMaxPacketSize:                  UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PIPE_MAX_PACKET_SIZE);
    public property MaxParameterSize:                   UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_MAX_PARAMETER_SIZE);
    public property MemBaseAddrAlign:                   UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MEM_BASE_ADDR_ALIGN);
    public property SingleFpConfig:                     DeviceFPConfig                   read GetDeviceFPConfig            (DeviceInfo.DEVICE_SINGLE_FP_CONFIG);
    public property DoubleFpConfig:                     DeviceFPConfig                   read GetDeviceFPConfig            (DeviceInfo.DEVICE_DOUBLE_FP_CONFIG);
    public property GlobalMemCacheType:                 DeviceMemCacheType               read GetDeviceMemCacheType        (DeviceInfo.DEVICE_GLOBAL_MEM_CACHE_TYPE);
    public property GlobalMemCachelineSize:             UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_GLOBAL_MEM_CACHELINE_SIZE);
    public property GlobalMemCacheSize:                 UInt64                           read GetUInt64                    (DeviceInfo.DEVICE_GLOBAL_MEM_CACHE_SIZE);
    public property GlobalMemSize:                      UInt64                           read GetUInt64                    (DeviceInfo.DEVICE_GLOBAL_MEM_SIZE);
    public property MaxConstantBufferSize:              UInt64                           read GetUInt64                    (DeviceInfo.DEVICE_MAX_CONSTANT_BUFFER_SIZE);
    public property MaxConstantArgs:                    UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_CONSTANT_ARGS);
    public property MaxGlobalVariableSize:              UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_MAX_GLOBAL_VARIABLE_SIZE);
    public property GlobalVariablePreferredTotalSize:   UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_GLOBAL_VARIABLE_PREFERRED_TOTAL_SIZE);
    public property LocalMemType:                       DeviceLocalMemType               read GetDeviceLocalMemType        (DeviceInfo.DEVICE_LOCAL_MEM_TYPE);
    public property LocalMemSize:                       UInt64                           read GetUInt64                    (DeviceInfo.DEVICE_LOCAL_MEM_SIZE);
    public property ErrorCorrectionSupport:             Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_ERROR_CORRECTION_SUPPORT);
    public property ProfilingTimerResolution:           UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_PROFILING_TIMER_RESOLUTION);
    public property EndianLittle:                       Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_ENDIAN_LITTLE);
    public property Available:                          Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_AVAILABLE);
    public property CompilerAvailable:                  Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_COMPILER_AVAILABLE);
    public property LinkerAvailable:                    Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_LINKER_AVAILABLE);
    public property ExecutionCapabilities:              DeviceExecCapabilities           read GetDeviceExecCapabilities    (DeviceInfo.DEVICE_EXECUTION_CAPABILITIES);
    public property QueueOnHostProperties:              CommandQueueProperties           read GetCommandQueueProperties    (DeviceInfo.DEVICE_QUEUE_ON_HOST_PROPERTIES);
    public property QueueOnDeviceProperties:            CommandQueueProperties           read GetCommandQueueProperties    (DeviceInfo.DEVICE_QUEUE_ON_DEVICE_PROPERTIES);
    public property QueueOnDevicePreferredSize:         UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_QUEUE_ON_DEVICE_PREFERRED_SIZE);
    public property QueueOnDeviceMaxSize:               UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_QUEUE_ON_DEVICE_MAX_SIZE);
    public property MaxOnDeviceQueues:                  UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_ON_DEVICE_QUEUES);
    public property MaxOnDeviceEvents:                  UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_ON_DEVICE_EVENTS);
    public property BuiltInKernels:                     String                           read GetString                    (DeviceInfo.DEVICE_BUILT_IN_KERNELS);
    public property Name:                               String                           read GetString                    (DeviceInfo.DEVICE_NAME);
    public property Vendor:                             String                           read GetString                    (DeviceInfo.DEVICE_VENDOR);
    public property Profile:                            String                           read GetString                    (DeviceInfo.DEVICE_PROFILE);
    public property Version:                            String                           read GetString                    (DeviceInfo.DEVICE_VERSION);
    public property OpenclCVersion:                     String                           read GetString                    (DeviceInfo.DEVICE_OPENCL_C_VERSION);
    public property Extensions:                         String                           read GetString                    (DeviceInfo.DEVICE_EXTENSIONS);
    public property PrintfBufferSize:                   UIntPtr                          read GetUIntPtr                   (DeviceInfo.DEVICE_PRINTF_BUFFER_SIZE);
    public property PreferredInteropUserSync:           Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_PREFERRED_INTEROP_USER_SYNC);
    public property PartitionMaxSubDevices:             UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PARTITION_MAX_SUB_DEVICES);
    public property PartitionProperties:                array of DevicePartitionProperty read GetDevicePartitionPropertyArr(DeviceInfo.DEVICE_PARTITION_PROPERTIES);
    public property PartitionAffinityDomain:            DeviceAffinityDomain             read GetDeviceAffinityDomain      (DeviceInfo.DEVICE_PARTITION_AFFINITY_DOMAIN);
    public property PartitionType:                      array of DevicePartitionProperty read GetDevicePartitionPropertyArr(DeviceInfo.DEVICE_PARTITION_TYPE);
    public property ReferenceCount:                     UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_REFERENCE_COUNT);
    public property SvmCapabilities:                    DeviceSVMCapabilities            read GetDeviceSVMCapabilities     (DeviceInfo.DEVICE_SVM_CAPABILITIES);
    public property PreferredPlatformAtomicAlignment:   UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_PLATFORM_ATOMIC_ALIGNMENT);
    public property PreferredGlobalAtomicAlignment:     UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_GLOBAL_ATOMIC_ALIGNMENT);
    public property PreferredLocalAtomicAlignment:      UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_PREFERRED_LOCAL_ATOMIC_ALIGNMENT);
    public property MaxNumSubGroups:                    UInt32                           read GetUInt32                    (DeviceInfo.DEVICE_MAX_NUM_SUB_GROUPS);
    public property SubGroupIndependentForwardProgress: Boolean                          read GetBoolean                   (DeviceInfo.DEVICE_SUB_GROUP_INDEPENDENT_FORWARD_PROGRESS);
    
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
    
    public property ReferenceCount: UInt32                     read GetUInt32              (ContextInfo.CONTEXT_REFERENCE_COUNT);
    public property NumDevices:     UInt32                     read GetUInt32              (ContextInfo.CONTEXT_NUM_DEVICES);
    public property Properties:     array of ContextProperties read GetContextPropertiesArr(ContextInfo.CONTEXT_PROPERTIES);
    
  end;
  
  {$endregion Context}
  
  {$region Buffer}
  
  BufferProperties = class(NtvPropertiesBase<cl_mem, MemInfo>)
    
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
    
    public property &Type:          MemObjectType read GetMemObjectType(MemInfo.MEM_TYPE);
    public property Flags:          MemFlags      read GetMemFlags     (MemInfo.MEM_FLAGS);
    public property Size:           UIntPtr       read GetUIntPtr      (MemInfo.MEM_SIZE);
    public property HostPtr:        IntPtr        read GetIntPtr       (MemInfo.MEM_HOST_PTR);
    public property MapCount:       UInt32        read GetUInt32       (MemInfo.MEM_MAP_COUNT);
    public property ReferenceCount: UInt32        read GetUInt32       (MemInfo.MEM_REFERENCE_COUNT);
    public property UsesSvmPointer: Boolean       read GetBoolean      (MemInfo.MEM_USES_SVM_POINTER);
    public property Offset:         UIntPtr       read GetUIntPtr      (MemInfo.MEM_OFFSET);
    
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
    
    public property FunctionName:   String read GetString(KernelInfo.KERNEL_FUNCTION_NAME);
    public property NumArgs:        UInt32 read GetUInt32(KernelInfo.KERNEL_NUM_ARGS);
    public property ReferenceCount: UInt32 read GetUInt32(KernelInfo.KERNEL_REFERENCE_COUNT);
    public property Attributes:     String read GetString(KernelInfo.KERNEL_ATTRIBUTES);
    
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
    
    public property ReferenceCount:          UInt32                 read GetUInt32    (ProgramInfo.PROGRAM_REFERENCE_COUNT);
    public property Source:                  String                 read GetString    (ProgramInfo.PROGRAM_SOURCE);
    public property Il:                      array of Byte          read GetByteArr   (ProgramInfo.PROGRAM_IL);
    public property BinarySizes:             array of UIntPtr       read GetUIntPtrArr(ProgramInfo.PROGRAM_BINARY_SIZES);
    public property Binaries:                array of array of Byte read GetByteArrArr(ProgramInfo.PROGRAM_BINARIES, BinarySizes);
    public property NumKernels:              UIntPtr                read GetUIntPtr   (ProgramInfo.PROGRAM_NUM_KERNELS);
    public property KernelNames:             String                 read GetString    (ProgramInfo.PROGRAM_KERNEL_NAMES);
    public property ScopeGlobalCtorsPresent: Boolean                read GetBoolean   (ProgramInfo.PROGRAM_SCOPE_GLOBAL_CTORS_PRESENT);
    public property ScopeGlobalDtorsPresent: Boolean                read GetBoolean   (ProgramInfo.PROGRAM_SCOPE_GLOBAL_DTORS_PRESENT);
    
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
    protected function CreateProp: TProp; abstract;
    
    ///--
    public function Equals(obj: object): boolean; override :=
    (obj is WrapperBase<TNtv, TProp>(var wr)) and (self.ntv=wr.ntv);
    
  end;
  
  {$endregion Base}
  
  {$region Platform}
  
  Platform = sealed class(WrapperBase<cl_platform_id, PlatformProperties>)
    protected function CreateProp: PlatformProperties; override := new PlatformProperties(ntv);
    
    public property Native: cl_platform_id read ntv;
    public property Properties: PlatformProperties read GetProperties;
    
    {$region constructor's}
    
    public constructor(pl: cl_platform_id) :=
    self.ntv := pl;
    private constructor := raise new System.NotSupportedException;
    
    private static _all: IList<Platform>;
    static constructor;
    begin
      var c: UInt32;
      cl.GetPlatformIDs(0, IntPtr.Zero, c).RaiseIfError;
      
      var all := new cl_platform_id[c];
      cl.GetPlatformIDs(c, all[0], IntPtr.Zero).RaiseIfError;
      
      _all := new ReadOnlyCollection<Platform>(all.ConvertAll(pl->new Platform(pl)));
    end;
    public static property All: IList<Platform> read _all;
    
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
  
  Device = class(WrapperBase<cl_device_id, DeviceProperties>)
    protected function CreateProp: DeviceProperties; override := new DeviceProperties(ntv);
    
    public property Native: cl_device_id read ntv;
    public property Properties: DeviceProperties read GetProperties;
    
    public property BasePlatform: Platform read new Platform(Properties.GetVal&<cl_platform_id>(DeviceInfo.DEVICE_PLATFORM));
    
    {$region constructor's}
    
    public constructor(dvc: cl_device_id) :=
    self.ntv := dvc;
    private constructor := raise new System.NotSupportedException;
    
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
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(dvc1, dvc2: Device): boolean := dvc1.ntv = dvc2.ntv;
    public static function operator<>(dvc1, dvc2: Device): boolean := dvc1.ntv <> dvc2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}]';
    
    {$endregion operator's}
    
  end;
  SubDevice = class(Device)
    private _parent: Device;
    public property Parent: Device read _parent;
    
    {$region constructor's}
    
    private constructor(dvc: cl_device_id; parent: Device);
    begin
      inherited Create(dvc);
      self._parent := parent;
    end;
    private constructor := inherited;
    
    private static function Split(dvc: Device; props: array of DevicePartitionProperty): array of SubDevice;
    begin
      
      var c: UInt32;
      cl.CreateSubDevices(dvc.Native, props, 0, IntPtr.Zero, c).RaiseIfError;
      
      var res := new cl_device_id[int64(c)];
      cl.CreateSubDevices(dvc.Native, props, c, res[0], IntPtr.Zero).RaiseIfError;
      
      Result := res.ConvertAll(sdvc->new SubDevice(sdvc, dvc));
    end;
    
    public static function SplitEqually(dvc: Device; CUCount: integer) :=
    Split(dvc,
      new DevicePartitionProperty[3](
        DevicePartitionProperty.DEVICE_PARTITION_EQUALLY,
        DevicePartitionProperty.Create(CUCount),
        DevicePartitionProperty.Create(0)
      )
    );
    
    public static function SplitByCounts(dvc: Device; params CUCounts: array of integer): array of SubDevice;
    begin
      for var i := 0 to CUCounts.Length-1 do
        if CUCounts[i]<=0 then
          raise new ArgumentException($'');
      
      var props := new DevicePartitionProperty[CUCounts.Length+2];
      props[0] := DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS;
      for var i := 0 to CUCounts.Length-1 do
        props[i+1] := new DevicePartitionProperty(CUCounts[i]);
      props[props.Length-1] := DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS_LIST_END;
      
      Result := Split(dvc, props);
    end;
    
    public static function SplitByAffinityDomain(dvc: Device; affinity_domain: DeviceAffinityDomain) :=
    Split(dvc,
      new DevicePartitionProperty[3](
        DevicePartitionProperty.DEVICE_PARTITION_EQUALLY,
        DevicePartitionProperty.Create(new IntPtr(affinity_domain.val)),
        DevicePartitionProperty.Create(0)
      )
    );
    
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
  ///Представляет контекст для хранения данных и выполнения команд на GPU
  Context = sealed class(WrapperBase<cl_context, ContextProperties>)
    private dvcs: IList<Device>;
    private main_dvc: Device;
    
    protected function CreateProp: ContextProperties; override := new ContextProperties(ntv);
    
    public property Native:     cl_context    read ntv;
    public property AllDevices: IList<Device> read dvcs;
    public property MainDevice: Device        read main_dvc;
    
    public property Properties: ContextProperties read GetProperties;
    
    public function GetAllNtvDevices: array of cl_device_id;
    begin
      Result := new cl_device_id[dvcs.Count];
      for var i := 0 to Result.Length-1 do
        Result[i] := dvcs[i].Native;
    end;
    
    {$region constructor's}
    
    ///Один любой GPU, если такой имеется
    ///Одно любое другое устройство, поддерживающее OpenCL, если GPU отсутствует
    ///
    ///Если устройств поддерживающих OpenCL нет - возвращает nil
    ///Обычно это свидетельствует об устаревших или неправильно установленных драйверах
    public static auto property &Default: Context;
    static constructor;
    begin
      var pls := Platform.All;
      if pls=nil then exit;
      
      foreach var pl in pls do
      begin
        var dvcs := Device.GetAllFor(pl) ?? Device.GetAllFor(pl, DeviceType.DEVICE_TYPE_ALL);
        if dvcs=nil then continue;
        
        Context.Default := new Context(dvcs);
        
      end;
      
    end;
    
    public constructor(dvcs: IList<Device>; main_dvc: Device);
    begin
      if not dvcs.Contains(main_dvc) then raise new InvalidOperationException($'');
      
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
    private constructor(ntv: cl_context; dvcs: IList<Device>; main_dvc: Device);
    begin
      if not dvcs.Contains(main_dvc) then raise new InvalidOperationException($'');
      cl.RetainContext(ntv).RaiseIfError;
      self.ntv := ntv;
      self.dvcs := new ReadOnlyCollection<Device>(dvcs);
      self.main_dvc := main_dvc;
    end;
    public constructor(ntv: cl_context; params dvcs: array of Device) := Create(ntv, dvcs, dvcs[0]);
    public constructor(ntv: cl_context; main_dvc: Device) := Create(ntv, GetContextDevices(ntv), main_dvc);
    public constructor(ntv: cl_context) := Create(ntv, GetContextDevices(ntv));
    
    public function MakeSibling(dvc: Device) := new Context(self.ntv, self.dvcs, dvc);
    
    private constructor := raise new System.NotSupportedException;
    
    protected procedure Finalize; override :=
    cl.ReleaseContext(ntv).RaiseIfError;
    
    {$endregion constructor's}
    
    {$region operator's}
    
    public static function operator=(c1, c2: Context): boolean := c1.ntv = c2.ntv;
    public static function operator<>(c1, c2: Context): boolean := c1.ntv <> c2.ntv;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}[{ntv.val}] on devices: {AllDevices.JoinToString('', '')}; Main device: {MainDevice}';
    
    {$endregion operator's}
    
    {$region Invoke}
    
    ///Запускает данную очередь и все её подочереди
    ///Как только всё запущено: возвращает объект типа CLTask<>, через который можно следить за процессом выполнения
    public function BeginInvoke<T>(q: CommandQueue<T>): CLTask<T>;
    ///Запускает данную очередь и все её подочереди
    ///Как только всё запущено: возвращает объект типа CLTask<>, через который можно следить за процессом выполнения
    public function BeginInvoke(q: CommandQueueBase): CLTaskBase;
    
    ///Запускает данную очередь и все её подочереди
    ///Затем ожидает окончания выполнения и возвращает полученный результат
    public function SyncInvoke<T>(q: CommandQueue<T>): T;
    ///Запускает данную очередь и все её подочереди
    ///Затем ожидает окончания выполнения и возвращает полученный результат
    public function SyncInvoke(q: CommandQueueBase): Object;
    
    {$endregion Invoke}
    
  end;
  
  {$endregion Context}
  
  {$region Buffer}
  
  BufferCommandQueue = class;
  KernelArg = class;
  ///Представляет область памяти GPU
  Buffer = class(WrapperBase<cl_mem, BufferProperties>, IDisposable)
    private sz: UIntPtr;
    
    public property Native: cl_mem read ntv;
    
    protected function CreateProp: BufferProperties; override;
    begin
      if ntv=cl_mem.Zero then raise new InvalidOperationException($'');
      Result := new BufferProperties(ntv);
    end;
    public property Properties: BufferProperties read GetProperties;
    
    ///Возвращает размер буфера в байтах
    public property Size: UIntPtr read sz;
    ///Возвращает размер буфера в байтах
    public property Size32: UInt32 read sz.ToUInt32;
    ///Возвращает размер буфера в байтах
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
    
    protected constructor(ntv: cl_mem; sz: UIntPtr; retain: boolean);
    begin
      cl.RetainMemObject(ntv).RaiseIfError;
      self.ntv := ntv;
      self.sz := sz;
    end;
    protected static function GetBuffSize(ntv: cl_mem): UIntPtr;
    begin cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(Marshal.SizeOf&<UIntPtr>), Result, IntPtr.Zero).RaiseIfError; end;
    public constructor(ntv: cl_mem) := Create(ntv, GetBuffSize(ntv), true);
    
    private constructor := raise new System.NotSupportedException;
    
    ///Выделяет память на устройстве, указанном в контексте
    ///Если память уже была выделена, то она освобождается и выделяется заново
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
    
    public procedure Dispose :=
    if ntv<>cl_mem.Zero then lock self do
    begin
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
    
    public static function operator implicit(b: Buffer): CommandQueue<KernelArg>;
    
    {$endregion operator's}
    
    {$region 1#Write&Read}
    
    ///- function WriteData(ptr: IntPtr): Buffer;
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function WriteData(ptr: CommandQueue<IntPtr>): Buffer;
    
    ///- function ReadData(ptr: IntPtr): Buffer;
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function ReadData(ptr: CommandQueue<IntPtr>): Buffer;
    
    public function WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    public function ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function WriteData(ptr: pointer): Buffer;
    
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function ReadData(ptr: pointer): Buffer;
    
    public function WriteData(ptr: pointer; offset, len: CommandQueue<integer>): Buffer;
    
    public function ReadData(ptr: pointer; offset, len: CommandQueue<integer>): Buffer;
    
    public function WriteValue<TRecord>(val: TRecord): Buffer;where TRecord: record;
    
    public function WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteValue<TRecord>(val: CommandQueue<TRecord>): Buffer;where TRecord: record;
    
    public function WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteArray1<TRecord>(a: CommandQueue<array of TRecord>): Buffer;where TRecord: record;
    
    public function WriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): Buffer;where TRecord: record;
    
    public function WriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): Buffer;where TRecord: record;
    
    public function ReadArray1<TRecord>(a: CommandQueue<array of TRecord>): Buffer;where TRecord: record;
    
    public function ReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): Buffer;where TRecord: record;
    
    public function ReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): Buffer;where TRecord: record;
    
    public function WriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function ReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function ReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function ReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function WriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function ReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function ReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): Buffer;where TRecord: record;
    
    public function ReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): Buffer;where TRecord: record;
    
    {$endregion 1#Write&Read}
    
    {$region 2#Fill}
    
    {$endregion 2#Fill}
    
    {$region 3#Copy}
    
    {$endregion 3#Copy}
    
    {$region}
    (**
    
    {$region Write}
    
    ///- function WriteData(ptr: IntPtr): Buffer;
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function WriteData(ptr: CommandQueue<IntPtr>): Buffer;
    public function WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function WriteData(ptr: pointer) := WriteData(IntPtr(ptr));
    public function WriteData(ptr: pointer; offset, len: CommandQueue<integer>) := WriteData(IntPtr(ptr), offset, len);
    
    
    ///- function WriteArray(a: Array): Buffer;
    ///Копирует данные из содержимого массива в память буфера
    public function WriteArray(a: CommandQueue<&Array>): Buffer;
    public function WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function WriteArray(a: Array): Buffer;
    ///Копирует данные из содержимого массива в память буфера
    public function WriteArray(a: &Array) := WriteArray(CommandQueue&<&Array>(a));
    public function WriteArray(a: &Array; offset, len: CommandQueue<integer>) := WriteArray(CommandQueue&<&Array>(a), offset, len);
    
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    begin Result := WriteData(@val, offset, Marshal.SizeOf&<TRecord>); end;
    
    public function WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    
    {$endregion Write}
    
    {$region Read}
    
    ///- function ReadData(ptr: IntPtr): Buffer;
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function ReadData(ptr: CommandQueue<IntPtr>): Buffer;
    public function ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function ReadData(ptr: pointer) := ReadData(IntPtr(ptr));
    public function ReadData(ptr: pointer; offset, len: CommandQueue<integer>) := ReadData(IntPtr(ptr), offset, len);
    
    ///- function ReadArray(a: Array): Buffer;
    ///Копирует данные из памяти буфера в содержимое массива
    public function ReadArray(a: CommandQueue<&Array>): Buffer;
    public function ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function ReadArray(a: Array): Buffer;
    ///Копирует данные из памяти буфера в содержимое массива
    public function ReadArray(a: &Array) := ReadArray(CommandQueue&<&Array>(a));
    public function ReadArray(a: &Array; offset, len: CommandQueue<integer>) := ReadArray(CommandQueue&<&Array>(a), offset, len);
    
    public function ReadValue<TRecord>(var val: TRecord; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    begin
      Result := ReadData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Read}
    
    {$region Fill}
    
    public function FillData(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>): Buffer;
    public function FillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>): Buffer;
    
    public function FillData(ptr: pointer; pattern_len: CommandQueue<integer>) := FillData(IntPtr(ptr), pattern_len);
    public function FillData(ptr: pointer; pattern_len, offset, len: CommandQueue<integer>) := FillData(IntPtr(ptr), pattern_len, offset, len);
    
    ///- function ReadArray(a: Array): Buffer;
    ///Заполняет буфер копиями содержимого массива
    public function FillArray(a: CommandQueue<&Array>): Buffer;
    public function FillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function ReadArray(a: Array): Buffer;
    ///Заполняет буфер копиями содержимого массива
    public function FillArray(a: &Array) := FillArray(CommandQueue&<&Array>(a));
    public function FillArray(a: &Array; offset, len: CommandQueue<integer>) := FillArray(CommandQueue&<&Array>(a), offset, len);
    
    ///- function FillValue(val: TRecord): Buffer;
    ///Заполняет буфер копиями значения val
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function FillValue<TRecord>(val: TRecord): Buffer; where TRecord: record;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function FillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): Buffer; where TRecord: record;
    
    ///- function FillValue(val: TRecord): Buffer;
    ///Заполняет буфер копиями значения val
    public function FillValue<TRecord>(val: CommandQueue<TRecord>): Buffer; where TRecord: record;
    public function FillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>): Buffer; where TRecord: record;
    
    {$endregion Fill}
    
    {$region Copy}
    
    public function CopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): Buffer;
    public function CopyTo  (b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): Buffer;
    
    ///- function CopyFrom(b: Buffer): Buffer;
    ///Копирует память из буфера b в текущий
    public function CopyFrom(b: CommandQueue<Buffer>): Buffer;
    ///- function CopyTo(b: Buffer): Buffer;
    ///Копирует память из текущего буфера в b
    public function CopyTo  (b: CommandQueue<Buffer>): Buffer;
    
    {$endregion Copy}
    
    {$region Get}
    
    public function GetData(offset, len: CommandQueue<integer>): IntPtr;
    public function GetData := GetData(0,integer(self.Size32));
    
    
    
    public function GetArrayAt<TArray>(offset: CommandQueue<integer>; szs: CommandQueue<array of integer>): TArray; where TArray: &Array;
    ///- function GetArray(szs: array of integer): TArray;
    ///Создаёт новый массив указанного типа с размерами (исчисляемых в элементах, НЕ байтах) szs и копирует в него содержимое буфера
    public function GetArray<TArray>(szs: CommandQueue<array of integer>): TArray; where TArray: &Array;
    begin Result := GetArrayAt&<TArray>(0, szs); end;
    
    public function GetArrayAt<TArray>(offset: CommandQueue<integer>; params szs: array of CommandQueue<integer>): TArray; where TArray: &Array;
    ///- function GetArray(szs: array of integer): TArray;
    ///Создаёт новый массив указанного типа с размерами (исчисляемых в элементах, НЕ байтах) szs и копирует в него содержимое буфера
    public function GetArray<TArray>(params szs: array of integer): TArray; where TArray: &Array;
    begin Result := GetArrayAt&<TArray>(0, CommandQueue&<array of integer>(szs)); end;
    
    
    public function GetArray1At<TRecord>(offset, length: CommandQueue<integer>): array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(offset, length); end;
    ///- function GetArray1(length: integer): array of TRecord;
    ///Создаёт новый массив длиной в length элементов и копирует в него содержимое буфера
    public function GetArray1<TRecord>(length: CommandQueue<integer>): array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(0,length); end;
    
    public function GetArray1<TRecord>: array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(0, integer(sz.ToUInt32) div Marshal.SizeOf&<TRecord>); end;
    
    
    public function GetArray2At<TRecord>(offset, length1, length2: CommandQueue<integer>): array[,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,] of TRecord>(offset, length1, length2); end;
    public function GetArray2<TRecord>(length1, length2: CommandQueue<integer>): array[,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,] of TRecord>(0, length1, length2); end;
    
    
    public function GetArray3At<TRecord>(offset, length1, length2, length3: CommandQueue<integer>): array[,,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,,] of TRecord>(offset, length1, length2, length3); end;
    public function GetArray3<TRecord>(length1, length2, length3: CommandQueue<integer>): array[,,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,,] of TRecord>(0, length1, length2, length3); end;
    
    
    
    ///- function GetValueAt(offset: integer): TRecord;
    ///Читает из буфера значение указанного размерного типа
    ///offset указывает отступ в буфере в байтах
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function GetValueAt<TRecord>(offset: CommandQueue<integer>): TRecord; where TRecord: record;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function GetValue<TRecord>: TRecord; where TRecord: record;
    begin Result := GetValueAt&<TRecord>(0); end;
    
    {$endregion Get}
    
    (**)
    {$endregion}
    
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
    
    protected static function MakeSubBuff(parent: Buffer; reg: cl_buffer_region): cl_mem;
    begin
      var parent_ntv := parent.Native;
      if parent_ntv=cl_mem.Zero then raise new InvalidOperationException($'');
      
      var ec: ErrorCode;
      Result := cl.CreateSubBuffer(parent_ntv, MemFlags.MEM_READ_WRITE, BufferCreateType.BUFFER_CREATE_TYPE_REGION, reg, ec);
      ec.RaiseIfError;
      
    end;
    
    protected constructor(parent: Buffer; reg: cl_buffer_region);
    begin
      inherited Create(MakeSubBuff(parent, reg), reg.size, false);
      self._parent := parent;
    end;
    public constructor(parent: Buffer; origin, size: UIntPtr) := Create(parent, new cl_buffer_region(origin, size));
    
    public constructor(parent: Buffer; origin, size: UInt32) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    public constructor(parent: Buffer; origin, size: UInt64) := Create(parent, new UIntPtr(origin), new UIntPtr(size));
    
    public procedure Init(c: Context); override := raise new NotSupportedException($'');
    
    {$endregion constructor's}
    
  end;
  
  {$endregion Buffer}
  
  {$region Kernel}
  
  KernelCommandQueue = class;
  ///Представляет подпрограмму-kernel, выполняемую на GPU
  Kernel = sealed class(WrapperBase<cl_kernel, KernelProperties>)
    protected function CreateProp: KernelProperties; override := new KernelProperties(ntv);
    
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
      if retain then cl.RetainKernel(ntv).RaiseIfError;
      self.ntv := ntv;
      cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, new UIntPtr(cl_program.Size), self._prog, IntPtr.Zero).RaiseIfError;
      
      var sz: UIntPtr;
      cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, UIntPtr.Zero, nil, sz).RaiseIfError;
      
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, sz, str_ptr, IntPtr.Zero).RaiseIfError;
        self._name := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
    end;
    
    private constructor := raise new System.NotSupportedException;
    
    protected procedure Finalize; override :=
    cl.ReleaseKernel(ntv).RaiseIfError;
    
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
      try
        p( owned ? ntv : MakeNewNtv );
      finally
        if owned then Monitor.Exit(exclusive_ntv_lock);
      end;
    end;
    public function UseExclusiveNative<T>(f: cl_kernel->T): T;
    begin
      var owned := Monitor.TryEnter(exclusive_ntv_lock);
      try
        Result := f( owned ? ntv : MakeNewNtv );
      finally
        if owned then Monitor.Exit(exclusive_ntv_lock);
      end;
    end;
    
    {$endregion UseExclusiveNative}
    
    {$region 1#Exec}
    
    {$endregion 1#Exec}
    
    {$region}
    (**
    
    {$region Exec}
    
    public function Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>): Kernel;
    public function Exec(work_szs: array of integer; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function Exec1(work_sz1: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1), args);
    public function Exec1(work_sz1: integer; params args: array of CommandQueue<Buffer>) := Exec1(new UIntPtr(work_sz1), args);
    
    public function Exec2(work_sz1, work_sz2: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1, work_sz2), args);
    public function Exec2(work_sz1, work_sz2: integer; params args: array of CommandQueue<Buffer>) := Exec2(new UIntPtr(work_sz1), new UIntPtr(work_sz2), args);
    
    public function Exec3(work_sz1, work_sz2, work_sz3: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1, work_sz2, work_sz3), args);
    public function Exec3(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<Buffer>) := Exec3(new UIntPtr(work_sz1), new UIntPtr(work_sz2), new UIntPtr(work_sz3), args);
    
    
    public function Exec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>): Kernel;
    public function Exec(work_szs: array of CommandQueue<integer>; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz_q->sz_q.ThenConvert(sz->new UIntPtr(sz))), args);
    
    public function Exec1(work_sz1: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1), args);
    public function Exec1(work_sz1: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec1(work_sz1.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function Exec2(work_sz1, work_sz2: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2), args);
    public function Exec2(work_sz1, work_sz2: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec2(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function Exec3(work_sz1, work_sz2, work_sz3: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2, work_sz3), args);
    public function Exec3(work_sz1, work_sz2, work_sz3: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec3(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), work_sz3.ThenConvert(sz->new UIntPtr(sz)), args);
    
    
    public function Exec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>): Kernel;
    public function Exec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>): Kernel;
    
    {$endregion Exec}
    (**)
    
    {$endregion}
    
  end;
  
  {$endregion Kernel}
  
  {$region ProgramCode}
  
  ///Представляет контейнер для прекомпилированного кода для GPU
  ProgramCode = sealed class(WrapperBase<cl_program, ProgramProperties>)
    protected function CreateProp: ProgramProperties; override := new ProgramProperties(ntv);
    
    public property Native: cl_program read ntv;
    public property Properties: ProgramProperties read GetProperties;
    
    protected _c: Context;
    public property BaseContext: Context read _c;
    
    {$region constructor's}
    
    public constructor(c: Context; params files_texts: array of string);
    begin
      var ec: ErrorCode;
      
      self.ntv := cl.CreateProgramWithSource(c.Native, files_texts.Length, files_texts, nil, ec);
      ec.RaiseIfError;
      
      ec := cl.BuildProgram(self.ntv, c.dvcs.Count,c.GetAllNtvDevices, nil, nil,IntPtr.Zero);
      if ec=ErrorCode.BUILD_PROGRAM_FAILURE then
      begin
        var sb := new StringBuilder($'');
        
        foreach var dvc in c.AllDevices do
        begin
          sb += #10#10;
          sb += dvc.ToString;
          sb += ':'#10;
          
          var sz: UIntPtr;
          cl.GetProgramBuildInfo(self.ntv, dvc.Native, ProgramBuildInfo.PROGRAM_BUILD_LOG, UIntPtr.Zero,IntPtr.Zero,sz).RaiseIfError;
          
          var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
          cl.GetProgramBuildInfo(self.ntv, dvc.Native, ProgramBuildInfo.PROGRAM_BUILD_LOG, sz,str_ptr,IntPtr.Zero).RaiseIfError;
          
          sb += Marshal.PtrToStringAnsi(str_ptr);
          Marshal.FreeHGlobal(str_ptr);
          
        end;
        
        raise new OpenCLException(ec, sb.ToString);
      end else
        ec.RaiseIfError;
      
      self._c := c;
    end;
    
    public constructor(ntv: cl_program; retain: boolean := true);
    begin
      if retain then cl.RetainProgram(ntv).RaiseIfError;
      self.ntv := ntv;
      
      var c: cl_context;
      cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_CONTEXT, new UIntPtr(Marshal.SizeOf&<cl_context>), c, IntPtr.Zero).RaiseIfError;
      self._c := new Context(c);
      
    end;
    
    private constructor := raise new NotSupportedException;
    
    protected procedure Finalize; override :=
    cl.ReleaseProgram(ntv).RaiseIfError;
    
    {$endregion constructor's}
    
    {$region GetKernel}
    
    ///Находит в прекомпилированном коде подпрограмму-kernel с указанным именем
    ///Регистр имени kernel'а важен!
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
    
    public function Serialize: array of byte;
    begin
//      var bytes_count: UIntPtr;
//      cl.GetProgramInfo(_program, ProgramInfo.PROGRAM_BINARY_SIZES, new UIntPtr(UIntPtr.Size),bytes_count, IntPtr.Zero).RaiseIfError;
//      
//      Result := new byte[bytes_count.ToUInt64];
//      cl.GetProgramInfo(_program, ProgramInfo.PROGRAM_BINARIES, bytes_count,Result[0], IntPtr.Zero).RaiseIfError;
//      
    end;
    
    ///Вызывает метод ProgramCode.Serialize
    ///Затем записывает в поток размер полученного массива как integer
    ///И затем записывает сам массив
    public procedure SerializeTo(bw: System.IO.BinaryWriter);
    begin
      var bts := Serialize;
      bw.Write(bts.Length);
      bw.Write(bts);
    end;
    ///Вызывает метод ProgramCode.Serialize
    ///Затем записывает в поток размер полученного массива как integer
    ///И затем записывает сам массив
    public procedure SerializeTo(str: System.IO.Stream) :=
    SerializeTo(new System.IO.BinaryWriter(str));
    
    {$endregion Serialize}
    
    {$region Deserialize}
    
    public static function Deserialize(c: Context; bin: array of byte): ProgramCode;
    begin
//      Result := new ProgramCode;
//      var bin_len := new UIntPtr(bin.Length);
//      
//      var bin_arr: array of array of byte;
//      SetLength(bin_arr,1);
//      bin_arr[0] := bin;
//      
//      var ec: ErrorCode;
//      Result._program := cl.CreateProgramWithBinary(c._context,1,c._device, bin_len,bin_arr, IntPtr.Zero,ec);
//      ec.RaiseIfError;
//      
    end;
    
    public static function DeserializeFrom(c: Context; br: System.IO.BinaryReader): ProgramCode;
    begin
      var bin_len := br.ReadInt32;
      var bin_arr := br.ReadBytes(bin_len);
      if bin_arr.Length<bin_len then raise new System.IO.EndOfStreamException;
      Result := Deserialize(c, bin_arr);
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
  
  BlittableException = class(Exception)
    constructor(t, blame: System.Type; source_name: string) :=
    inherited Create(t=blame ? $'Тип {t} нельзя использовать в {source_name}' : $'Тип {t} нельзя использовать в {source_name}, потому что он содержит тип {blame}' );
  end;
  BlittableHelper = static class
    
    private static blittable_cache := new Dictionary<System.Type, System.Type>;
    static constructor;
    begin
      blittable_cache.Add(typeof(IntPtr), nil);
      blittable_cache.Add(typeof(UIntPtr), nil);
    end;
    public static function Blame(t: System.Type): System.Type;
    begin
      if t.IsPointer then exit;
      if t.IsClass then
      begin
        Result := t;
        exit;
      end;
      if blittable_cache.TryGetValue(t, Result) then exit;
      
      //ToDo протестировать - может быстрее будет без blittable_cache, потому что всё заинлайнится?
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
        on e: ThreadAbortException do ;
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
      if not st.IS_ERROR then exit;
      if st.val = ErrorCode.EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST.val then
      for var i := 0 to count-1 do
      begin
        if CLTaskExt.AddErr(tsk, cl.GetEventInfo(
          evs[i], EventInfo.EVENT_COMMAND_EXECUTION_STATUS,
          new UIntPtr(sizeof(CommandExecutionStatus)), st, IntPtr.Zero
        )) then continue;
        if CLTaskExt.AddErr(tsk, st) then Result := true;
      end else
        Result := CLTaskExt.AddErr(tsk, st);
    end;
    public procedure AttachCallback(work: Action; tsk: CLTaskBase; c: cl_context; dvc: cl_device_id; var cq: cl_command_queue) :=
    AttachCallback(self.ToMarker(c, dvc, cq), work, tsk, SmartStatusErr);
    public procedure AttachFinallyCallback(work: Action; tsk: CLTaskBase; c: cl_context; dvc: cl_device_id; var cq: cl_command_queue) :=
    AttachFinallyCallback(self.ToMarker(c, dvc, cq), work, tsk);
    
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
    private constructor := raise new System.NotSupportedException;
    static function MakeUserEvent(tsk: CLTaskBase; c: cl_context): UserEvent;
    
    public static function StartBackgroundWork(after: EventList; work: Action; c: cl_context; tsk: CLTaskBase): UserEvent;
    begin
      var res := MakeUserEvent(tsk, c);
      
      var abort_thr_ev := new AutoResetEvent(false);
      res.AttachCallback(()->abort_thr_ev.Set(), tsk);
      
      var work_thr: Thread;
      var abort_thr := NativeUtils.StartNewThread(()->
      begin
        abort_thr_ev.WaitOne; // изначальная пауза, чтоб work_thr не убили до того как он успеет запуститься и выполнить cl.ReleaseEvent
        abort_thr_ev.WaitOne;
        work_thr.Abort;
      end);
      
      work_thr := NativeUtils.StartNewThread(()->
      try
        var err := (after<>nil) and after.WaitAndRelease(tsk);
        abort_thr_ev.Set;
        
        if err then
          res.Abort;
        begin
          work;
          abort_thr.Abort;
          res.SetStatus(CommandExecutionStatus.COMPLETE);
        end;
        
      except
        on e: ThreadAbortException do ;
        on e: Exception do
        begin
          CLTaskExt.AddErr(tsk, e);
          res.Abort;
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
    
    public procedure AttachCallback(work: Action; tsk: CLTaskBase; retain: boolean := true);
    begin
      if retain then cl.RetainEvent(self.uev).RaiseIfError;
      EventList.AttachCallback(self, work, tsk);
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
    private constructor := raise new System.NotSupportedException;
    
    public function GetPtr: ^T := ptr;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(new IntPtr(ptr));
    
  end;
  
  QueueRes<T> = class;
  QueueResBase = abstract class
    public ev: EventList;
    
    public function GetResBase: object; abstract;
    
    public function LazyQuickTransformBase<T2>(f: object->T2): QueueRes<T2>;
    
  end;
  
  QueueResDelayedPtr<T> = class;
  QueueRes<T> = abstract class(QueueResBase)
    
    public function GetRes: T; abstract;
    public function GetResBase: object; override := GetRes;
    
    public function LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>;
    
    /// Должно выполнятся только после ожидания ивентов
    public function ToPtr: IPtrQueueRes<T>; abstract;
    
  end;
  
  // Результат который просто есть
  IQueueResConst = interface end;
  QueueResConst<T> = sealed class(QueueRes<T>, IQueueResConst)
    private res: T;
    
    public constructor(res: T) := self.res := res;
    private constructor := raise new System.NotSupportedException;
    
    public function GetRes: T; override := res;
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(res);
    
  end;
  
  // Результат который будет сохранён куда то, надо только дождаться
  IQueueResDelayed = interface end;
  QueueResDelayedBase<T> = abstract class(QueueRes<T>, IQueueResDelayed)
    
    public procedure SetRes(value: T); abstract;
    
  end;
  QueueResDelayedObj<T> = sealed class(QueueResDelayedBase<T>)
    private res := default(T);
    
    public constructor := exit;
    
    public function GetRes: T; override := res;
    public procedure SetRes(value: T); override := res := value;
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(res);
    
  end;
  QueueResDelayedPtr<T> = sealed class(QueueResDelayedBase<T>, IPtrQueueRes<T>)
    private ptr: ^T := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<T>));
    
    public constructor := exit;
    public constructor(res: T) := ptr^ := res;
    
    public function GetPtr: ^T := ptr;
    public function GetRes: T; override := ptr^;
    public procedure SetRes(value: T); override := ptr^ := value;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(new IntPtr(ptr));
    
    public function ToPtr: IPtrQueueRes<T>; override := self;
    
  end;
  
  // Результат который надо будет сначала дождаться, а потом ещё досчитать
  IQueueResFunc = interface
    function GetF: ()->object;
  end;
  QueueResFunc<T> = sealed class(QueueRes<T>, IQueueResFunc)
    private f: ()->T;
    
    public constructor(f: ()->T) := self.f := f;
    
    public function GetRes: T; override := f();
    public function IQueueResFunc.GetF: ()->object := ()->f();
    
    public function ToPtr: IPtrQueueRes<T>; override := new QRPtrWrap<T>(f());
    
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
  
  ///Представляет задачу выполнения очереди, создаваемую методом Context.BeginInvoke
  CLTaskBase = abstract class
    
    protected wh := new ManualResetEvent(false);
    protected wh_lock := new object;
    
    protected mu_res := new Dictionary<MultiusableCommandQueueHubBase, QueueResBase>;
    
    
    private function OrgQueueBase: CommandQueueBase; abstract;
    ///Возвращает очередь, выполнение которой описывает данный объект
    public property OrgQueue: CommandQueueBase read OrgQueueBase;
    
    {$region AddErr}
    protected err_lst := new List<Exception>;
    
    /// lock err_lst do err_lst.ToArray
    private function GetErrArr: array of Exception;
    begin
      lock err_lst do
        Result := err_lst.ToArray;
    end;
    
    public property Error: AggregateException read err_lst.Count=0 ? nil : new AggregateException($'При выполнении очереди было вызвано {err_lst.Count} исключений. Используйте try чтоб получить больше информации', GetErrArr);
    
    protected procedure AddErr(e: Exception) :=
    begin
      lock err_lst do err_lst += e;
      lock user_events do
      begin
        foreach var uev in user_events do
          uev.Abort;
        user_events.Clear;
      end;
    end;
    
    /// True если ошибка есть
    protected function AddErr(ec: ErrorCode): boolean;
    begin
      if not ec.IS_ERROR then exit;
      AddErr(new OpenCLException(ec));
      Result := true;
    end;
    /// True если ошибка есть
    protected function AddErr(st: CommandExecutionStatus): boolean;
    begin
      if not st.IS_ERROR then exit;
      AddErr(new OpenCLException(ErrorCode(st)));
      Result := true;
    end;
    
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
    ///Добавляет подпрограмму-обработчик, которая будет вызвана когда выполнение очереди завершится (успешно или с ошибой)
    public procedure WhenDone(cb: Action<CLTaskBase>) := WhenDone(cb);
    
    protected procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); abstract;
    ///Добавляет подпрограмму-обработчик, которая будет вызвана когда- и если выполнение очереди завершится успешно
    public procedure WhenComplete(cb: Action<CLTaskBase, object>) := WhenCompleteBase(cb);
    
    protected procedure WhenErrorBase(cb: Action<CLTaskBase, array of Exception>); abstract;
    ///Добавляет подпрограмму-обработчик, которая будет вызвана когда- и если при выполнении очереди будет вызвано исключение
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
  
  ///Представляет задачу выполнения очереди, создаваемую методом Context.BeginInvoke
  CLTask<T> = sealed class(CLTaskBase)
    protected q: CommandQueue<T>;
    protected q_res: T;
    
    ///Возвращает очередь, выполнение которой описывает данный объект
    public property OrgQueue: CommandQueue<T> read q; reintroduce;
    protected function OrgQueueBase: CommandQueueBase; override;
    
    private procedure RegisterWaitables(q: CommandQueue<T>);
    private function InvokeQueue(q: CommandQueue<T>; c: Context; var cq: cl_command_queue): QueueRes<T>;
    protected constructor(q: CommandQueue<T>; c: Context);
    begin
      self.q := q;
      RegisterWaitables(q);
      
      var cq: cl_command_queue;
      var qr := InvokeQueue(q, c, cq);
      
      // mu выполняют лишний .Retain, чтоб ивент не удалился пока очередь ещё запускается
      foreach var mu_qr in mu_res.Values do
        mu_qr.ev.Release;
      mu_res := nil;
      
      if qr.ev.count=0 then
      begin
        if cq<>cl_command_queue.Zero then raise new NotImplementedException; // не должно произойти никогда
        OnQDone(qr);
      end else
        qr.ev.AttachFinallyCallback(()->
        begin
          if cq<>cl_command_queue.Zero then
            System.Threading.Tasks.Task.Run(()->self.AddErr( cl.ReleaseCommandQueue(cq) ));
          OnQDone(qr);
        end, self, c.Native, c.MainDevice.Native, cq);
      
    end;
    
    {$region CLTask event's}
    
    protected EvDone := new List<Action<CLTask<T>>>;
    ///Добавляет подпрограмму-обработчик, которая будет вызвана когда выполнение очереди завершится (успешно или с ошибой)
    public procedure WhenDone(cb: Action<CLTask<T>>); reintroduce :=
    if AddEventHandler(EvDone, cb) then cb(self);
    protected procedure WhenDoneBase(cb: Action<CLTaskBase>); override :=
    WhenDone(cb as object as Action<CLTask<T>>); //ToDo #2221
    
    protected EvComplete := new List<Action<CLTask<T>, T>>;
    ///Добавляет подпрограмму-обработчик, которая будет вызвана когда- и если выполнение очереди завершится успешно
    public procedure WhenComplete(cb: Action<CLTask<T>, T>); reintroduce :=
    if AddEventHandler(EvComplete, cb) then cb(self, q_res);
    protected procedure WhenCompleteBase(cb: Action<CLTaskBase, object>); override :=
    WhenComplete(cb as object as Action<CLTask<T>, T>); //ToDo #2221
    
    protected EvError := new List<Action<CLTask<T>, array of Exception>>;
    ///Добавляет подпрограмму-обработчик, которая будет вызвана когда- и если при выполнении очереди будет вызвано исключение
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
        on e: ThreadAbortException do ;
        on e: Exception do AddErr(e);
      end;
      
      if err_lst.Count=0 then
      begin
        
        foreach var ev in l_EvComplete do
        try
          ev(self, self.q_res);
        except
          on e: ThreadAbortException do ;
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
          on e: ThreadAbortException do ;
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
  
  ///Базовый тип очереди с неопределённым типом возвращаемого значения
  ///От этого класса наследуют все типы очередей
  CommandQueueBase = abstract class
    
    {$region Invoke}
    
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; abstract;
    
    protected function InvokeNewQBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueResBase;
    begin
      var cq := cl_command_queue.Zero;
      Result := InvokeBase(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      
      Result.ev.AttachFinallyCallback(()->
      begin
        System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(cq)))
      end, tsk, c.Native, main_dvc, cq);
      
    end;
    
    {$endregion Invoke}
    
    {$region MW}
    
    private waiters_c := 0;
    protected function IsWaitable := waiters_c<>0;
    protected procedure MakeWaitable := lock self do waiters_c += 1;
    protected procedure UnMakeWaitable := lock self do waiters_c -= 1;
    
    /// добавляет tsk в качестве ключа для всех ожидаемых очередей
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
    private mw_evs := new Dictionary<CLTaskBase, MWEventContainer>;
    protected procedure RegisterWaiterTask(tsk: CLTaskBase) :=
    lock mw_evs do if not mw_evs.ContainsKey(tsk) then
    begin
      mw_evs[tsk] := new MWEventContainer;
      tsk.WhenDone(tsk->lock mw_evs do mw_evs.Remove(tsk));
    end;
    
    protected procedure AddMWHandler(tsk: CLTaskBase; handler: ()->boolean);
    begin
      var cont: MWEventContainer;
      lock mw_evs do cont := mw_evs[tsk];
      cont.AddHandler(handler);
    end;
    
    protected procedure ExecuteMWHandlers;
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
    
    //ToDo #2218
//    protected function ThenConvertBase<TOtp>(f: object->TOtp): CommandQueue<TOtp>;
//    protected function ThenConvertBase<TOtp>(f: (object,Context)->TOtp): CommandQueue<TOtp>;
    
    public function ThenConvert<TOtp>(f: object->TOtp): CommandQueue<TOtp> := ThenConvert((o,c)->f(o));
    public function ThenConvert<TOtp>(f: (object, Context)->TOtp): CommandQueue<TOtp>;
    
    {$endregion ThenConvert}
    
    {$region +/*}
    
    protected function AfterQueueSyncBase(q: CommandQueueBase): CommandQueueBase; abstract;
    protected function AfterQueueAsyncBase(q: CommandQueueBase): CommandQueueBase; abstract;
    
    public static function operator+(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueSyncBase(q1);
    public static function operator*(q1, q2: CommandQueueBase): CommandQueueBase := q2.AfterQueueAsyncBase(q1);
    
    public static procedure operator+=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1*q2;
    
    {$endregion +/*}
    
    {$region Multiusable}
    
    protected function MultiusableBase: ()->CommandQueueBase; abstract;
    
    public function Multiusable: ()->CommandQueueBase := MultiusableBase;
    
    {$endregion Multiusable}
    
    {$region ThenWait}
    
    protected function ThenWaitForAllBase(qs: sequence of CommandQueueBase): CommandQueueBase; abstract;
    protected function ThenWaitForAnyBase(qs: sequence of CommandQueueBase): CommandQueueBase; abstract;
    
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую сигнала выполненности от каждой из заданых очередей
    public function ThenWaitForAll(params qs: array of CommandQueueBase) := ThenWaitForAllBase(qs);
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую сигнала выполненности от каждой из заданых очередей
    public function ThenWaitForAll(qs: sequence of CommandQueueBase    ) := ThenWaitForAllBase(qs);
    
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую первого сигнала выполненности от одной из заданных очередей
    public function ThenWaitForAny(params qs: array of CommandQueueBase) := ThenWaitForAnyBase(qs);
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую первого сигнала выполненности от одной из заданных очередей
    public function ThenWaitForAny(qs: sequence of CommandQueueBase    ) := ThenWaitForAnyBase(qs);
    
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую сигнала выполненности от заданой очереди
    public function ThenWaitFor(q: CommandQueueBase) := ThenWaitForAll(q);
    
    {$endregion ThenWait}
    
  end;
  ///Базовый тип очереди с определённым типом возвращаемого значения "T"
  ///От этого класса наследуют все типы очередей
  CommandQueue<T> = abstract class(CommandQueueBase)
    
    {$region Invoke}
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    protected function InvokeBase(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueResBase; override :=
    Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    
    protected function InvokeNewQ(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; prev_ev: EventList): QueueRes<T>;
    begin
      var cq := cl_command_queue.Zero;
      Result := Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      
      Result.ev.AttachFinallyCallback(()->
      begin
        System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(cq)))
      end, tsk, c.Native, main_dvc, cq);
      
    end;
    
    {$endregion Invoke}
    
    {$region ConstQueue}
    
    public static function operator implicit(o: T): CommandQueue<T>;
    
    {$endregion ConstQueue}
    
    {$region ThenConvert}
    
    public function ThenConvert<TInp,TOtp>(f: TInp->TOtp): CommandQueue<TOtp>;
    public function ThenConvert<TInp,TOtp>(f: (TInp, Context)->TOtp): CommandQueue<TOtp>;
    
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
    protected function MultiusableBase: ()->CommandQueueBase; override := Multiusable as object as Func<CommandQueueBase>; //ToDo #2221
    
    {$endregion Multiusable}
    
    {$region ThenWait}
    
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую сигнала выполненности от каждой из заданых очередей
    public function ThenWaitForAll(params qs: array of CommandQueueBase): CommandQueue<T> := ThenWaitForAll(qs.AsEnumerable);
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую сигнала выполненности от каждой из заданых очередей
    public function ThenWaitForAll(qs: sequence of CommandQueueBase): CommandQueue<T>;
    protected function ThenWaitForAllBase(qs: sequence of CommandQueueBase): CommandQueueBase; override := ThenWaitForAll(qs);
    
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую первого сигнала выполненности от одной из заданных очередей
    public function ThenWaitForAny(params qs: array of CommandQueueBase): CommandQueue<T> := ThenWaitForAny(qs.AsEnumerable);
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую первого сигнала выполненности от одной из заданных очередей
    public function ThenWaitForAny(qs: sequence of CommandQueueBase): CommandQueue<T>;
    protected function ThenWaitForAnyBase(qs: sequence of CommandQueueBase): CommandQueueBase; override := ThenWaitForAny(qs);
    
    ///Создаёт очередь, сначала выполняющую данную, а затем ожидающую сигнала выполненности от заданой очереди
    public function ThenWaitFor(q: CommandQueueBase) := ThenWaitForAll(q);
    
    {$endregion ThenWait}
    
  end;
  
  {$endregion Base}
  
  {$region Container}
  
  /// очередь, выполняющая незначитальный объём своей работы, но запускающая под-очереди
  ContainerQueue<T> = abstract class(CommandQueue<T>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := InvokeSubQs(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      
      if self.IsWaitable then
        if Result.ev.count=0 then
          self.ExecuteMWHandlers else
          Result.ev.AttachCallback(self.ExecuteMWHandlers, tsk, c.Native, main_dvc, cq);
      
    end;
    
  end;
  
  {$endregion Container}
  
  {$region Host}
  
  /// очередь, выполняющая какую то работу на CPU, всегда в отдельном потоке
  HostQueue<TInp,TRes> = abstract class(CommandQueue<TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TInp>; abstract;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; abstract;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TRes>; override;
    begin
      var prev_qr := InvokeSubQs(tsk, c, main_dvc, cq, prev_ev);
      var qr := need_ptr_qr ?
        new QueueResDelayedPtr<TRes> as QueueResDelayedBase<TRes>:
        new QueueResDelayedObj<TRes> as QueueResDelayedBase<TRes>;
      
      var uev := UserEvent.StartBackgroundWork(prev_qr.ev, ()->qr.SetRes( ExecFunc(prev_qr.GetRes(), c) ), c.Native, tsk);
      if self.IsWaitable then uev.AttachCallback(self.ExecuteMWHandlers, tsk);
      
      qr.ev := uev;
      Result := qr;
    end;
    
  end;
  
  {$endregion Host}
  
  {$region Const}
  
  ///Интерфейс, который реализован только классом ConstQueue<>
  ///Позволяет получить значение, из которого была создана константая очередь, не зная его типа
  IConstQueue = interface
    function GetConstVal: Object;
  end;
  ///Представляет константную очередь
  ///Константные очереди ничего не выполняют и возвращает заданное при создании значение
  ConstQueue<T> = sealed class(CommandQueue<T>, IConstQueue)
    private res: T;
    
    public constructor(o: T) :=
    self.res := o;
    private constructor := raise new System.NotSupportedException;
    
    public function IConstQueue.GetConstVal: object := self.res;
    ///Возвращает значение из которого была создана данная константная очередь
    public property Val: T read self.res;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      
      if self.IsWaitable then
      begin
        
        if prev_ev.count=0 then
          ExecuteMWHandlers else
          prev_ev.AttachCallback(self.ExecuteMWHandlers, tsk, c.Native, main_dvc, cq);
        
      end;
      
      if need_ptr_qr then
        Result := new QueueResDelayedPtr<T>(self.res) else
        Result := new QueueResConst<T>(self.res);
      Result.ev := prev_ev ?? new EventList;
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override := exit;
    
  end;
  
  {$endregion Const}
  
  {$region Array}
  
  {$region Simple}
  
  ISimpleQueueArray = interface
    function GetQS: array of CommandQueueBase;
  end;
  SimpleQueueArray<T> = abstract class(ContainerQueue<T>, ISimpleQueueArray)
    protected qs: array of CommandQueueBase;
    
    public constructor(params qs: array of CommandQueueBase) := self.qs := qs;
    private constructor := raise new NotSupportedException;
    
    public function GetQS: array of CommandQueueBase := qs;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    foreach var q in qs do q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
  ISimpleSyncQueueArray = interface(ISimpleQueueArray) end;
  SimpleSyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleSyncQueueArray)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      
      for var i := 0 to qs.Length-2 do
        prev_ev := qs[i].InvokeBase(tsk, c, main_dvc, false, cq, prev_ev).ev;
      
      Result := (qs[qs.Length-1] as CommandQueue<T>).Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
    end;
    
  end;
  
  ISimpleAsyncQueueArray = interface(ISimpleQueueArray) end;
  SimpleAsyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleAsyncQueueArray)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      var evs := new EventList[qs.Length];
      
      for var i := 0 to qs.Length-2 do
      begin
        prev_ev.Retain;
        evs[i] := qs[i].InvokeNewQBase(tsk, c, main_dvc, false, prev_ev).ev;
      end;
      
      prev_ev.Retain;
      // Используем внешнюю cq, чтоб не создавать лишнюю
      Result := (qs[qs.Length-1] as CommandQueue<T>).Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      evs[evs.Length-1] := Result.ev;
      prev_ev.Release;
      
      Result.ev := EventList.Combine(evs, tsk, c.Native, main_dvc, cq);
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
    private constructor := raise new NotSupportedException;
    
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
      end);
      Result.ev := prev_ev;
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
      // Отдельно, чтоб не создавать лишнюю cq
      var qr := qs[qs.Length-1].Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      qrs[evs.Length-1] := qr;
      evs[evs.Length-1] := qr.ev;
      if prev_ev<>nil then prev_ev.Release;
      
      Result := new QueueResFunc<array of TInp>(()->
      begin
        Result := new TInp[qrs.Length];
        for var i := 0 to qrs.Length-1 do
          Result[i] := qrs[i].GetRes;
      end);
      Result.ev := EventList.Combine(evs, tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion Generic}
  
  {$region [2]}
  
  ConvQueueArrayBase2<TInp1, TInp2, TRes> = abstract class(HostQueue<ValueTuple<TInp1, TInp2>, TRes>)
    protected q1: CommandQueue<TInp1>;
    protected q2: CommandQueue<TInp2>;
    protected f: (TInp1, TInp2, Context)->TRes;
    
    public constructor(q1: CommandQueue<TInp1>; q2: CommandQueue<TInp2>; f: (TInp1, TInp2, Context)->TRes);
    begin
      self.q1 := q1;
      self.q2 := q2;
      self.f := f;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      self.q1.RegisterWaitables(tsk, prev_hubs);
      self.q2.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected function ExecFunc(t: ValueTuple<TInp1, TInp2>; c: Context): TRes; override := f(t.Item1, t.Item2, c);
    
  end;
  
  ConvSyncQueueArray2<TInp1, TInp2, TRes> = sealed class(ConvQueueArrayBase2<TInp1, TInp2, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr1.ev;
      var qr2 := q2.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr2.ev;
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes()));
      Result.ev := prev_ev;
    end;
    
  end;
  ConvAsyncQueueArray2<TInp1, TInp2, TRes> = sealed class(ConvQueueArrayBase2<TInp1, TInp2, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      var qr2 := q2.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes()));
      Result.ev := EventList.Combine(new EventList[](qr1.ev, qr2.ev), tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion [2]}
  
  {$region [3]}
  
  ConvQueueArrayBase3<TInp1, TInp2, TInp3, TRes> = abstract class(HostQueue<ValueTuple<TInp1, TInp2, TInp3>, TRes>)
    protected q1: CommandQueue<TInp1>;
    protected q2: CommandQueue<TInp2>;
    protected q3: CommandQueue<TInp3>;
    protected f: (TInp1, TInp2, TInp3, Context)->TRes;
    
    public constructor(q1: CommandQueue<TInp1>; q2: CommandQueue<TInp2>; q3: CommandQueue<TInp3>; f: (TInp1, TInp2, TInp3, Context)->TRes);
    begin
      self.q1 := q1;
      self.q2 := q2;
      self.q3 := q3;
      self.f := f;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      self.q1.RegisterWaitables(tsk, prev_hubs);
      self.q2.RegisterWaitables(tsk, prev_hubs);
      self.q3.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected function ExecFunc(t: ValueTuple<TInp1, TInp2, TInp3>; c: Context): TRes; override := f(t.Item1, t.Item2, t.Item3, c);
    
  end;
  
  ConvSyncQueueArray3<TInp1, TInp2, TInp3, TRes> = sealed class(ConvQueueArrayBase3<TInp1, TInp2, TInp3, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr1.ev;
      var qr2 := q2.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr2.ev;
      var qr3 := q3.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr3.ev;
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes()));
      Result.ev := prev_ev;
    end;
    
  end;
  ConvAsyncQueueArray3<TInp1, TInp2, TInp3, TRes> = sealed class(ConvQueueArrayBase3<TInp1, TInp2, TInp3, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      var qr2 := q2.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr3 := q3.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes()));
      Result.ev := EventList.Combine(new EventList[](qr1.ev, qr2.ev, qr3.ev), tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion [3]}
  
  {$region [4]}
  
  ConvQueueArrayBase4<TInp1, TInp2, TInp3, TInp4, TRes> = abstract class(HostQueue<ValueTuple<TInp1, TInp2, TInp3, TInp4>, TRes>)
    protected q1: CommandQueue<TInp1>;
    protected q2: CommandQueue<TInp2>;
    protected q3: CommandQueue<TInp3>;
    protected q4: CommandQueue<TInp4>;
    protected f: (TInp1, TInp2, TInp3, TInp4, Context)->TRes;
    
    public constructor(q1: CommandQueue<TInp1>; q2: CommandQueue<TInp2>; q3: CommandQueue<TInp3>; q4: CommandQueue<TInp4>; f: (TInp1, TInp2, TInp3, TInp4, Context)->TRes);
    begin
      self.q1 := q1;
      self.q2 := q2;
      self.q3 := q3;
      self.q4 := q4;
      self.f := f;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      self.q1.RegisterWaitables(tsk, prev_hubs);
      self.q2.RegisterWaitables(tsk, prev_hubs);
      self.q3.RegisterWaitables(tsk, prev_hubs);
      self.q4.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected function ExecFunc(t: ValueTuple<TInp1, TInp2, TInp3, TInp4>; c: Context): TRes; override := f(t.Item1, t.Item2, t.Item3, t.Item4, c);
    
  end;
  
  ConvSyncQueueArray4<TInp1, TInp2, TInp3, TInp4, TRes> = sealed class(ConvQueueArrayBase4<TInp1, TInp2, TInp3, TInp4, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr1.ev;
      var qr2 := q2.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr2.ev;
      var qr3 := q3.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr3.ev;
      var qr4 := q4.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr4.ev;
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes()));
      Result.ev := prev_ev;
    end;
    
  end;
  ConvAsyncQueueArray4<TInp1, TInp2, TInp3, TInp4, TRes> = sealed class(ConvQueueArrayBase4<TInp1, TInp2, TInp3, TInp4, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      var qr2 := q2.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr3 := q3.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr4 := q4.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes()));
      Result.ev := EventList.Combine(new EventList[](qr1.ev, qr2.ev, qr3.ev, qr4.ev), tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion [4]}
  
  {$region [5]}
  
  ConvQueueArrayBase5<TInp1, TInp2, TInp3, TInp4, TInp5, TRes> = abstract class(HostQueue<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5>, TRes>)
    protected q1: CommandQueue<TInp1>;
    protected q2: CommandQueue<TInp2>;
    protected q3: CommandQueue<TInp3>;
    protected q4: CommandQueue<TInp4>;
    protected q5: CommandQueue<TInp5>;
    protected f: (TInp1, TInp2, TInp3, TInp4, TInp5, Context)->TRes;
    
    public constructor(q1: CommandQueue<TInp1>; q2: CommandQueue<TInp2>; q3: CommandQueue<TInp3>; q4: CommandQueue<TInp4>; q5: CommandQueue<TInp5>; f: (TInp1, TInp2, TInp3, TInp4, TInp5, Context)->TRes);
    begin
      self.q1 := q1;
      self.q2 := q2;
      self.q3 := q3;
      self.q4 := q4;
      self.q5 := q5;
      self.f := f;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      self.q1.RegisterWaitables(tsk, prev_hubs);
      self.q2.RegisterWaitables(tsk, prev_hubs);
      self.q3.RegisterWaitables(tsk, prev_hubs);
      self.q4.RegisterWaitables(tsk, prev_hubs);
      self.q5.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected function ExecFunc(t: ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5>; c: Context): TRes; override := f(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5, c);
    
  end;
  
  ConvSyncQueueArray5<TInp1, TInp2, TInp3, TInp4, TInp5, TRes> = sealed class(ConvQueueArrayBase5<TInp1, TInp2, TInp3, TInp4, TInp5, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr1.ev;
      var qr2 := q2.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr2.ev;
      var qr3 := q3.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr3.ev;
      var qr4 := q4.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr4.ev;
      var qr5 := q5.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr5.ev;
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes(), qr5.GetRes()));
      Result.ev := prev_ev;
    end;
    
  end;
  ConvAsyncQueueArray5<TInp1, TInp2, TInp3, TInp4, TInp5, TRes> = sealed class(ConvQueueArrayBase5<TInp1, TInp2, TInp3, TInp4, TInp5, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      var qr2 := q2.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr3 := q3.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr4 := q4.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr5 := q5.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes(), qr5.GetRes()));
      Result.ev := EventList.Combine(new EventList[](qr1.ev, qr2.ev, qr3.ev, qr4.ev, qr5.ev), tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion [5]}
  
  {$region [6]}
  
  ConvQueueArrayBase6<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TRes> = abstract class(HostQueue<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6>, TRes>)
    protected q1: CommandQueue<TInp1>;
    protected q2: CommandQueue<TInp2>;
    protected q3: CommandQueue<TInp3>;
    protected q4: CommandQueue<TInp4>;
    protected q5: CommandQueue<TInp5>;
    protected q6: CommandQueue<TInp6>;
    protected f: (TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, Context)->TRes;
    
    public constructor(q1: CommandQueue<TInp1>; q2: CommandQueue<TInp2>; q3: CommandQueue<TInp3>; q4: CommandQueue<TInp4>; q5: CommandQueue<TInp5>; q6: CommandQueue<TInp6>; f: (TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, Context)->TRes);
    begin
      self.q1 := q1;
      self.q2 := q2;
      self.q3 := q3;
      self.q4 := q4;
      self.q5 := q5;
      self.q6 := q6;
      self.f := f;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      self.q1.RegisterWaitables(tsk, prev_hubs);
      self.q2.RegisterWaitables(tsk, prev_hubs);
      self.q3.RegisterWaitables(tsk, prev_hubs);
      self.q4.RegisterWaitables(tsk, prev_hubs);
      self.q5.RegisterWaitables(tsk, prev_hubs);
      self.q6.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected function ExecFunc(t: ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6>; c: Context): TRes; override := f(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5, t.Item6, c);
    
  end;
  
  ConvSyncQueueArray6<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TRes> = sealed class(ConvQueueArrayBase6<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr1.ev;
      var qr2 := q2.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr2.ev;
      var qr3 := q3.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr3.ev;
      var qr4 := q4.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr4.ev;
      var qr5 := q5.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr5.ev;
      var qr6 := q6.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr6.ev;
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes(), qr5.GetRes(), qr6.GetRes()));
      Result.ev := prev_ev;
    end;
    
  end;
  ConvAsyncQueueArray6<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TRes> = sealed class(ConvQueueArrayBase6<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      var qr2 := q2.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr3 := q3.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr4 := q4.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr5 := q5.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr6 := q6.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes(), qr5.GetRes(), qr6.GetRes()));
      Result.ev := EventList.Combine(new EventList[](qr1.ev, qr2.ev, qr3.ev, qr4.ev, qr5.ev, qr6.ev), tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion [6]}
  
  {$region [7]}
  
  ConvQueueArrayBase7<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, TRes> = abstract class(HostQueue<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7>, TRes>)
    protected q1: CommandQueue<TInp1>;
    protected q2: CommandQueue<TInp2>;
    protected q3: CommandQueue<TInp3>;
    protected q4: CommandQueue<TInp4>;
    protected q5: CommandQueue<TInp5>;
    protected q6: CommandQueue<TInp6>;
    protected q7: CommandQueue<TInp7>;
    protected f: (TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, Context)->TRes;
    
    public constructor(q1: CommandQueue<TInp1>; q2: CommandQueue<TInp2>; q3: CommandQueue<TInp3>; q4: CommandQueue<TInp4>; q5: CommandQueue<TInp5>; q6: CommandQueue<TInp6>; q7: CommandQueue<TInp7>; f: (TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, Context)->TRes);
    begin
      self.q1 := q1;
      self.q2 := q2;
      self.q3 := q3;
      self.q4 := q4;
      self.q5 := q5;
      self.q6 := q6;
      self.q7 := q7;
      self.f := f;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      self.q1.RegisterWaitables(tsk, prev_hubs);
      self.q2.RegisterWaitables(tsk, prev_hubs);
      self.q3.RegisterWaitables(tsk, prev_hubs);
      self.q4.RegisterWaitables(tsk, prev_hubs);
      self.q5.RegisterWaitables(tsk, prev_hubs);
      self.q6.RegisterWaitables(tsk, prev_hubs);
      self.q7.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected function ExecFunc(t: ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7>; c: Context): TRes; override := f(t.Item1, t.Item2, t.Item3, t.Item4, t.Item5, t.Item6, t.Item7, c);
    
  end;
  
  ConvSyncQueueArray7<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, TRes> = sealed class(ConvQueueArrayBase7<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr1.ev;
      var qr2 := q2.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr2.ev;
      var qr3 := q3.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr3.ev;
      var qr4 := q4.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr4.ev;
      var qr5 := q5.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr5.ev;
      var qr6 := q6.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr6.ev;
      var qr7 := q7.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr7.ev;
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes(), qr5.GetRes(), qr6.GetRes(), qr7.GetRes()));
      Result.ev := prev_ev;
    end;
    
  end;
  ConvAsyncQueueArray7<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, TRes> = sealed class(ConvQueueArrayBase7<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7, TRes>)
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7>>; override;
    begin
      var qr1 := q1.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
      var qr2 := q2.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr3 := q3.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr4 := q4.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr5 := q5.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr6 := q6.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      var qr7 := q7.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);
      Result := new QueueResFunc<ValueTuple<TInp1, TInp2, TInp3, TInp4, TInp5, TInp6, TInp7>>(()->ValueTuple.Create(qr1.GetRes(), qr2.GetRes(), qr3.GetRes(), qr4.GetRes(), qr5.GetRes(), qr6.GetRes(), qr7.GetRes()));
      Result.ev := EventList.Combine(new EventList[](qr1.ev, qr2.ev, qr3.ev, qr4.ev, qr5.ev, qr6.ev, qr7.ev), tsk, c.Native, main_dvc, cq);
    end;
    
  end;
  
  {$endregion [7]}
  
  {$endregion Conv}
  
  {$region Utils}
  
  QueueArrayUtils = static class
    
    public static function FlattenQueueArray<T>(inp: sequence of CommandQueueBase): array of CommandQueueBase; where T: ISimpleQueueArray;
    begin
      var enmr := inp.GetEnumerator;
      if not enmr.MoveNext then raise new InvalidOperationException('CombineSyncQueue и CombineAsyncQueue не могут принимать 0 очередей');
      
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
  
  {$region GPUCommand}
  
  {$region Base}
  
  GPUCommand<T> = abstract class
    
    protected function InvokeObj  (o: T;                      tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; abstract;
    protected function InvokeQueue(o_q: ()->CommandQueue<T>;  tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
  end;
  
  {$endregion Base}
  
  {$region Enqueueable}
  
  //ToDo Enqueueable команды с результатом, как GetValue. У них функция InvokeParams должна возвращать (...)->QueueRes<TRes>
  // - наверное, стоит сделать так же как HostQueue - очень базовый класс с 2 шаблонными типами
  // - а, нет, команды вроде GetValue должны быть вообще не командой, а полноценной очередью
  EnqueueableGPUCommand<T> = abstract class(GPUCommand<T>)
    
    // Если это True - InvokeParams должен возращать (...)->cl_event.Zero
    // Иначе останется ивент, который никто не удалил
    protected function NeedThread: boolean; virtual := false;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (T, cl_command_queue, CLTaskBase, EventList)->cl_event; abstract;
    
    private function MakeEvList(start_ev: EventList): List<EventList>;
    begin
      Result := new List<EventList>(ParamCount + integer(start_ev<>nil));
      if start_ev<>nil then Result += start_ev;
    end;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_qr: QueueRes<T>; l2_start_ev: EventList): EventList;
    begin
      var need_thread := self.NeedThread;
      
      var evs_l1 := MakeEvList(prev_qr.ev); // ожидание до Enqueue
      var evs_l2 := MakeEvList(l2_start_ev); // ожидание, передаваемое в Enqueue
      
      var enq_f := InvokeParams(tsk, c, main_dvc, cq, evs_l1, evs_l2);
      var ev_l1 := EventList.Combine(evs_l1, tsk, c.Native, main_dvc, cq);
      var ev_l2 := EventList.Combine(evs_l2, tsk, c.Native, main_dvc, cq);
      
      if not need_thread and (ev_l1=nil) then
        Result := enq_f(prev_qr.GetRes, cq, tsk, ev_l2) else
      begin
        NativeUtils.FixCQ(c.Native, main_dvc, cq);
        
        // Асинхронное Enqueue, придётся пересоздать cq
        var lcq := cq;
        cq := cl_command_queue.Zero;
        
        var res: UserEvent;
        
        if need_thread then
          res := UserEvent.StartBackgroundWork(ev_l1, ()->enq_f(prev_qr.GetRes, lcq, tsk, ev_l2), c.Native, tsk) else
        begin
          res := tsk.MakeUserEvent(c.Native);
          
          //ВНИМАНИЕ "ev_l1=nil" не может случится, из за условий выше
          ev_l1.AttachCallback(()->
          begin
            ev_l1.Release;
            var enq_ev := enq_f(prev_qr.GetRes, lcq, tsk, ev_l2);
            EventList.AttachCallback(enq_ev, ()->res.SetStatus(CommandExecutionStatus.COMPLETE), tsk);
          end, tsk, c.Native, main_dvc, lcq);
          
        end;
        
        EventList.AttachFinallyCallback(res, ()->
        begin
          System.Threading.Tasks.Task.Run(()->tsk.AddErr(cl.ReleaseCommandQueue(lcq)));
        end, tsk);
        Result := res; //ВНИМАНИЕ: "Result.abortable" тут установлено, в отличии от предыдущего "Result :="
      end;
      
    end;
    
    protected function InvokeObj(o: T; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    Invoke(tsk, c, main_dvc, cq, new QueueResConst<T>(o), prev_ev); // prev_qr.ev=nil
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): EventList; override :=
    Invoke(tsk, c, main_dvc, cq, o_q().Invoke(tsk, c, main_dvc, false, cq, prev_ev), nil);
    
  end;
  
  {$endregion Enqueueable}
  
  {$endregion GPUCommand}
  
  {$region GPUCommandContainer}
  
  {$region Base}
  
  GPUCommandContainer<T> = class;
  GPUCommandContainerBody<T> = abstract class
    private cc: GPUCommandContainer<T>;
    
    protected function Invoke(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; abstract;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); abstract;
    
  end;
  
  GPUCommandContainer<T> = abstract class(ContainerQueue<T>)
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
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override :=
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
  
  ///Представляет особый тип CommandQueue<Buffer>, напрямую хранящий команды чтения/записи памяти на GPU
  BufferCommandQueue = sealed class(GPUCommandContainer<Buffer>)
    
    {$region constructor's}
    
    protected procedure InitObj(obj: Buffer; c: Context); override := obj.Init(c);
    protected static function InitBuffer(b: Buffer; c: Context): Buffer;
    begin
      b.Init(c);
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
    
    ///Добавляет выполнение очереди в список обычных команд для GPU
    public function AddQueue(q: CommandQueueBase): BufferCommandQueue;
    
    {$endregion Queue}
    
    {$region Proc}
    
    ///Добавляет выполнение процедуры на CPU в список обычных команд для GPU
    public function AddProc(p: Buffer->()): BufferCommandQueue;
    public function AddProc(p: (Buffer, Context)->()): BufferCommandQueue;
    
    {$endregion Proc}
    
    {$region Wait}
    
    ///Добавляет ожидание сигнала выполненности от всех заданных очередей
    public function AddWaitAll(params qs: array of CommandQueueBase): BufferCommandQueue := AddWaitAll(qs.AsEnumerable);
    ///Добавляет ожидание сигнала выполненности от всех заданных очередей
    public function AddWaitAll(qs: sequence of CommandQueueBase): BufferCommandQueue;
    
    ///Добавляет ожидание первого сигнала выполненности от одной из заданных очередей
    public function AddWaitAny(params qs: array of CommandQueueBase): BufferCommandQueue := AddWaitAny(qs.AsEnumerable);
    ///Добавляет ожидание первого сигнала выполненности от одной из заданных очередей
    public function AddWaitAny(qs: sequence of CommandQueueBase): BufferCommandQueue;
    
    ///Добавляет ожидание сигнала выполненности от заданной очереди
    public function AddWait(q: CommandQueueBase) := AddWaitAll(q);
    
    {$endregion Wait}
    
    {$endregion Non-command add's}
    
    {$region 1#Write&Read}
    
    ///- function AddWriteData(ptr: IntPtr): BufferCommandQueue;
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function AddWriteData(ptr: CommandQueue<IntPtr>): BufferCommandQueue;
    
    ///- function AddReadData(ptr: IntPtr): BufferCommandQueue;
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function AddReadData(ptr: CommandQueue<IntPtr>): BufferCommandQueue;
    
    public function AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function AddWriteData(ptr: pointer): BufferCommandQueue;
    
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function AddReadData(ptr: pointer): BufferCommandQueue;
    
    public function AddWriteData(ptr: pointer; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddReadData(ptr: pointer; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddWriteValue<TRecord>(val: TRecord): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteValue<TRecord>(val: CommandQueue<TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray1<TRecord>(a: CommandQueue<array of TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray1<TRecord>(a: CommandQueue<array of TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddWriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    public function AddReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): BufferCommandQueue;where TRecord: record;
    
    {$endregion 1#Write&Read}
    
    {$region 2#Fill}
    
    {$endregion 2#Fill}
    
    {$region 3#Copy}
    
    {$endregion 3#Copy}
    
    {$region}
    (**
    
    {$region Write}
    
    ///- function AddWriteData(ptr: IntPtr): BufferCommandQueue;
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function AddWriteData(ptr: CommandQueue<IntPtr>): BufferCommandQueue := AddWriteData(ptr, 0,GetSizeQ);
    public function AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///Копирует область из оперативной памяти по адресу ptr в память буфера
    public function AddWriteData(ptr: pointer) := AddWriteData(IntPtr(ptr));
    public function AddWriteData(ptr: pointer; offset, len: CommandQueue<integer>) := AddWriteData(IntPtr(ptr), offset, len);
    
    
    ///- function AddWriteArray(a: Array): BufferCommandQueue;
    ///Копирует данные из содержимого массива в память буфера
    public function AddWriteArray(a: CommandQueue<&Array>): BufferCommandQueue := AddWriteArray(a, 0,GetSizeQ);
    public function AddWriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function AddWriteArray(a: Array): BufferCommandQueue;
    ///Копирует данные из содержимого массива в память буфера
    public function AddWriteArray(a: &Array) := AddWriteArray(CommandQueue&<&Array>(a));
    public function AddWriteArray(a: &Array; offset, len: CommandQueue<integer>) := AddWriteArray(CommandQueue&<&Array>(a), offset, len);
    
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    
    public function AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    
    {$endregion Write}
    
    {$region Read}
    
    ///- function AddReadData(ptr: IntPtr): BufferCommandQueue;
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function AddReadData(ptr: CommandQueue<IntPtr>): BufferCommandQueue := AddReadData(ptr, 0,GetSizeQ);
    public function AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///Копирует область памяти из буфера в оперативную память по адресу ptr
    public function AddReadData(ptr: pointer) := AddReadData(IntPtr(ptr));
    public function AddReadData(ptr: pointer; offset, len: CommandQueue<integer>) := AddReadData(IntPtr(ptr), offset, len);
    
    ///- function AddReadArray(a: Array): BufferCommandQueue;
    ///Копирует данные из памяти буфера в содержимое массива
    public function AddReadArray(a: CommandQueue<&Array>): BufferCommandQueue := AddReadArray(a, 0,GetSizeQ);
    public function AddReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function AddReadArray(a: Array): BufferCommandQueue;
    ///Копирует данные из памяти буфера в содержимое массива
    public function AddReadArray(a: &Array) := AddReadArray(CommandQueue&<&Array>(a));
    public function AddReadArray(a: &Array; offset, len: CommandQueue<integer>) := AddReadArray(CommandQueue&<&Array>(a), offset, len);
    
    public function AddReadValue<TRecord>(var val: TRecord; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    begin
      Result := AddReadData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Read}
    
    {$region Fill}
    
    public function AddFillData(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>): BufferCommandQueue := AddFillData(ptr,pattern_len, 0,GetSizeQ);
    public function AddFillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddFillData(ptr: pointer; pattern_len: CommandQueue<integer>) := AddFillData(IntPtr(ptr), pattern_len);
    public function AddFillData(ptr: pointer; pattern_len, offset, len: CommandQueue<integer>) := AddFillData(IntPtr(ptr), pattern_len, offset, len);
    
    ///- function AddReadArray(a: Array): BufferCommandQueue;
    ///Заполняет буфер копиями содержимого массива
    public function AddFillArray(a: CommandQueue<&Array>): BufferCommandQueue := AddFillArray(a, 0,GetSizeQ);
    public function AddFillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function AddReadArray(a: Array): BufferCommandQueue;
    ///Заполняет буфер копиями содержимого массива
    public function AddFillArray(a: &Array) := AddFillArray(CommandQueue&<&Array>(a));
    public function AddFillArray(a: &Array; offset, len: CommandQueue<integer>) := AddFillArray(CommandQueue&<&Array>(a), offset, len);
    
    ///- function AddFillValue(val: TRecord): BufferCommandQueue;
    ///Заполняет буфер копиями значения val
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function AddFillValue<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    begin Result := AddFillValue(val, 0,GetSizeQ); end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function AddFillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): BufferCommandQueue; where TRecord: record;
    
    ///- function AddFillValue(val: TRecord): BufferCommandQueue;
    ///Заполняет буфер копиями значения val
    public function AddFillValue<TRecord>(val: CommandQueue<TRecord>): BufferCommandQueue; where TRecord: record;
    begin Result := AddFillValue(val, 0,GetSizeQ); end;
    public function AddFillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>): BufferCommandQueue; where TRecord: record;
    
    {$endregion Fill}
    
    {$region Copy}
    
    public function AddCopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): BufferCommandQueue;
    public function AddCopyTo  (b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function AddCopyFrom(b: Buffer): BufferCommandQueue;
    ///Копирует память из буфера b в текущий
    public function AddCopyFrom(b: CommandQueue<Buffer>) := AddCopyFrom(b, 0,0, GetSizeQ);
    ///- function AddCopyTo(b: Buffer): BufferCommandQueue;
    ///Копирует память из текущего буфера в b
    public function AddCopyTo  (b: CommandQueue<Buffer>) := AddCopyTo  (b, 0,0, GetSizeQ);
    
    {$endregion Copy}
    
    (**)
    {$endregion}
    
  end;
  
  {$endregion BufferCommandQueue}
  
  {$region KernelCommandQueue}
  
  ///Представляет особый тип CommandQueue<Kernel>, напрямую хранящий команды запуска kernel'ов GPU
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
    
    ///Добавляет выполнение очереди в список обычных команд для GPU
    public function AddQueue(q: CommandQueueBase): KernelCommandQueue;
    
    {$endregion Queue}
    
    {$region Proc}
    
    ///Добавляет выполнение процедуры на CPU в список обычных команд для GPU
    public function AddProc(p: Kernel->()): KernelCommandQueue;
    public function AddProc(p: (Kernel, Context)->()): KernelCommandQueue;
    
    {$endregion Proc}
    
    {$region Wait}
    
    ///Добавляет ожидание сигнала выполненности от всех заданных очередей
    public function AddWaitAll(params qs: array of CommandQueueBase): KernelCommandQueue := AddWaitAll(qs.AsEnumerable);
    ///Добавляет ожидание сигнала выполненности от всех заданных очередей
    public function AddWaitAll(qs: sequence of CommandQueueBase): KernelCommandQueue;
    
    ///Добавляет ожидание первого сигнала выполненности от одной из заданных очередей
    public function AddWaitAny(params qs: array of CommandQueueBase): KernelCommandQueue := AddWaitAny(qs.AsEnumerable);
    ///Добавляет ожидание первого сигнала выполненности от одной из заданных очередей
    public function AddWaitAny(qs: sequence of CommandQueueBase): KernelCommandQueue;
    
    ///Добавляет ожидание сигнала выполненности от заданной очереди
    public function AddWait(q: CommandQueueBase) := AddWaitAll(q);
    
    {$endregion Wait}
    
    {$endregion Non-command add's}
    
    {$region 1#Exec}
    
    {$endregion 1#Exec}
    
    {$region}
    (**
    
    {$region Exec}
    
    public function AddExec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function AddExec(work_szs: array of integer; params args: array of CommandQueue<Buffer>) :=
    AddExec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function AddExec1(work_sz1: UIntPtr; params args: array of CommandQueue<Buffer>) := AddExec(new UIntPtr[](work_sz1), args);
    public function AddExec1(work_sz1: integer; params args: array of CommandQueue<Buffer>) := AddExec1(new UIntPtr(work_sz1), args);
    
    public function AddExec2(work_sz1, work_sz2: UIntPtr; params args: array of CommandQueue<Buffer>) := AddExec(new UIntPtr[](work_sz1, work_sz2), args);
    public function AddExec2(work_sz1, work_sz2: integer; params args: array of CommandQueue<Buffer>) := AddExec2(new UIntPtr(work_sz1), new UIntPtr(work_sz2), args);
    
    public function AddExec3(work_sz1, work_sz2, work_sz3: UIntPtr; params args: array of CommandQueue<Buffer>) := AddExec(new UIntPtr[](work_sz1, work_sz2, work_sz3), args);
    public function AddExec3(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<Buffer>) := AddExec3(new UIntPtr(work_sz1), new UIntPtr(work_sz2), new UIntPtr(work_sz3), args);
    
    
    public function AddExec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function AddExec(work_szs: array of CommandQueue<integer>; params args: array of CommandQueue<Buffer>) :=
    AddExec(work_szs.ConvertAll(sz_q->sz_q.ThenConvert(sz->new UIntPtr(sz))), args);
    
    public function AddExec1(work_sz1: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := AddExec(new CommandQueue<UIntPtr>[](work_sz1), args);
    public function AddExec1(work_sz1: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := AddExec1(work_sz1.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function AddExec2(work_sz1, work_sz2: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := AddExec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2), args);
    public function AddExec2(work_sz1, work_sz2: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := AddExec2(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function AddExec3(work_sz1, work_sz2, work_sz3: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := AddExec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2, work_sz3), args);
    public function AddExec3(work_sz1, work_sz2, work_sz3: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := AddExec3(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), work_sz3.ThenConvert(sz->new UIntPtr(sz)), args);
    
    
    public function AddExec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function AddExec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    
    {$endregion Exec}
    
    (**)
    {$endregion}
    
  end;
  
  {$endregion KernelCommandQueue}
  
  {$endregion GPUCommandContainer}
  
  {$region KernelArg}
  
  KernelArg = abstract class
    protected procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); abstract;
    
    public static function FromBuffer(b: Buffer): KernelArg;
    public static function FromBufferCQ(bq: CommandQueue<Buffer>) := bq.ThenConvert(FromBuffer);
    public static function operator implicit(b: Buffer): KernelArg := FromBuffer(b);
    
    public static function FromRecord<TRecord>(val: TRecord): KernelArg; where TRecord: record;
    public static function FromRecordCQ<TRecord>(valq: CommandQueue<TRecord>): CommandQueue<KernelArg>; where TRecord: record;
    begin Result := valq.ThenConvert(FromRecord); end;
    public static function operator implicit<TRecord>(val: TRecord): KernelArg; where TRecord: record; begin Result := FromRecord(val); end;
    
    public static function FromPtr(ptr: IntPtr; sz: UIntPtr): KernelArg;
    public static function FromPtrCQ(ptr_q: CommandQueue<IntPtr>; sz_q: CommandQueue<UIntPtr>): CommandQueue<KernelArg>;
    
    public static function FromRecordPtr<TRecord>(ptr: ^TRecord): KernelArg; where TRecord: record; begin Result := FromPtr(new IntPtr(ptr), new UIntPtr(Marshal.SizeOf&<TRecord>)); end;
    public static function operator implicit<TRecord>(ptr: ^TRecord): KernelArg; where TRecord: record; begin Result := FromRecordPtr(ptr); end;
    
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
    private constructor := raise new NotSupportedException;
    
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
  
  Result := new EventList(count);
  
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

//ToDo #2218 Переделать в абстрактный метод
function QueueResBase.LazyQuickTransformBase<T2>(f: object->T2): QueueRes<T2>;
begin
  match self with
    IQueueResConst     (var qr): Result := new QueueResConst<T2>(f(self.GetResBase));
    IQueueResDelayed   (var qr): Result := new QueueResFunc<T2>(()->f(self.GetResBase));
    IQueueResFunc      (var qr): Result := new QueueResFunc<T2>(()->f(qr.GetF()));
    else raise new System.NotImplementedException;
  end;
  Result.ev := self.ev;
end;

function QueueRes<T>.LazyQuickTransform<T2>(f: T->T2): QueueRes<T2>;
begin
  match self with
    QueueResConst       <T>(var qr): Result := new QueueResConst<T2>(f(qr.res));
    QueueResDelayedBase <T>(var qr): Result := new QueueResFunc<T2>(()->f(qr.GetRes()));
    QueueResFunc        <T>(var qr): Result := new QueueResFunc<T2>(()->f(qr.f()));
    else raise new System.NotImplementedException;
  end;
  Result.ev := self.ev;
end;

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
      q.RegisterWaitables(self, new HashSet<MultiusableCommandQueueHubBase>);
      
      var cq: cl_command_queue;
      var qr := q.InvokeBase(self, c, c.MainDevice.Native, false, cq, nil);
      
      // mu выполняют лишний .Retain, чтоб ивент не удалился пока очередь ещё запускается
      foreach var mu_qr in mu_res.Values do
        mu_qr.ev.Release;
      mu_res := nil;
      
      if qr.ev.count=0 then
      begin
        if cq<>cl_command_queue.Zero then raise new NotImplementedException; // не должно произойти никогда
        OnQDone(qr);
      end else
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
        on e: ThreadAbortException do ;
        on e: Exception do AddErr(e);
      end;
      
      if err_lst.Count=0 then
      begin
        
        foreach var ev in l_EvComplete do
        try
          ev(self, self.q_res);
        except
          on e: ThreadAbortException do ;
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
          on e: ThreadAbortException do ;
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
  CastQueue<T> = sealed class(ContainerQueue<T>)
    private q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override :=
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
    private constructor := raise new NotSupportedException;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    q.RegisterWaitables(tsk, prev_hubs);
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<TInp>; override :=
    q.Invoke(tsk, c, main_dvc, false, cq, prev_ev);
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
function CommandQueue<T>.ThenConvert<TInp, TOtp>(f: (TInp, Context)->TOtp) :=
new CommandQueueThenConvert<TInp, TOtp>(self, f);
function CommandQueue<T>.ThenConvert<TInp, TOtp>(f: TInp->TOtp) :=
new CommandQueueThenConvert<TInp, TOtp>(self, (o,c)->f(o));

function CommandQueueBase.ThenConvert<TOtp>(f: (object, Context)->TOtp) :=
self.Cast&<object>.ThenConvert(f);

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
    
    public function OnNodeInvoked(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean): QueueRes<T>;
    begin
      
      var res_o: QueueResBase;
      if tsk.mu_res.TryGetValue(self, res_o) then
        Result := QueueRes&<T>( res_o ) else
      begin
        Result := self.q.InvokeNewQ(tsk, c, main_dvc, need_ptr_qr, nil);
        tsk.mu_res[self] := Result;
      end;
      
      Result.ev.Retain;
    end;
    
    public function MakeNode: CommandQueue<T>;
    
  end;
  
  MultiusableCommandQueueNode<T> = sealed class(ContainerQueue<T>)
    public hub: MultiusableCommandQueueHub<T>;
    public constructor(hub: MultiusableCommandQueueHub<T>) := self.hub := hub;
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := hub.OnNodeInvoked(tsk, c, main_dvc, need_ptr_qr);
      if prev_ev<>nil then Result.ev := prev_ev + Result.ev;
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    if prev_hubs.Add(hub) then hub.q.RegisterWaitables(tsk, prev_hubs);
    
  end;
  
function MultiusableCommandQueueHub<T>.MakeNode :=
new MultiusableCommandQueueNode<T>(self);

function CommandQueue<T>.Multiusable: ()->CommandQueue<T> := MultiusableCommandQueueHub&<T>.Create().MakeNode;

{$endregion Multiusable}

{$region Wait}

type
  CommandQueueThenWaitFor<T> = sealed class(ContainerQueue<T>)
    public q: CommandQueue<T>;
    public waiter: WCQWaiter;
    
    public constructor(q: CommandQueue<T>; waiter: WCQWaiter);
    begin
      self.q := q;
      self.waiter := waiter;
    end;
    
    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<T>; override;
    begin
      Result := q.Invoke(tsk, c, main_dvc, need_ptr_qr, cq, prev_ev);
      Result.ev := Result.ev + waiter.GetWaitEv(tsk, c);
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
    private constructor := raise new NotSupportedException;
    
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
    private constructor := raise new NotSupportedException;
    
    protected procedure ExecProc(o: T; c: Context); override := p(o);
    
  end;
  ProcCommandC<T> = sealed class(ProcCommandBase<T>)
    public p: (T,Context)->();
    
    public constructor(p: (T,Context)->()) := self.p := p;
    private constructor := raise new NotSupportedException;
    
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
      
      var res := new QueueResConst<T>(res_obj);
      res.ev := prev_ev;
      Result := res;
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
      // это тут, чтоб хаб передал need_ptr_qr. Он делает это при первом Invoke
      Result := new_plug().Invoke(tsk, c, main_dvc, need_ptr_qr, cq, nil);
      
      foreach var comm in cc.commands do
        prev_ev := comm.InvokeQueue(new_plug, tsk, c, main_dvc, cq, prev_ev);
      
      Result.ev := prev_ev;
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

{$region Buffer}

type
  KernelArgBuffer = sealed class(KernelArg)
    private b: Buffer;
    
    public constructor(b: Buffer) := self.b := b;
    private constructor := raise new NotSupportedException;
    
    protected procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override;
    begin
      if b.ntv=cl_mem.Zero then b.Init(c);
      cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), b.ntv).RaiseIfError; 
    end;
    
  end;
  
static function KernelArg.FromBuffer(b: Buffer) := new KernelArgBuffer(b) as KernelArg; //ToDo лишний as
static function Buffer.operator implicit(b: Buffer): CommandQueue<KernelArg> := KernelArg.FromBuffer(b);

function ToKernelArg(self: CommandQueue<Buffer>) := KernelArg.FromBufferCQ(self);

{$endregion Buffer}

{$region Record}

type
  KernelArgRecord<TRecord> = sealed class(KernelArg)
  where TRecord: record;
    private val: TRecord;
    
    public constructor(val: TRecord) := self.val := val;
    private constructor := raise new NotSupportedException;
    
    protected procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override :=
    cl.SetKernelArg(k, ind, new UIntPtr(Marshal.SizeOf&<TRecord>), self.val).RaiseIfError; 
    
  end;
  
static function KernelArg.FromRecord<TRecord>(val: TRecord) := new KernelArgRecord<TRecord>(val) as KernelArg; //ToDo лишний as

function ToKernelArg<TRecord>(self: CommandQueue<TRecord>): CommandQueue<KernelArg>; extensionmethod; where TRecord: record;
begin Result := KernelArg.FromRecordCQ(self); end;

{$endregion Record}

{$region Ptr}

type
  KernelArgPtr = sealed class(KernelArg)
    private ptr: IntPtr;
    private sz: UIntPtr;
    
    public constructor(ptr: IntPtr; sz: UIntPtr);
    begin
      self.ptr := ptr;
      self.sz := sz;
    end;
    private constructor := raise new NotSupportedException;
    
    protected procedure SetArg(k: cl_kernel; ind: UInt32; c: Context); override :=
    cl.SetKernelArg(k, ind, sz, pointer(ptr)).RaiseIfError; 
    
  end;
  
static function KernelArg.FromPtr(ptr: IntPtr; sz: UIntPtr) := new KernelArgPtr(ptr, sz) as KernelArg; //ToDo лишний as

static function KernelArg.FromPtrCQ(ptr_q: CommandQueue<IntPtr>; sz_q: CommandQueue<UIntPtr>): CommandQueue<KernelArg>;
begin
  Result := new ConvAsyncQueueArray2<IntPtr, UIntPtr, KernelArg>(ptr_q, sz_q, (ptr, sz, c)->new KernelArgPtr(ptr, sz) as KernelArg);
end;

{$endregion Ptr}

{$endregion KernelArg}

{$region CommonCommands}

{$region BufferCQ}

{$region 1#Write&Read}

{$region WriteDataAutoSize}

type
  BufferCommandWriteDataAutoSize = sealed class(EnqueueableGPUCommand<Buffer>)
    private ptr: CommandQueue<IntPtr>;
    
    public constructor(ptr: CommandQueue<IntPtr>);
    begin
      self.ptr := ptr;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var ptr_qr := ptr.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 += ptr_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var ptr := ptr_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.NON_BLOCKING,
          UIntPtr.Zero, o.Size,
          ptr,
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      ptr.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteDataAutoSize}

function BufferCommandQueue.AddWriteData(ptr: CommandQueue<IntPtr>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteDataAutoSize(ptr));

{$region ReadDataAutoSize}

type
  BufferCommandReadDataAutoSize = sealed class(EnqueueableGPUCommand<Buffer>)
    private ptr: CommandQueue<IntPtr>;
    
    public constructor(ptr: CommandQueue<IntPtr>);
    begin
      self.ptr := ptr;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var ptr_qr := ptr.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 += ptr_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var ptr := ptr_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.NON_BLOCKING,
          UIntPtr.Zero, o.Size,
          ptr,
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      ptr.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadDataAutoSize}

function BufferCommandQueue.AddReadData(ptr: CommandQueue<IntPtr>): BufferCommandQueue :=
AddCommand(new BufferCommandReadDataAutoSize(ptr));

{$region WriteData}

type
  BufferCommandWriteData = sealed class(EnqueueableGPUCommand<Buffer>)
    private    ptr: CommandQueue<IntPtr>;
    private offset: CommandQueue<integer>;
    private    len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      self.   ptr :=    ptr;
      self.offset := offset;
      self.   len :=    len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var    ptr_qr :=    ptr.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=    ptr_qr.ev;
      var offset_qr := offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += offset_qr.ev;
      var    len_qr :=    len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=    len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var    ptr :=    ptr_qr.GetRes;
        var offset := offset_qr.GetRes;
        var    len :=    len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.NON_BLOCKING,
          new UIntPtr(offset), new UIntPtr(len),
          ptr,
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
         ptr.RegisterWaitables(tsk, prev_hubs);
      offset.RegisterWaitables(tsk, prev_hubs);
         len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteData}

function BufferCommandQueue.AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteData(ptr, offset, len));

{$region ReadData}

type
  BufferCommandReadData = sealed class(EnqueueableGPUCommand<Buffer>)
    private    ptr: CommandQueue<IntPtr>;
    private offset: CommandQueue<integer>;
    private    len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      self.   ptr :=    ptr;
      self.offset := offset;
      self.   len :=    len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var    ptr_qr :=    ptr.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=    ptr_qr.ev;
      var offset_qr := offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += offset_qr.ev;
      var    len_qr :=    len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=    len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var    ptr :=    ptr_qr.GetRes;
        var offset := offset_qr.GetRes;
        var    len :=    len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.NON_BLOCKING,
          new UIntPtr(offset), new UIntPtr(len),
          ptr,
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
         ptr.RegisterWaitables(tsk, prev_hubs);
      offset.RegisterWaitables(tsk, prev_hubs);
         len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadData}

function BufferCommandQueue.AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadData(ptr, offset, len));

function BufferCommandQueue.AddWriteData(ptr: pointer): BufferCommandQueue :=
AddWriteData(IntPtr(ptr));

function BufferCommandQueue.AddReadData(ptr: pointer): BufferCommandQueue :=
AddReadData(IntPtr(ptr));

function BufferCommandQueue.AddWriteData(ptr: pointer; offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddWriteData(IntPtr(ptr), offset, len);

function BufferCommandQueue.AddReadData(ptr: pointer; offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddReadData(IntPtr(ptr), offset, len);

function BufferCommandQueue.AddWriteValue<TRecord>(val: TRecord): BufferCommandQueue :=
AddWriteValue(val, 0);

{$region WriteValue}

type
  BufferCommandWriteValue<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private    val: ^TRecord := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<TRecord>));
    private offset: CommandQueue<integer>;
    
    protected procedure Finalize; override;
    begin
      Marshal.FreeHGlobal(new IntPtr(val));
    end;
    
    public constructor(val: TRecord; offset: CommandQueue<integer>);
    begin
      self.   val^ :=    val;
      self.offset  := offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var offset_qr := offset.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 += offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var offset := offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.NON_BLOCKING,
          new UIntPtr(offset), new UIntPtr(Marshal.SizeOf&<TRecord>),
          new IntPtr(val),
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
      offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteValue}

function BufferCommandQueue.AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteValue<TRecord>(val, offset));

function BufferCommandQueue.AddWriteValue<TRecord>(val: CommandQueue<TRecord>): BufferCommandQueue :=
AddWriteValue(val, 0);

{$region WriteValueQ}

type
  BufferCommandWriteValueQ<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private    val: CommandQueue<TRecord>;
    private offset: CommandQueue<integer>;
    
    public constructor(val: CommandQueue<TRecord>; offset: CommandQueue<integer>);
    begin
      self.   val :=    val;
      self.offset := offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var    val_qr :=    val.Invoke    (tsk, c, main_dvc,  True, cq, nil); evs_l2 +=    val_qr.ev;
      var offset_qr := offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var    val :=    val_qr.ToPtr;
        var offset := offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.NON_BLOCKING,
          new UIntPtr(offset), new UIntPtr(Marshal.SizeOf&<TRecord>),
          new IntPtr(val.GetPtr),
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        var val_hnd := GCHandle.Alloc(val);
        
        EventList.AttachFinallyCallback(res, ()->
        begin
          val_hnd.Free;
        end, tsk);
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
         val.RegisterWaitables(tsk, prev_hubs);
      offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteValueQ}

function BufferCommandQueue.AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteValueQ<TRecord>(val, offset));

function BufferCommandQueue.AddWriteArray1<TRecord>(a: CommandQueue<array of TRecord>): BufferCommandQueue :=
AddWriteArray1(a, 0, 0);

function BufferCommandQueue.AddWriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): BufferCommandQueue :=
AddWriteArray2(a, 0,0, 0);

function BufferCommandQueue.AddWriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): BufferCommandQueue :=
AddWriteArray3(a, 0,0,0, 0);

function BufferCommandQueue.AddReadArray1<TRecord>(a: CommandQueue<array of TRecord>): BufferCommandQueue :=
AddReadArray1(a, 0, 0);

function BufferCommandQueue.AddReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): BufferCommandQueue :=
AddReadArray2(a, 0,0, 0);

function BufferCommandQueue.AddReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): BufferCommandQueue :=
AddReadArray3(a, 0,0,0, 0);

{$region WriteArray1AutoSize}

type
  BufferCommandWriteArray1AutoSize<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array of TRecord>;
    private    a_offset: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.   a_offset :=    a_offset;
      self.buff_offset := buff_offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var    a_offset_qr :=    a_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=    a_offset_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var    a_offset :=    a_offset_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(a.Length*Marshal.SizeOf&<TRecord>),
          a[a_offset],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
         a_offset.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteArray1AutoSize}

function BufferCommandQueue.AddWriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteArray1AutoSize<TRecord>(a, a_offset, buff_offset));

{$region WriteArray2AutoSize}

type
  BufferCommandWriteArray2AutoSize<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.buff_offset := buff_offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(a.Length*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteArray2AutoSize}

function BufferCommandQueue.AddWriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteArray2AutoSize<TRecord>(a, a_offset1, a_offset2, buff_offset));

{$region WriteArray3AutoSize}

type
  BufferCommandWriteArray3AutoSize<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private   a_offset3: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.  a_offset3 :=   a_offset3;
      self.buff_offset := buff_offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var   a_offset3_qr :=   a_offset3.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset3_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var   a_offset3 :=   a_offset3_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(a.Length*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2,a_offset3],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
        a_offset3.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteArray3AutoSize}

function BufferCommandQueue.AddWriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteArray3AutoSize<TRecord>(a, a_offset1, a_offset2, a_offset3, buff_offset));

{$region ReadArray1AutoSize}

type
  BufferCommandReadArray1AutoSize<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array of TRecord>;
    private    a_offset: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.   a_offset :=    a_offset;
      self.buff_offset := buff_offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var    a_offset_qr :=    a_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=    a_offset_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var    a_offset :=    a_offset_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(a.Length*Marshal.SizeOf&<TRecord>),
          a[a_offset],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
         a_offset.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadArray1AutoSize}

function BufferCommandQueue.AddReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadArray1AutoSize<TRecord>(a, a_offset, buff_offset));

{$region ReadArray2AutoSize}

type
  BufferCommandReadArray2AutoSize<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.buff_offset := buff_offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(a.Length*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadArray2AutoSize}

function BufferCommandQueue.AddReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadArray2AutoSize<TRecord>(a, a_offset1, a_offset2, buff_offset));

{$region ReadArray3AutoSize}

type
  BufferCommandReadArray3AutoSize<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private   a_offset3: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.  a_offset3 :=   a_offset3;
      self.buff_offset := buff_offset;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var   a_offset3_qr :=   a_offset3.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset3_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var   a_offset3 :=   a_offset3_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(a.Length*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2,a_offset3],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
        a_offset3.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadArray3AutoSize}

function BufferCommandQueue.AddReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadArray3AutoSize<TRecord>(a, a_offset1, a_offset2, a_offset3, buff_offset));

{$region WriteArray1}

type
  BufferCommandWriteArray1<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array of TRecord>;
    private    a_offset: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    private         len: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.   a_offset :=    a_offset;
      self.buff_offset := buff_offset;
      self.        len :=         len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var    a_offset_qr :=    a_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=    a_offset_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      var         len_qr :=         len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=         len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var    a_offset :=    a_offset_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        var         len :=         len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(len*Marshal.SizeOf&<TRecord>),
          a[a_offset],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
         a_offset.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
              len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteArray1}

function BufferCommandQueue.AddWriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteArray1<TRecord>(a, a_offset, buff_offset, len));

{$region WriteArray2}

type
  BufferCommandWriteArray2<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    private         len: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.buff_offset := buff_offset;
      self.        len :=         len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      var         len_qr :=         len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=         len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        var         len :=         len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(len*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
              len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteArray2}

function BufferCommandQueue.AddWriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteArray2<TRecord>(a, a_offset1, a_offset2, buff_offset, len));

{$region WriteArray3}

type
  BufferCommandWriteArray3<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private   a_offset3: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    private         len: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.  a_offset3 :=   a_offset3;
      self.buff_offset := buff_offset;
      self.        len :=         len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var   a_offset3_qr :=   a_offset3.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset3_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      var         len_qr :=         len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=         len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var   a_offset3 :=   a_offset3_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        var         len :=         len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueWriteBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(len*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2,a_offset3],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
        a_offset3.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
              len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion WriteArray3}

function BufferCommandQueue.AddWriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandWriteArray3<TRecord>(a, a_offset1, a_offset2, a_offset3, buff_offset, len));

{$region ReadArray1}

type
  BufferCommandReadArray1<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array of TRecord>;
    private    a_offset: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    private         len: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.   a_offset :=    a_offset;
      self.buff_offset := buff_offset;
      self.        len :=         len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var    a_offset_qr :=    a_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=    a_offset_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      var         len_qr :=         len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=         len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var    a_offset :=    a_offset_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        var         len :=         len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(len*Marshal.SizeOf&<TRecord>),
          a[a_offset],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
         a_offset.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
              len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadArray1}

function BufferCommandQueue.AddReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadArray1<TRecord>(a, a_offset, buff_offset, len));

{$region ReadArray2}

type
  BufferCommandReadArray2<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    private         len: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.buff_offset := buff_offset;
      self.        len :=         len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      var         len_qr :=         len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=         len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        var         len :=         len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(len*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
              len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadArray2}

function BufferCommandQueue.AddReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadArray2<TRecord>(a, a_offset1, a_offset2, buff_offset, len));

{$region ReadArray3}

type
  BufferCommandReadArray3<TRecord> = sealed class(EnqueueableGPUCommand<Buffer>)
  where TRecord: record;
    private           a: CommandQueue<array[,,] of TRecord>;
    private   a_offset1: CommandQueue<integer>;
    private   a_offset2: CommandQueue<integer>;
    private   a_offset3: CommandQueue<integer>;
    private buff_offset: CommandQueue<integer>;
    private         len: CommandQueue<integer>;
    
    protected function NeedThread: boolean; override := true;
    
    public constructor(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>);
    begin
      self.          a :=           a;
      self.  a_offset1 :=   a_offset1;
      self.  a_offset2 :=   a_offset2;
      self.  a_offset3 :=   a_offset3;
      self.buff_offset := buff_offset;
      self.        len :=         len;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (Buffer, cl_command_queue, CLTaskBase, EventList)->cl_event; override;
    begin
      var           a_qr :=           a.Invoke    (tsk, c, main_dvc, False, cq, nil); evs_l1 +=           a_qr.ev;
      var   a_offset1_qr :=   a_offset1.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset1_qr.ev;
      var   a_offset2_qr :=   a_offset2.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset2_qr.ev;
      var   a_offset3_qr :=   a_offset3.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=   a_offset3_qr.ev;
      var buff_offset_qr := buff_offset.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 += buff_offset_qr.ev;
      var         len_qr :=         len.InvokeNewQ(tsk, c, main_dvc, False,     nil); evs_l1 +=         len_qr.ev;
      
      Result := (o, cq, tsk, evs)->
      begin
        var           a :=           a_qr.GetRes;
        var   a_offset1 :=   a_offset1_qr.GetRes;
        var   a_offset2 :=   a_offset2_qr.GetRes;
        var   a_offset3 :=   a_offset3_qr.GetRes;
        var buff_offset := buff_offset_qr.GetRes;
        var         len :=         len_qr.GetRes;
        
        var res: cl_event;
        
        cl.EnqueueReadBuffer(
          cq, o.Native, Bool.BLOCKING,
          new UIntPtr(buff_offset), new UIntPtr(len*Marshal.SizeOf&<TRecord>),
          a[a_offset1,a_offset2,a_offset3],
          evs.count, evs.evs, res
        ).RaiseIfError;
        
        Result := res;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;
    begin
                a.RegisterWaitables(tsk, prev_hubs);
        a_offset1.RegisterWaitables(tsk, prev_hubs);
        a_offset2.RegisterWaitables(tsk, prev_hubs);
        a_offset3.RegisterWaitables(tsk, prev_hubs);
      buff_offset.RegisterWaitables(tsk, prev_hubs);
              len.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
{$endregion ReadArray3}

function BufferCommandQueue.AddReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): BufferCommandQueue :=
AddCommand(new BufferCommandReadArray3<TRecord>(a, a_offset1, a_offset2, a_offset3, buff_offset, len));

{$endregion 1#Write&Read}

{$region 2#Fill}

{$endregion 2#Fill}

{$region 3#Copy}

{$endregion 3#Copy}

(**
{$region Write}

type
  BufferCommandWriteData = sealed class(EnqueueableGPUCommand<Buffer>)
    public ptr_q: CommandQueue<IntPtr>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(ptr_q: CommandQueue<IntPtr>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.ptr_q    := ptr_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var ptr     := ptr_q    .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, ptr.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, Bool.NON_BLOCKING,
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          ptr.Get,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      ptr_q   .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  BufferCommandWriteArray = sealed class(EnqueueableGPUCommand<Buffer>)
    public a_q: CommandQueue<&Array>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(a_q: CommandQueue<&Array>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.allow_sync_enq := false;
      self.a_q      := a_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var a       := a_q      .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, a.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, Bool.BLOCKING,
          new UIntPtr(offset.WaitAndGet), new UIntPtr(len.WaitAndGet),
          Marshal.UnsafeAddrOfPinnedArrayElement(a.WaitAndGet,0),
          0,IntPtr.Zero,IntPtr.Zero
        ).RaiseIfError;
        
        Result := cl_event.Zero;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      a_q     .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  BufferCommandWriteValue<T> = sealed class(EnqueueableGPUCommand<Buffer>) where T: record;
    public val: IntPtr;
    public offset_q: CommandQueue<integer>;
    
    public constructor(val: T; offset_q: CommandQueue<integer>);
    begin
      self.val      := __NativeUtils.CopyToUnm(val);
      self.offset_q := offset_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, offset.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, Bool.NON_BLOCKING,
          new UIntPtr(offset.Get), new UIntPtr(Marshal.SizeOf&<T>),
          self.val,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      offset_q.RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(self.val);
    
  end;
  BufferCommandWriteValueQ<T> = sealed class(EnqueueableGPUCommand<Buffer>) where T: record;
    public val_q: CommandQueue<T>;
    public offset_q: CommandQueue<integer>;
    
    public constructor(val_q: CommandQueue<T>; offset_q: CommandQueue<integer>);
    begin
      self.val_q    := val_q;
      self.offset_q := offset_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var val     := val_q    .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, val.ev, offset.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var val_ptr := __NativeUtils.CopyToUnm(val.Get());
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, Bool.NON_BLOCKING,
          new UIntPtr(offset.Get), new UIntPtr(Marshal.SizeOf&<T>),
          val_ptr,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        __EventList.AttachCallback(res_ev, (ev,st,data)->
        begin
          tsk.AddErr(st);
          Marshal.FreeHGlobal(val_ptr);
          __NativeUtils.GCHndFree(data);
        end);
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      val_q   .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  
function BufferCommandQueue.AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteData(ptr, offset, len));


function BufferCommandQueue.AddWriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteArray(a, offset, len));


function BufferCommandQueue.AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValue<TRecord>(val, offset));

function BufferCommandQueue.AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValueQ<TRecord>(val, offset));

{$endregion Write}

{$region Read}

type
  BufferCommandReadData = sealed class(EnqueueableGPUCommand<Buffer>)
    public ptr_q: CommandQueue<IntPtr>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(ptr_q: CommandQueue<IntPtr>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.ptr_q    := ptr_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var ptr     := ptr_q    .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, ptr.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueReadBuffer(
          l_cq, b.memobj, Bool.NON_BLOCKING,
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          ptr.Get,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      ptr_q   .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  BufferCommandReadArray = sealed class(EnqueueableGPUCommand<Buffer>)
    public a_q: CommandQueue<&Array>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(a_q: CommandQueue<&Array>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.allow_sync_enq := false;
      self.a_q      := a_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var a       := a_q      .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, a.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        
        cl.EnqueueReadBuffer(
          l_cq, b.memobj, Bool.BLOCKING,
          new UIntPtr(offset.WaitAndGet), new UIntPtr(len.WaitAndGet),
          Marshal.UnsafeAddrOfPinnedArrayElement(a.WaitAndGet,0),
          0,IntPtr.Zero,IntPtr.Zero
        ).RaiseIfError;
        
        Result := cl_event.Zero;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      a_q     .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  
function BufferCommandQueue.AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadData(ptr, offset, len));


function BufferCommandQueue.AddReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadArray(a, offset, len));

{$endregion Read}

{$region Fill}

type
  BufferCommandDataFill = sealed class(EnqueueableGPUCommand<Buffer>)
    public ptr_q: CommandQueue<IntPtr>;
    public pattern_len_q, offset_q, len_q: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; pattern_len_q, offset_q, len_q: CommandQueue<integer>);
    begin
      self.ptr_q          := ptr_q;
      self.pattern_len_q  := pattern_len_q;
      self.offset_q       := offset_q;
      self.len_q          := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var ptr         := ptr_q        .Invoke(tsk, c, cq, new __EventList);
      var pattern_len := pattern_len_q.Invoke(tsk, c, cq, new __EventList);
      var offset      := offset_q     .Invoke(tsk, c, cq, new __EventList);
      var len         := len_q        .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, ptr.ev, pattern_len.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          ptr.Get, new UIntPtr(pattern_len.Get),
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          prev_ev.count, prev_ev.evs, res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      ptr_q         .RegisterWaitables(tsk, prev_hubs);
      pattern_len_q .RegisterWaitables(tsk, prev_hubs);
      offset_q      .RegisterWaitables(tsk, prev_hubs);
      len_q         .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  BufferCommandArrayFill = sealed class(EnqueueableGPUCommand<Buffer>)
    public a_q: CommandQueue<&Array>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(a_q: CommandQueue<&Array>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.allow_sync_enq := false;
      self.a_q      := a_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var a       := a_q      .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, a.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var la := a.WaitAndGet;
        
        // Синхронного Fill нету, поэтому между cl.Enqueue и cl.WaitForEvents сборщик мусора может сломать указатель
        // Остаётся только закреплять, хоть так и не любой тип массива пропустит
        var a_hnd := GCHandle.Alloc(la, GCHandleType.Pinned);
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          a_hnd.AddrOfPinnedObject, new UIntPtr(System.Buffer.ByteLength(la)),
          new UIntPtr(offset.WaitAndGet), new UIntPtr(len.WaitAndGet),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        cl.WaitForEvents(1,res_ev).RaiseIfError;
        cl.ReleaseEvent(res_ev).RaiseIfError;
        
        a_hnd.Free;
        Result := cl_event.Zero;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      a_q     .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  BufferCommandValueFill<T> = sealed class(EnqueueableGPUCommand<Buffer>) where T: record;
    public val: IntPtr;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(val: T; offset_q, len_q: CommandQueue<integer>);
    begin
      self.val      := __NativeUtils.CopyToUnm(val);
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          val, new UIntPtr(Marshal.SizeOf&<T>),
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(self.val);
    
  end;
  BufferCommandValueFillQ<T> = sealed class(EnqueueableGPUCommand<Buffer>) where T: record;
    public val_q: CommandQueue<T>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(val_q: CommandQueue<T>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.val_q    := val_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var val     := val_q    .Invoke(tsk, c, cq, new __EventList);
      var offset  := offset_q .Invoke(tsk, c, cq, new __EventList);
      var len     := len_q    .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, val.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var val_ptr := __NativeUtils.CopyToUnm(val.Get());
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          val_ptr, new UIntPtr(Marshal.SizeOf&<T>),
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        __EventList.AttachCallback(res_ev, (ev,st,data)->
        begin
          tsk.AddErr(st);
          Marshal.FreeHGlobal(val_ptr);
          __NativeUtils.GCHndFree(data);
        end);
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      val_q   .RegisterWaitables(tsk, prev_hubs);
      offset_q.RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
  
function BufferCommandQueue.AddFillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandDataFill(ptr,pattern_len, offset,len));


function BufferCommandQueue.AddFillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandArrayFill(a, offset,len));


function BufferCommandQueue.AddFillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFill<TRecord>(val, offset, len));

function BufferCommandQueue.AddFillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFillQ<TRecord>(val, offset, len));

{$endregion Fill}

{$region Copy}

type
  BufferCommandCopyFrom = sealed class(EnqueueableGPUCommand<Buffer>)
    public buf_q: CommandQueue<Buffer>;
    public f_pos_q, t_pos_q, len_q: CommandQueue<integer>;
    
    public constructor(buf_q: CommandQueue<Buffer>; f_pos_q, t_pos_q, len_q: CommandQueue<integer>);
    begin
      self.buf_q    := buf_q;
      self.f_pos_q  := f_pos_q;
      self.t_pos_q  := t_pos_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var buf   := buf_q  .Invoke(tsk, c, cq, new __EventList);
      var f_pos := f_pos_q.Invoke(tsk, c, cq, new __EventList);
      var t_pos := t_pos_q.Invoke(tsk, c, cq, new __EventList);
      var len   := len_q  .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, buf.ev, f_pos.ev, t_pos.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        var b2 := buf.Get;
        if b2.memobj=cl_mem.Zero then b2.Init(l_c);
        
        cl.EnqueueCopyBuffer(
          l_cq, b2.memobj,b.memobj,
          new UIntPtr(f_pos.Get), new UIntPtr(t_pos.Get),
          new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs, res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      buf_q   .RegisterWaitables(tsk, prev_hubs);
      f_pos_q .RegisterWaitables(tsk, prev_hubs);
      t_pos_q .RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  BufferCommandCopyTo = sealed class(EnqueueableGPUCommand<Buffer>)
    public buf_q: CommandQueue<Buffer>;
    public f_pos_q, t_pos_q, len_q: CommandQueue<integer>;
    
    public constructor(buf_q: CommandQueue<Buffer>; f_pos_q, t_pos_q, len_q: CommandQueue<integer>);
    begin
      self.buf_q    := buf_q;
      self.f_pos_q  := f_pos_q;
      self.t_pos_q  := t_pos_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(tsk: CLTaskBase; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var buf   := buf_q  .Invoke(tsk, c, cq, new __EventList);
      var f_pos := f_pos_q.Invoke(tsk, c, cq, new __EventList);
      var t_pos := t_pos_q.Invoke(tsk, c, cq, new __EventList);
      var len   := len_q  .Invoke(tsk, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, buf.ev, f_pos.ev, t_pos.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        var b2 := buf.Get;
        if b2.memobj=cl_mem.Zero then b2.Init(l_c);
        
        cl.EnqueueCopyBuffer(
          l_cq, b.memobj,b2.memobj,
          new UIntPtr(f_pos.Get), new UIntPtr(t_pos.Get),
          new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs, res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<object>); override;
    begin
      buf_q   .RegisterWaitables(tsk, prev_hubs);
      f_pos_q .RegisterWaitables(tsk, prev_hubs);
      t_pos_q .RegisterWaitables(tsk, prev_hubs);
      len_q   .RegisterWaitables(tsk, prev_hubs);
    end;
    
  end;
  
function BufferCommandQueue.AddCopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopyFrom(b, from,&to, len));

function BufferCommandQueue.AddCopyTo(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopyTo(b, &to,from, len));

{$endregion Copy}
(**)

{$endregion BufferCQ}

{$region Buffer}

{$region 1#Write&Read}

function Buffer.WriteData(ptr: CommandQueue<IntPtr>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteData(ptr) as CommandQueue<Buffer>);

function Buffer.ReadData(ptr: CommandQueue<IntPtr>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadData(ptr) as CommandQueue<Buffer>);

function Buffer.WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteData(ptr, offset, len) as CommandQueue<Buffer>);

function Buffer.ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadData(ptr, offset, len) as CommandQueue<Buffer>);

function Buffer.WriteData(ptr: pointer): Buffer :=
WriteData(IntPtr(ptr));

function Buffer.ReadData(ptr: pointer): Buffer :=
ReadData(IntPtr(ptr));

function Buffer.WriteData(ptr: pointer; offset, len: CommandQueue<integer>): Buffer :=
WriteData(IntPtr(ptr), offset, len);

function Buffer.ReadData(ptr: pointer; offset, len: CommandQueue<integer>): Buffer :=
ReadData(IntPtr(ptr), offset, len);

function Buffer.WriteValue<TRecord>(val: TRecord): Buffer :=
WriteValue(val, 0);

function Buffer.WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteValue(val, offset) as CommandQueue<Buffer>);

function Buffer.WriteValue<TRecord>(val: CommandQueue<TRecord>): Buffer :=
WriteValue(val, 0);

function Buffer.WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteValue(val, offset) as CommandQueue<Buffer>);

function Buffer.WriteArray1<TRecord>(a: CommandQueue<array of TRecord>): Buffer :=
WriteArray1(a, 0, 0);

function Buffer.WriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): Buffer :=
WriteArray2(a, 0,0, 0);

function Buffer.WriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): Buffer :=
WriteArray3(a, 0,0,0, 0);

function Buffer.ReadArray1<TRecord>(a: CommandQueue<array of TRecord>): Buffer :=
ReadArray1(a, 0, 0);

function Buffer.ReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>): Buffer :=
ReadArray2(a, 0,0, 0);

function Buffer.ReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>): Buffer :=
ReadArray3(a, 0,0,0, 0);

function Buffer.WriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteArray1(a, a_offset, buff_offset) as CommandQueue<Buffer>);

function Buffer.WriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteArray2(a, a_offset1, a_offset2, buff_offset) as CommandQueue<Buffer>);

function Buffer.WriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteArray3(a, a_offset1, a_offset2, a_offset3, buff_offset) as CommandQueue<Buffer>);

function Buffer.ReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadArray1(a, a_offset, buff_offset) as CommandQueue<Buffer>);

function Buffer.ReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadArray2(a, a_offset1, a_offset2, buff_offset) as CommandQueue<Buffer>);

function Buffer.ReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadArray3(a, a_offset1, a_offset2, a_offset3, buff_offset) as CommandQueue<Buffer>);

function Buffer.WriteArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteArray1(a, a_offset, buff_offset, len) as CommandQueue<Buffer>);

function Buffer.WriteArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteArray2(a, a_offset1, a_offset2, buff_offset, len) as CommandQueue<Buffer>);

function Buffer.WriteArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddWriteArray3(a, a_offset1, a_offset2, a_offset3, buff_offset, len) as CommandQueue<Buffer>);

function Buffer.ReadArray1<TRecord>(a: CommandQueue<array of TRecord>; a_offset, buff_offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadArray1(a, a_offset, buff_offset, len) as CommandQueue<Buffer>);

function Buffer.ReadArray2<TRecord>(a: CommandQueue<array[,] of TRecord>; a_offset1,a_offset2, buff_offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadArray2(a, a_offset1, a_offset2, buff_offset, len) as CommandQueue<Buffer>);

function Buffer.ReadArray3<TRecord>(a: CommandQueue<array[,,] of TRecord>; a_offset1,a_offset2,a_offset3, buff_offset, len: CommandQueue<integer>): Buffer :=
Context.Default.SyncInvoke(self.NewQueue.AddReadArray3(a, a_offset1, a_offset2, a_offset3, buff_offset, len) as CommandQueue<Buffer>);

{$endregion 1#Write&Read}

{$region 2#Fill}

{$endregion 2#Fill}

{$region 3#Copy}

{$endregion 3#Copy}

(**
{$region Get}

function Buffer.GetData(offset, len: CommandQueue<integer>): IntPtr;
begin
  var res: IntPtr;
  
  var Qs_len: ()->CommandQueue<integer>;
  if len is ConstQueue<integer> then
    Qs_len := ()->len else
  if len is MultiusableCommandQueueNode<integer>(var mcqn) then
    Qs_len := mcqn.hub.MakeNode else
    Qs_len := len.Multiusable;
  
  var Q_res := Qs_len().ThenConvert(len_val->
  begin
    Result := Marshal.AllocHGlobal(len_val);
    res := Result;
  end);
  
  Context.Default.SyncInvoke(
    self.NewQueue.AddReadData(Q_res, offset,Qs_len()) as CommandQueue<Buffer>
  );
  
  Result := res;
end;

function Buffer.GetArrayAt<TArray>(offset: CommandQueue<integer>; szs: CommandQueue<array of integer>): TArray;
begin
  var el_t := typeof(TArray).GetElementType;
  
  if szs is ConstQueue<array of integer>(var const_szs) then
  begin
    var res := System.Array.CreateInstance(
      el_t,
      const_szs.res
    );
    
    self.ReadArray(res, 0,Marshal.SizeOf(el_t)*res.Length);
    
    Result := TArray(res);
  end else
  begin
    var Qs_szs: ()->CommandQueue<array of integer>;
    if szs is ConstQueue<array of integer> then
      Qs_szs := ()->szs else
    if szs is MultiusableCommandQueueNode<array of integer>(var mcqn) then
      Qs_szs := mcqn.hub.MakeNode else
      Qs_szs := szs.Multiusable;
    
    var Qs_a := Qs_szs().ThenConvert(szs_val->
    System.Array.CreateInstance(
      el_t,
      szs_val
    )).Multiusable;
    
    var Q_a := Qs_a();
    var Q_a_len := Qs_szs().ThenConvert( szs_val -> Marshal.SizeOf(el_t)*szs_val.Aggregate((i1,i2)->i1*i2) );
    var Q_res := Qs_a().Cast&<TArray>;
    
    Result := Context.Default.SyncInvoke(
      self.NewQueue.AddReadArray(Q_a, offset, Q_a_len)
      as CommandQueue<Buffer> +
      Q_res
    );
  end;
  
end;

function Buffer.GetArrayAt<TArray>(offset: CommandQueue<integer>; params szs: array of CommandQueue<integer>) :=
szs.All(q->q is ConstQueue<integer>) ?
GetArrayAt&<TArray>(offset, CommandQueue&<array of integer>( szs.ConvertAll(q->ConstQueue&<integer>(q).res) )) :
GetArrayAt&<TArray>(offset, CombineAsyncQueue(a->a, szs));

function Buffer.GetValueAt<TRecord>(offset: CommandQueue<integer>): TRecord;
begin
  Context.Default.SyncInvoke(
    self.NewQueue
    .AddReadValue(Result, offset) as CommandQueue<Buffer>
  );
end;

{$endregion Get}
(**)

{$endregion Buffer}

{$region KernelCQ}

{$region 1#Exec}

{$endregion 1#Exec}

{$endregion KernelCQ}

{$region Kernel}

{$region 1#Exec}

{$endregion 1#Exec}

{$endregion Kernel}

{$endregion CommonCommands}

end.