
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

interface

uses System;

uses OpenCL;
uses OpenCLABCBase in 'Internal\OpenCLABCBase';

{$region Re:definition's}

type
  
  DeviceType              = OpenCL.DeviceType;
  DeviceAffinityDomain    = OpenCL.DeviceAffinityDomain;
  
  Platform                = OpenCLABCBase.Platform;
  Device                  = OpenCLABCBase.Device;
  SubDevice               = OpenCLABCBase.SubDevice;
  Context                 = OpenCLABCBase.Context;
  
  Buffer                  = OpenCLABCBase.Buffer;
  SubBuffer               = OpenCLABCBase.SubBuffer;
  Kernel                  = OpenCLABCBase.Kernel;
  ProgramCode             = OpenCLABCBase.ProgramCode;
  
  CLTaskBase              = OpenCLABCBase.CLTaskBase;
  CLTask<T>               = OpenCLABCBase.CLTask<T>;
  
  CommandQueueBase        = OpenCLABCBase.CommandQueueBase;
  CommandQueue<T>         = OpenCLABCBase.CommandQueue<T>;
  
  IConstQueue             = OpenCLABCBase.IConstQueue;
  ConstQueue<T>           = OpenCLABCBase.ConstQueue<T>;
  
  BufferCommandQueue      = OpenCLABCBase.BufferCommandQueue;
  KernelCommandQueue      = OpenCLABCBase.KernelCommandQueue;
  
  KernelArg               = OpenCLABCBase.KernelArg;
  
{$endregion Re:definition's}

{$region HFQ/HPQ}

function HFQ<T>(f: ()->T): CommandQueue<T>;
function HFQ<T>(f: Context->T): CommandQueue<T>;

function HPQ(p: ()->()): CommandQueueBase;
function HPQ(p: Context->()): CommandQueueBase;

{$endregion HFQ/HPQ}

{$region WaitFor}

function WaitForAll(params qs: array of CommandQueueBase): CommandQueueBase;
function WaitForAll(qs: sequence of CommandQueueBase): CommandQueueBase;

function WaitForAny(params qs: array of CommandQueueBase): CommandQueueBase;
function WaitForAny(qs: sequence of CommandQueueBase): CommandQueueBase;

function WaitFor(q: CommandQueueBase): CommandQueueBase;

{$endregion WaitFor}

{$region CombineQueue's}

{%CombineQueues.Interface!CombineQueues.pas%}

{$endregion CombineQueue's}

implementation

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

{$region WaitFor}

type
  CommandQueueWaitFor = sealed class(CommandQueue<object>)
    public waiter: WCQWaiter;
    
    public constructor(waiter: WCQWaiter) :=
    self.waiter := waiter;
    
    protected function InvokeImpl(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; need_ptr_qr: boolean; var cq: cl_command_queue; prev_ev: EventList): QueueRes<object>; override;
    begin
      if need_ptr_qr then new System.InvalidOperationException;
      var wait_ev := waiter.GetWaitEv(tsk, c);
      Result := new QueueResConst<object>(nil, prev_ev=nil ? wait_ev : prev_ev+wait_ev);
    end;
    
    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override :=
    waiter.RegisterWaitables(tsk);
    
  end;
  
function WaitForAll(params qs: array of CommandQueueBase) := WaitForAll(qs.AsEnumerable);
function WaitForAll(qs: sequence of CommandQueueBase) := new CommandQueueWaitFor(new WCQWaiterAll(qs.ToArray));

function WaitForAny(params qs: array of CommandQueueBase) := WaitForAny(qs.AsEnumerable);
function WaitForAny(qs: sequence of CommandQueueBase) := new CommandQueueWaitFor(new WCQWaiterAny(qs.ToArray));

function WaitFor(q: CommandQueueBase) := WaitForAll(q);

{$endregion WaitFor}

{$region CombineQueue's}

{%CombineQueues.Implementation!CombineQueues.pas%}

{$endregion CombineQueue's}

end.