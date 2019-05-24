unit OpenCLABC;

interface

uses OpenCL;
uses System;
uses System.Threading.Tasks;

type
  Context = class;
  KernelArg = class;
  
  CommandQueueBase = abstract class
    
    protected procedure Invoke(c: Context; cq: cl_command_queue); abstract;
    
  end;
  CommandQueue<T> = abstract class(CommandQueueBase)
    protected ev: cl_event;
    protected res: T;
    
    public static function operator+<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
    
    public static function operator*(q1, q2: CommandQueue<T>): CommandQueue<T>;
    
  end;
  
  
  CommandQueueHostFunc<T> = sealed class(CommandQueue<T>)
    private f: ()->T;
    
    public constructor(f: ()->T);
    begin
      self.f := f;
      self.ev := cl.create
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue); override;
    begin
      self.res := f();
      var ToDo := 0;//self.ev.state := complete
    end;
    
    
    public static function operator implicit(o: T): CommandQueueHostFunc<T> :=
    new CommandQueueHostFunc<T>(()->o);
    
  end;
  
  
  ///--
  KernelArgCommandQueue = abstract class(CommandQueue<KernelArg>)
    private org: KernelArg;
    private prev: KernelArgCommandQueue;
    
    private constructor(org: KernelArg; prev: KernelArgCommandQueue);
    begin
      self.org := org;
      self.prev := prev;
    end;
    
    public static function Wrap(arg: KernelArg): KernelArgCommandQueue;
    
    
    public function WriteData(ptr: IntPtr): KernelArgCommandQueue;
    public function WriteData(ptr: IntPtr; offset, len: integer): KernelArgCommandQueue;
    
    public function WriteData(ptr: pointer) := WriteData(IntPtr(ptr));
    public function WriteData(ptr: pointer; offset, len: integer) := WriteData(IntPtr(ptr), offset, len);
    
    public function WriteData(a: &Array): KernelArgCommandQueue;
    public function WriteData(a: &Array; offset, len: integer): KernelArgCommandQueue;
    
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
    
    public constructor := Create(DeviceType.GPU);
    
    public constructor(dt: DeviceType);
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
        Windows.MessageBox.Show($'Название ошибки:{#10}{ec}', 'Не удалось инициализировать OpenCL');
        Halt;
      end;
      
    end;
    
    public function SyncInvoke<T>(q: CommandQueue<T>): T;
    begin
      var ec: ErrorCode;
      var cq := cl.CreateCommandQueue(_context, _device, CommandQueueProperties.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, ec);
      ec.RaiseIfError;
      
      q.Invoke(self, cq);
      cl.WaitForEvents(1, @q.ev);
      
      cl.ReleaseCommandQueue(cq).RaiseIfError;
      Result := q.res;
    end;
    
    public function BeginInvoke<T>(q: CommandQueue<T>): Task<T>;
//    begin ToDo #1947
//      Result := new Task<T>(()->self.SyncInvoke(q)); // ToDo #1946
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

{$region CommandQueueSyncList}

type
  CommandQueueSyncList<T> = sealed class(CommandQueue<T>)
    public lst: List<CommandQueueBase>;
    
  end;

static function CommandQueue<T>.operator+<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
begin
  var res := new CommandQueueSyncList<T2>;
  
  if q1 is CommandQueueSyncList<T>(var psl) then
    res.lst += psl.lst else
    res.lst += q1;
  
  res += q2;
  Result := res;
end;

{$endregion CommandQueueSyncList}

{$region CommandQueueAsyncList}

static function CommandQueue<T>.operator*(q1, q2: CommandQueue<T>): CommandQueue<T>;
begin
  
end;

{$endregion CommandQueueAsyncList}

{$region KernelCommandQueue}

{$region Base}

type
  KernelArgQueueWrap = sealed class(KernelArgCommandQueue)
    
    public constructor(arg: KernelArg);
    begin
      inherited Create(arg, nil);
      self.ev := cl.create
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue); override := self.res := org;
    
  end;
  KernelArgQueueWriteData = sealed class(KernelArgCommandQueue)
    public ptr: IntPtr;
    public offset, len: integer;
    public gchnd: GCHandle;
    
    public constructor(arg: KernelArgCommandQueue; ptr: IntPtr; offset, len: integer; gchnd: GCHandle);
    begin
      inherited Create(arg.org, arg);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
      self.gchnd := gchnd;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue); override;
    begin
      prev.Invoke(c, cq);
      
      cl.EnqueueWriteBuffer(cq, org.memobj, 0, new UIntPtr(offset), new UIntPtr(len), ptr, 1,@prev.ev,@self.ev).RaiseIfError;
      
      if gchnd.IsAllocated then gchnd.Free;
    end;
    
    public procedure Finalize; override :=
    if gchnd.IsAllocated then gchnd.Free;
    
  end;

static function KernelArgCommandQueue.Wrap(arg: KernelArg) :=
new KernelArgQueueWrap(arg);

{$endregion Base}

{$region WriteData}

function KernelArgCommandQueue.WriteData(ptr: IntPtr; offset, len: integer) :=
new KernelArgQueueWriteData(self,ptr,offset,len,default(GCHandle));

function KernelArgCommandQueue.WriteData(a: &Array; offset, len: integer): KernelArgCommandQueue;
begin
  var gchnd := GCHandle.Alloc(a,GCHandleType.Pinned);
  Result := new KernelArgQueueWriteData(self,gchnd.AddrOfPinnedObject,offset,len,gchnd);
end;

function KernelArgCommandQueue.WriteData(ptr: IntPtr) :=
WriteData(ptr,0,org.sz.ToUInt32);

function KernelArgCommandQueue.WriteData(a: &Array) :=
WriteData(a,0,org.sz.ToUInt32);

{$endregion WriteData}

{$endregion KernelCommandQueue}

end.