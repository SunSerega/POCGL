## uses OpenCLABC;

//ToDo #2511
procedure TestArg(arg: KernelArg) := Write(arg as object);



Writeln('ToDo #2511');
var i: byte;
var mem := new MemorySegment(1);



Writeln(#10'>>> Const'#10);

Writeln('MemorySegment:');
TestArg(KernelArg.FromMemorySegment(mem));
//TestArg(mem); //ToDo #2511
Writeln;

Writeln('Record:');
TestArg(KernelArg.FromRecord(1));
//TestArg(1); //ToDo #2511
Writeln;

Writeln('Ptr:');
TestArg(KernelArg.FromPtr(new System.IntPtr(1), new System.UIntPtr(2)));
//TestArg(PInteger(pointer(3))); //ToDo #2511
Writeln;



Writeln;
Writeln(#10'>>> Invokable'#10);

Writeln('MemorySegment:');
TestArg(KernelArg.FromMemorySegmentCQ(mem.NewQueue));
//TestArg(mem.NewQueue); //ToDo #2511
Writeln;

Writeln('Record:');
TestArg(KernelArg.FromRecordCQ(HFQ(()->1)));
//TestArg(HFQ(()->1)); //ToDo #2511
Writeln;

Writeln('Ptr:');
TestArg(KernelArg.FromPtrCQ(HFQ(()->System.IntPtr.Zero), System.UIntPtr.Zero));
Writeln;


