## uses OpenCLABC;

procedure TestArg(arg: KernelArg) := Write(arg);



var i: byte;
var mem := new MemorySegment(1);



Writeln(#10'>>> Const'#10);

Writeln('MemorySegment:');
TestArg(KernelArg.FromMemorySegment(mem));
TestArg(mem);
Writeln;

Writeln('Record:');
TestArg(KernelArg.FromRecord(1));
TestArg(1);
Writeln;

Writeln('Ptr:');
TestArg(KernelArg.FromPtr(new System.IntPtr(1), new System.UIntPtr(2)));
TestArg(PInteger(pointer(3)));
Writeln;



Writeln;
Writeln(#10'>>> Invokable'#10);

Writeln('MemorySegment:');
TestArg(KernelArg.FromMemorySegmentCQ(mem.NewQueue));
TestArg(mem.NewQueue);
Writeln;

Writeln('Record:');
TestArg(KernelArg.FromRecordCQ(HFQ(()->1)));
TestArg(HFQ(()->1));
Writeln;

Writeln('Ptr:');
TestArg(KernelArg.FromPtrCQ(HFQ(()->System.IntPtr.Zero), System.UIntPtr.Zero));
Writeln;


