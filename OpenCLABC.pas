
(************************************************************************************)
// Copyright (©) Cergey Latchenko ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
(************************************************************************************)
// Copyright (©) Сергей Латченко ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Этот код распространяется под Unlicense
// Для деталей смотрите в файл LICENSE или это:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
(************************************************************************************)

///
/// Выскокоуровневая оболочка для модуля OpenCL
/// OpenCL и OpenCLABC можно использовать одновременно
/// Но контактировать они в основном не будут
///
/// Если чего то не хватает - писать как и для модуля OpenCL, сюда:
/// https://github.com/SunSerega/POCGL/issues
///
unit OpenCLABC;

interface

uses OpenCL;
uses System;
uses System.Threading.Tasks;
uses System.Runtime.InteropServices;

//ToDo RaiseIfError в тасках - не хорошо. Надо передавать ErrorCode потоку, вызвавшему Invoke
// - но это не точно, Task.Wait снова вызывает все исключения
// - надо только чтоб все внутренние таски тоже получали Wait
// - возможно, заставить Invoke возвращать yield sequence of Task?

//ToDo юзер-эвенты надо удалять только если они не Zero, и так же удалять перед пересозданием
// - на случай, если очередь не выполняется или выполняется несколько раз

//ToDo issue компилятора:
// - #1881
// - #1947
// - #1952
// - #1957
// - #1958

type
  
  {$region class pre def}
  
  Context = class;
  KernelArg = class;
  Kernel = class;
  ProgramCode = class;
  
  {$endregion class pre def}
  
  {$region CommandQueue}
  
  CommandQueueBase = abstract class
    protected ev: cl_event;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); abstract;
    
    protected function GetRes: object; abstract;
    
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
    
    private костыль_поле_o: T;
    
    //ToDo #1881
//    public constructor(o: T) :=
//    self.f := ()->o;
    public constructor(o: T);
    begin
      self.костыль_поле_o := o;
      self.f := ()->self.костыль_поле_o;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
  end;
  
  {$endregion CommandQueue}
  
  {$region KernelArg}
  
  KernelArgCommandQueue = abstract class(CommandQueue<KernelArg>)
    protected org: KernelArg;
    protected prev: KernelArgCommandQueue;
    
    protected constructor(org: KernelArg);
    begin
      self.org := org;
      self.prev := nil;
    end;
    
    protected constructor(prev: KernelArgCommandQueue);
    begin
      self.org := prev.org;
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
    
    
    
    public function WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): KernelArgCommandQueue; where TRecord: record;
    begin
      Result := WriteData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
  end;
  
  KernelArg = sealed class
    private memobj: cl_mem;
    private sz: UIntPtr;
    
    {$region constructor's}
    
    private constructor := raise new System.NotSupportedException;
    
    public constructor(size: UIntPtr) :=
    self.sz := size;
    
    public constructor(size: integer) :=
    Create(new UIntPtr(size));
    
    public constructor(size: int64) :=
    Create(new UIntPtr(size));
    
    {$endregion constructor's}
    
    {$region Queue's}
    
    public function NewQueue :=
    KernelArgCommandQueue.Wrap(self);
    
    public static function ValueQueue<TRecord>(val: TRecord): KernelArgCommandQueue; where TRecord: record;
    begin
      Result := 
        KernelArg.Create(Marshal.SizeOf&<TRecord>)
        .NewQueue.WriteData(@val, 0, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Queue's}
    
  end;
  
  {$endregion KernelArg}
  
  {$region Kernel}
  
  KernelCommandQueue = abstract class(CommandQueue<Kernel>)
    protected org: Kernel;
    protected prev: KernelCommandQueue;
    
    protected constructor(org: Kernel);
    begin
      self.org := org;
      self.prev := nil;
    end;
    
    protected constructor(prev: KernelCommandQueue);
    begin
      self.org := prev.org;
      self.prev := prev;
    end;
    
    public static function Wrap(arg: Kernel): KernelCommandQueue;
    
    
    
    public function Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<KernelArg>): KernelCommandQueue;
    
    public function Exec(work_szs: array of integer; params args: array of CommandQueue<KernelArg>) :=
    Exec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function Exec(work_sz1: integer; params args: array of CommandQueue<KernelArg>) := Exec(new integer[](work_sz1), args);
    public function Exec(work_sz1, work_sz2: integer; params args: array of CommandQueue<KernelArg>) := Exec(new integer[](work_sz1, work_sz2), args);
    public function Exec(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<KernelArg>) := Exec(new integer[](work_sz1, work_sz2, work_sz3), args);
    
  end;
  
  Kernel = sealed class
    private _kernel: cl_kernel;
    
    {$region constructor's}
    
    private constructor := raise new System.NotSupportedException;
    
    public constructor(prog: ProgramCode; name: string);
    
    {$endregion constructor's}
    
    {$region Queue's}
    
    public function NewQueue :=
    KernelCommandQueue.Wrap(self);
    
    {$endregion Queue's}
    
  end;
  
  {$endregion Kernel}
  
  {$region Context}
  
  Context = sealed class
    private static _platform: cl_platform_id;
    private _device: cl_device_id;
    private _context: cl_context;
    
    public constructor := Create(DeviceTypeFlags.GPU);
    
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
    
    public constructor(dt: DeviceTypeFlags);
    begin
      var ec: ErrorCode;
      
      cl.GetDeviceIDs(_platform, dt, 1, @_device, nil).RaiseIfError;
      
      _context := cl.CreateContext(nil, 1, @_device, nil, nil, @ec);
      ec.RaiseIfError;
      
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
//      Result := new Task<T>(()->self.SyncInvoke(q)); // ToDo #1952 //ToDo #1881
//      Result.Start;
//    end;
    
    public procedure Finalize; override :=
    cl.ReleaseContext(_context).RaiseIfError;
    
  end;
  
  {$endregion Context}
  
  {$region ProgramCode}
  
  ProgramCode = sealed class
    private _program: cl_program;
    private cntxt: Context;
    
    private constructor := exit;
    
    public constructor(c: Context; params files: array of string);
    begin
      var ec: ErrorCode;
      self.cntxt := c;
      
      self._program := cl.CreateProgramWithSource(c._context, files.Length, files, files.ConvertAll(s->new UIntPtr(s.Length)), ec);
      ec.RaiseIfError;
      
      cl.BuildProgram(self._program, 1, @c._device, nil,nil,nil).RaiseIfError;
      
    end;
    
    public property KernelByName[kname: string]: Kernel read new Kernel(self, kname); default;
    
    public function GetAllKernels: Dictionary<string, Kernel>;
    begin
      
      var names_char_len: UIntPtr;
      cl.GetProgramInfo(_program, ProgramInfoType.NUM_KERNELS, new UIntPtr(UIntPtr.Size), @names_char_len, nil).RaiseIfError;
      
      var names_ptr := Marshal.AllocHGlobal(IntPtr(pointer(names_char_len))+1);
      cl.GetProgramInfo(_program, ProgramInfoType.KERNEL_NAMES, names_char_len, pointer(names_ptr), nil).RaiseIfError;
      
      var names := Marshal.PtrToStringAnsi(names_ptr).Split(';');
      Marshal.FreeHGlobal(names_ptr);
      
      Result := new Dictionary<string, Kernel>(names.Length);
      foreach var kname in names do
        Result[kname] := self[kname];
      
    end;
    
    public function Serialize: array of byte;
    begin
      var bytes_count: UIntPtr;
      cl.GetProgramInfo(_program, ProgramInfoType.BINARY_SIZES, new UIntPtr(UIntPtr.Size), @bytes_count, nil).RaiseIfError;
      
      var bytes_mem := Marshal.AllocHGlobal(IntPtr(pointer(bytes_count)));
      cl.GetProgramInfo(_program, ProgramInfoType.BINARIES, bytes_count, @bytes_mem, nil).RaiseIfError;
      
      Result := new byte[bytes_count.ToUInt64()];
      Marshal.Copy(bytes_mem,Result, 0,Result.Length);
      Marshal.FreeHGlobal(bytes_mem);
      
    end;
    
    public procedure SerializeTo(bw: System.IO.BinaryWriter);
    begin
      var bts := Serialize;
      bw.Write(bts.Length);
      bw.Write(bts);
    end;
    
    public procedure SerializeTo(str: System.IO.Stream) := SerializeTo(new System.IO.BinaryWriter(str));
    
    public static function Deserialize(c: Context; bin: array of byte): ProgramCode;
    begin
      var ec: ErrorCode;
      
      Result := new ProgramCode;
      Result.cntxt := c;
      
      var gchnd := GCHandle.Alloc(bin);
      var bin_mem: ^byte := pointer(gchnd.AddrOfPinnedObject);
      var bin_len := new UIntPtr(bin.Length);
      
      Result._program := cl.CreateProgramWithBinary(c._context,1,@c._device, @bin_len, @bin_mem, nil, @ec);
      ec.RaiseIfError;
      gchnd.Free;
      
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
    
  end;
  
  {$endregion ProgramCode}
  
///HostFuncQueue
///Создаёт новую CommandQueueHostFunc
function HFQ<T>(f: ()->T): CommandQueueHostFunc<T>;

implementation

{$region Костыль #1947, #1952}

type
  КостыльType1<T> = auto class // ToDo любая из: #1947, #1952
    
    this_par: Context;
    par1: CommandQueue<T>;
    
    function lambda1: T;
    begin
      Result := this_par.SyncInvoke(par1);
    end;
    
  end;

function Context.BeginInvoke<T>(q: CommandQueue<T>): Task<T>;
begin
  var k := new КостыльType1<T>(self,q); //лишнее предупреждение это #1948
  Result := new Task<T>(k.lambda1);
  Result.Start;
end;

{$endregion Костыль#1947}

{$region CommandQueue}

{$region HostFunc}

var костыль_для_CommandQueueHostFunc_prev_ev: cl_event; // ToDo #1881

procedure CommandQueueHostFunc<T>.Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event);
begin
  var ec: ErrorCode;
  
  self.ev := cl.CreateUserEvent(c._context, ec);
  ec.RaiseIfError;
  
  костыль_для_CommandQueueHostFunc_prev_ev := prev_ev;
  Task.Run(()->
  begin
    if костыль_для_CommandQueueHostFunc_prev_ev<>cl_event.Zero then cl.WaitForEvents(1,@костыль_для_CommandQueueHostFunc_prev_ev).RaiseIfError;
    self.res := f();
    cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
  end);
  
end;

static function CommandQueue<T>.operator implicit(o: T): CommandQueue<T> :=
new CommandQueueHostFunc<T>(o) as CommandQueue<T>; //ToDo #1957

{$endregion HostFunc}

{$region SyncList}

type
  CommandQueueSyncList<T> = sealed class(CommandQueue<T>)
    public lst: List<CommandQueueBase>;
    
    private костыль_для_prev_ev: cl_event; // ToDo #1881
    
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
      
      костыль_для_prev_ev := prev_ev;
      Task.Run(()->
      begin
        if костыль_для_prev_ev<>cl_event.Zero then cl.WaitForEvents(1,@костыль_для_prev_ev).RaiseIfError;
        self.res := T(lst[lst.Count-1].GetRes);
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
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
      
      Task.Run(p);
      
    end;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
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
      inherited Create(arg);
      self.res := org;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      self.ev := prev_ev;
      
      if org.memobj=cl_mem.Zero then
      begin
        var ec: ErrorCode;
        org.memobj := cl.CreateBuffer(c._context, MemoryFlags.READ_WRITE, org.sz, IntPtr.Zero, ec);
        ec.RaiseIfError;
      end;
      
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
      inherited Create(arg);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    private костыль_для_cq: cl_event; // ToDo #1881
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ec: ErrorCode;
      
      prev  .Invoke(c, cq, prev_ev);
      
      var ev_lst := new List<cl_event>;
      ptr   .Invoke(c, cq, cl_event.Zero); if ptr   .ev<>cl_event.Zero then ev_lst += ptr.ev;
      offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      костыль_для_cq := cq;
      Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev.ev=cl_event.Zero then
          cl.EnqueueWriteBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 0,nil,@buff_ev).RaiseIfError;
          cl.EnqueueWriteBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev.ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE);
      end);
      
    end;
    
  end;
  KernelArgQueueWriteArray = sealed class(KernelArgCommandQueue)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(arg: KernelArgCommandQueue; a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(arg);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    private костыль_для_cq: cl_event; // ToDo #1881
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      prev  .Invoke(c, cq,       prev_ev);
      
      a     .Invoke(c, cq, cl_event.Zero);
      offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      костыль_для_cq := cq;
      Task.Run(()->
      begin
        if a.ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev).RaiseIfError;
        var gchnd := GCHandle.Alloc(a.res);
        
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev.ev=cl_event.Zero then
          cl.EnqueueWriteBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 0,nil,@buff_ev).RaiseIfError;
          cl.EnqueueWriteBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 1,@prev.ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1,@buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
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
      inherited Create(arg);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    private костыль_для_cq: cl_event; // ToDo #1881
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ec: ErrorCode;
      
      prev  .Invoke(c, cq, prev_ev);
      
      var ev_lst := new List<cl_event>;
      ptr   .Invoke(c, cq, cl_event.Zero); if ptr   .ev<>cl_event.Zero then ev_lst += ptr.ev;
      offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      костыль_для_cq := cq;
      Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev.ev=cl_event.Zero then
          cl.EnqueueReadBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 0,nil,@buff_ev).RaiseIfError;
          cl.EnqueueReadBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev.ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE);
      end);
      
    end;
    
  end;
  KernelArgQueueReadArray = sealed class(KernelArgCommandQueue)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(arg: KernelArgCommandQueue; a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(arg);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    private костыль_для_cq: cl_event; // ToDo #1881
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      prev  .Invoke(c, cq,       prev_ev); if prev  .ev<>cl_event.Zero then
      
      a     .Invoke(c, cq, cl_event.Zero);
      offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      костыль_для_cq := cq;
      Task.Run(()->
      begin
        if a.ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev).RaiseIfError;
        var gchnd := GCHandle.Alloc(a.res);
        
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev.ev=cl_event.Zero then
          cl.EnqueueReadBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 0,nil,@buff_ev).RaiseIfError;
          cl.EnqueueReadBuffer(костыль_для_cq, org.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 1,@prev.ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1,@buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
  end;
  
function KernelArgCommandQueue.ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
new KernelArgQueueReadData(self,ptr,offset,len);

function KernelArgCommandQueue.ReadData(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
new KernelArgQueueReadArray(self,a,offset,len);

function KernelArgCommandQueue.ReadData(ptr: CommandQueue<IntPtr>) := ReadData(ptr, 0,integer(org.sz.ToUInt32));
function KernelArgCommandQueue.ReadData(a: CommandQueue<&Array>) := ReadData(a, 0,integer(org.sz.ToUInt32));

{$endregion ReadData}

{$endregion KernelArg}

{$region Kernel}

{$region Base}

type
  KernelQueueWrap = sealed class(KernelCommandQueue)
    
    public constructor(arg: Kernel);
    begin
      inherited Create(arg);
      self.res := org;
    end;
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      self.ev := prev_ev;
    end;
    
  end;
  
static function KernelCommandQueue.Wrap(arg: Kernel) :=
new KernelQueueWrap(arg);

{$endregion Base}

{$region Exec}

type
  KernelQueueExec = sealed class(KernelCommandQueue)
    public args_q: array of CommandQueue<KernelArg>;
    public work_szs: array of UIntPtr;
    
    public constructor(k: KernelCommandQueue; work_szs: array of UIntPtr; args: array of CommandQueue<KernelArg>);
    begin
      inherited Create(k);
      self.work_szs := work_szs;
      self.args_q := args;
    end;
    
    private костыль_для_cq: cl_event; // ToDo #1881
    
    protected procedure Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event); override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      prev.Invoke(c, cq, prev_ev);
      if prev.ev<>cl_event.Zero then
        ev_lst += prev.ev;
      
      foreach var arg_q in args_q do
      begin
        arg_q.Invoke(c, cq, cl_event.Zero);
        if arg_q.ev<>cl_event.Zero then
          ev_lst += arg_q.ev;
      end;
      
      cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      костыль_для_cq := cq;
      Task.Run(()->
      begin
        if ev_lst=nil then System.Console.Beep;
        halt;
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count,ev_lst.ToArray);
        
        for var i := 0 to args_q.Length-1 do
          cl.SetKernelArg(org._kernel, i, args_q[i].res.sz, args_q[i].res.memobj).RaiseIfError;
        
        var kernel_ev: cl_event;
        cl.EnqueueNDRangeKernel(костыль_для_cq, org._kernel, work_szs.Length, nil,work_szs,nil, 0,nil,@kernel_ev).RaiseIfError;
        cl.WaitForEvents(1,@kernel_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE);
      end);
      
    end;
    
    public procedure Finalize; override :=
    cl.ReleaseEvent(self.ev).RaiseIfError;
    
  end;
  
function KernelCommandQueue.Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<KernelArg>) :=
new KernelQueueExec(self, work_szs, args);

{$endregion Exec}

{$endregion Kernel}

{$endregion CommandQueue}

{$region Misc implementation}

constructor Kernel.Create(prog: ProgramCode; name: string);
begin
  var ec: ErrorCode;
  
  self._kernel := cl.CreateKernel(prog._program, name, ec);
  ec.RaiseIfError;
  
end;

function HFQ<T>(f: ()->T) :=
new CommandQueueHostFunc<T>(f);

{$endregion Misc implementation}

end.