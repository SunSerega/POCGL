unit OpenCLABC;

interface

uses OpenCL;
uses System;
uses System.Threading.Tasks;

//ToDo RaiseIfError в тасках - не хорошо. Надо передавать ErrorCode потоку, вызвавшему Invoke

//ToDo issue компилятора:
// - #1947
// - #1952
// - #1957
// - #1958

type
  Context = class;
  KernelArg = class;
  
  CommandQueueBase = abstract class
    protected ev: cl_event;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); abstract;
    
    protected function GetRes: object; abstract;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
  end;
  CommandQueue<T> = abstract class(CommandQueueBase)
    protected res: T;
    
    protected function GetRes: object; override := self.res;
    
    public static function operator+<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
    
    public static function operator*<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
    
    public static function operator implicit(o: T): CommandQueue<T>;
    
  end;
  
  
  CommandQueueHostFunc<T> = sealed class(CommandQueue<T>)
    private f: ()->T;
    
    public constructor(f: ()->T) :=
    self.f := f;
    
    public constructor(o: T) :=
    self.f := ()->o;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    
  end;
  
  
  KernelArgCommandQueue = abstract class(CommandQueue<KernelArg>)
    protected org: KernelArg;
    protected prev: KernelArgCommandQueue;
    
    protected constructor(org: KernelArg; prev: KernelArgCommandQueue);
    begin
      self.org := org;
      self.prev := prev;
    end;
    
    public static function Wrap(arg: KernelArg): KernelArgCommandQueue;
    
    
    
    public function WriteData(ptr: CommandQueue<IntPtr>): KernelArgCommandQueue;
    public function WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): KernelArgCommandQueue;
    
    public function WriteData(a: CommandQueue<&Array>): KernelArgCommandQueue;
    public function WriteData(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): KernelArgCommandQueue;
    
    public function WriteData(a: &Array) := WriteData(new CommandQueueHostFunc<&Array>(a));
    public function WriteData(a: &Array; offset, len: CommandQueue<integer>) := WriteData(new CommandQueueHostFunc&<&Array>(a), offset, len);
    
    public function WriteData(ptr: pointer) := WriteData(IntPtr(ptr));
    public function WriteData(ptr: pointer; offset, len: CommandQueue<integer>) := WriteData(IntPtr(ptr), offset, len);
    
    
    
    public function ReadData(ptr: CommandQueue<IntPtr>): KernelArgCommandQueue;
    public function ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): KernelArgCommandQueue;
    
    public function ReadData(a: CommandQueue<&Array>): KernelArgCommandQueue;
    public function ReadData(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): KernelArgCommandQueue;
    
    public function ReadData(a: &Array) := ReadData(new CommandQueueHostFunc<&Array>(a));
    public function ReadData(a: &Array; offset, len: CommandQueue<integer>) := ReadData(new CommandQueueHostFunc&<&Array>(a), offset, len);
    
    public function ReadData(ptr: pointer) := ReadData(IntPtr(ptr));
    public function ReadData(ptr: pointer; offset, len: CommandQueue<integer>) := ReadData(IntPtr(ptr), offset, len);
    
  end;
  
  KernelArg = sealed class
    private memobj: cl_mem;
    private sz: UIntPtr;
    
    {$region constructor's}
    
    private constructor := exit;
    
    public constructor(size: UIntPtr) :=
    self.sz := size;
    
    public constructor(size: integer) :=
    Create(new UIntPtr(size));
    
    public constructor(size: int64) :=
    Create(new UIntPtr(size));
    
    {$endregion constructor's}
    
    {$region Queue's}
    
    public function ToQueue :=
    KernelArgCommandQueue.Wrap(self);
    
    {$endregion Queue's}
    
  end;
  
  
  Context = sealed class
    private static _platform: cl_platform_id;
    private _device: cl_device_id;
    private _context: cl_context;
    
    public constructor := Create(DeviceTypeFlags.GPU);
    
    public constructor(dt: DeviceTypeFlags);
    begin
      var ec: ErrorCode;
      
      cl.GetDeviceIDs(_platform, dt, 1, @_device, nil).RaiseIfError;
      
      _context := cl.CreateContext(nil, 1, @_device, nil, nil, @ec);
      ec.RaiseIfError;
      
    end;
    
    static constructor;
    begin
      var ec := cl.GetPlatformIDs(1,@_platform,nil);
      
      if ec.val<>ErrorCode.SUCCESS then
      begin
        {$reference PresentationFramework.dll}
        System.Windows.MessageBox.Show($'Название ошибки:{#10}{ec}', 'Не удалось инициализировать OpenCL');
        Halt;
      end;
      
    end;
    
    public function SyncInvoke<T>(q: CommandQueue<T>): T;
    begin
      var ec: ErrorCode;
      var cq := cl.CreateCommandQueue(_context, _device, CommandQueuePropertyFlags.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, ec);
      ec.RaiseIfError;
      
      q.Invoke(self, cq, cl_event.Zero);
      if q.ev<>cl_event.Zero then cl.WaitForEvents(1, @q.ev).RaiseIfError;
      
      cl.ReleaseCommandQueue(cq).RaiseIfError;
      Result := q.res;
    end;
    
    public function BeginInvoke<T>(q: CommandQueue<T>): Task<T>;
//    begin ToDo #1947
//      Result := new Task<T>(()->self.SyncInvoke(q)); // ToDo #1952
//      Result.Start;
//    end;
    
    public procedure Finalize; override;
    begin
      cl.ReleaseContext(_context);
    end;
    
  end;

implementation

uses System.Runtime.InteropServices;

{$region Костыль#1947}

type
  КостыльType1<T> = auto class // ToDo #1947
    
    this_par: Context;
    par1: CommandQueue<T>;
    
    function lambda1: T;
    begin
      Result := this_par.SyncInvoke(par1);
    end;
    
  end;

function Context.BeginInvoke<T>(q: CommandQueue<T>): Task<T>;
begin
  var k := new КостыльType1<T>(self,q);
  Result := new Task<T>(k.lambda1);
  Result.Start;
end;

{$endregion Костыль#1947}

{$region CommandQueue}

{$region HostFunc}

procedure CommandQueueHostFunc<T>.Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event);
begin
  var ec: ErrorCode;
  
  if prev_ev=cl_event.Zero then
  begin
    self.res := self.f();
    self.ev := cl_event.Zero;
  end else
  begin
    self.ev := cl.CreateUserEvent(c._context, ec);
    ec.RaiseIfError;
    
    System.Threading.Tasks.Task.Run(()->
    begin
      if prev_ev<>cl_event.Zero then cl.WaitForEvents(1,@prev_ev).RaiseIfError;
      self.res := f();
      cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
    end);
    
  end;
  
end;

static function CommandQueue<T>.operator implicit(o: T): CommandQueue<T> :=
new CommandQueueHostFunc<T>(o) as CommandQueue<T>; //ToDo #1957

{$endregion HostFunc}

{$region SyncList}

type
  CommandQueueSyncList<T> = sealed class(CommandQueue<T>)
    public lst: List<CommandQueueBase>;
    
    public procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ec: ErrorCode;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      foreach var sq in lst do
      begin
        sq.Invoke(c, cq, prev_ev);
        prev_ev := sq.ev;
      end;
      
      System.Threading.Tasks.Task.Run(()->
      begin
        if prev_ev<>cl_event.Zero then cl.WaitForEvents(1,@prev_ev).RaiseIfError;
        self.res := T(lst[lst.Count-1].GetRes);
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
  end;

static function CommandQueue<T>.operator+<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
begin
  var res: CommandQueueSyncList<T2>;
  if q2 is CommandQueueSyncList<T2>(var psl) then
    res := psl else
  begin
    res := new CommandQueueSyncList<T2>;
    res.lst += q2 as CommandQueueBase;
  end;
  
  if q1 is CommandQueueSyncList<T>(var psl) then
    res.lst.InsertRange(0, psl.lst) else
    res.lst.Insert(0, q1);
  
  Result := res as CommandQueue<T2>; //ToDo #1957
end;

{$endregion SyncList}

{$region AsyncList}

type
  CommandQueueAsyncList<T> = sealed class(CommandQueue<T>)
    public lst: List<CommandQueueBase>;
    
    public procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ec: ErrorCode;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      foreach var sq in lst do sq.Invoke(c, cq, prev_ev);
      
      var p: Action0 := ()-> //ToDo #1958
      begin
        var evs := lst.Select(cq->cq.ev).Where(ev->ev<>cl_event.Zero).ToArray;
        if evs.Length<>0 then cl.WaitForEvents(evs.Length,evs).RaiseIfError;
        self.res := T(lst[lst.Count-1].GetRes);
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end;
      
      System.Threading.Tasks.Task.Run(p);
      
    end;
    
  end;

static function CommandQueue<T>.operator*<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
begin
  var res: CommandQueueAsyncList<T2>;
  if q2 is CommandQueueAsyncList<T2>(var pasl) then
    res := pasl else
  begin
    res := new CommandQueueAsyncList<T2>;
    res.lst += q2 as CommandQueueBase;
  end;
  
  if q1 is CommandQueueAsyncList<T>(var pasl) then
    res.lst.InsertRange(0, pasl.lst) else
    res.lst.Insert(0, q1);
  
  Result := res as CommandQueue<T2>; //ToDo #1957
end;

{$endregion AsyncList}

{$region KernelArg}

{$region Base}

type
  KernelArgQueueWrap = sealed class(KernelArgCommandQueue)
    
    public constructor(arg: KernelArg);
    begin
      inherited Create(arg, nil);
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ec: ErrorCode;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      System.Threading.Tasks.Task.Run(()->
      begin
        if prev_ev<>cl_event.Zero then cl.WaitForEvents(1,@prev_ev).RaiseIfError;
        self.res := org;
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
  end;
  
static function KernelArgCommandQueue.Wrap(arg: KernelArg) :=
new KernelArgQueueWrap(arg);

{$endregion Base}

{$region WriteData}

type
  KernelArgQueueWriteData = sealed class(KernelArgCommandQueue)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(arg: KernelArgCommandQueue; ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(arg.org, arg);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      prev  .Invoke(c, cq, prev_ev);
      
      ptr   .Invoke(c, cq, cl_event.Zero); if ptr    .ev<>cl_event.Zero then cl.WaitForEvents(1,@ptr.ev);
      offset.Invoke(c, cq, cl_event.Zero); if offset .ev<>cl_event.Zero then cl.WaitForEvents(1,@offset.ev);
      len   .Invoke(c, cq, cl_event.Zero); if len    .ev<>cl_event.Zero then cl.WaitForEvents(1,@len.ev);
      
      cl.EnqueueWriteBuffer(cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev.ev,@self.ev).RaiseIfError;
      
    end;
    
  end;
  KernelArgQueueWriteArray = sealed class(KernelArgCommandQueue)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(arg: KernelArgCommandQueue; a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(arg.org, arg);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      prev  .Invoke(c, cq, prev_ev);
      
      a     .Invoke(c, cq, cl_event.Zero); if a      .ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev);
      offset.Invoke(c, cq, cl_event.Zero); if offset .ev<>cl_event.Zero then cl.WaitForEvents(1,@offset.ev);
      len   .Invoke(c, cq, cl_event.Zero); if len    .ev<>cl_event.Zero then cl.WaitForEvents(1,@len.ev);
      
      var gchnd := GCHandle.Alloc(a.res);
      cl.EnqueueWriteBuffer(cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 1,@prev.ev,@self.ev).RaiseIfError;
      
      System.Threading.Tasks.Task.Run(()->
      begin
        cl.WaitForEvents(1,@self.ev).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
  end;
  
function KernelArgCommandQueue.WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
new KernelArgQueueWriteData(self,ptr,offset,len);

function KernelArgCommandQueue.WriteData(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
new KernelArgQueueWriteArray(self,a,offset,len);

function KernelArgCommandQueue.WriteData(ptr: CommandQueue<IntPtr>) := WriteData(ptr, 0,integer(org.sz.ToUInt32));
function KernelArgCommandQueue.WriteData(a: CommandQueue<&Array>) := WriteData(a, 0,integer(org.sz.ToUInt32));

{$endregion WriteData}

{$region ReadData}

type
  KernelArgQueueReadData = sealed class(KernelArgCommandQueue)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(arg: KernelArgCommandQueue; ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(arg.org, arg);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      prev  .Invoke(c, cq, prev_ev);
      
      ptr   .Invoke(c, cq, cl_event.Zero); if ptr    .ev<>cl_event.Zero then cl.WaitForEvents(1,@ptr.ev);
      offset.Invoke(c, cq, cl_event.Zero); if offset .ev<>cl_event.Zero then cl.WaitForEvents(1,@offset.ev);
      len   .Invoke(c, cq, cl_event.Zero); if len    .ev<>cl_event.Zero then cl.WaitForEvents(1,@len.ev);
      
      cl.EnqueueReadBuffer(cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev.ev,@self.ev).RaiseIfError;
      
    end;
    
  end;
  KernelArgQueueReadArray = sealed class(KernelArgCommandQueue)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(arg: KernelArgCommandQueue; a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(arg.org, arg);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      prev  .Invoke(c, cq, prev_ev);
      
      a     .Invoke(c, cq, cl_event.Zero); if a      .ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev);
      offset.Invoke(c, cq, cl_event.Zero); if offset .ev<>cl_event.Zero then cl.WaitForEvents(1,@offset.ev);
      len   .Invoke(c, cq, cl_event.Zero); if len    .ev<>cl_event.Zero then cl.WaitForEvents(1,@len.ev);
      
      var gchnd := GCHandle.Alloc(a.res);
      cl.EnqueueReadBuffer(cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 1,@prev.ev,@self.ev).RaiseIfError;
      
      System.Threading.Tasks.Task.Run(()->
      begin
        cl.WaitForEvents(1,@self.ev).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
  end;
  
function KernelArgCommandQueue.ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
new KernelArgQueueReadData(self,ptr,offset,len);

function KernelArgCommandQueue.ReadData(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
new KernelArgQueueReadArray(self,a,offset,len);

function KernelArgCommandQueue.ReadData(ptr: CommandQueue<IntPtr>) := ReadData(ptr, 0,integer(org.sz.ToUInt32));
function KernelArgCommandQueue.ReadData(a: CommandQueue<&Array>) := ReadData(a, 0,integer(org.sz.ToUInt32));

{$endregion ReadData}

{$endregion KernelArg}

{$endregion CommandQueue}

end.