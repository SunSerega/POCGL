## uses OpenCLABC;

procedure TestArg(arg: KernelArg) := Write(arg);



var cl_a := new CLArray<byte>(1);
var mem := new MemorySegment(1);
var a := |5.0|;



Writeln(#10'>>> Const'#10);

Writeln('CLArray:');
TestArg(KernelArg.FromCLArray(cl_a));
TestArg(cl_a);
Writeln;

Writeln('MemorySegment:');
TestArg(KernelArg.FromMemorySegment(mem));
TestArg(mem);
Writeln;

Writeln('Data:');
TestArg(KernelArg.FromData(new System.IntPtr(1), new System.UIntPtr(2)));
TestArg(PInteger(pointer(3)));
Writeln;

Writeln('Value:');
TestArg(KernelArg.FromValue(1));
TestArg(1);
Writeln;

Writeln('Array:');
TestArg(KernelArg.FromArray(a, 1));
TestArg(a);
Writeln;



Writeln;
Writeln(#10'>>> Invokable'#10);

Writeln('CLArray:');
TestArg(KernelArg.FromCLArrayCQ(cl_a.NewQueue));
//TestArg(cl_a.NewQueue); //TODO #2550
Writeln('TODO: implicit CLArray');
Writeln;

Writeln('MemorySegment:');
TestArg(KernelArg.FromMemorySegmentCQ(mem.NewQueue));
TestArg(mem.NewQueue);
Writeln;

Writeln('Data:');
TestArg(KernelArg.FromDataCQ(HFQ(()->System.IntPtr.Zero), System.UIntPtr.Zero));
Writeln;

Writeln('Value:');
TestArg(KernelArg.FromValueCQ(HFQ(()->1)));
TestArg(HFQ(()->1));
Writeln;

Writeln('Array:');
TestArg(KernelArg.FromArrayCQ(HFQ(()->a), 1));
TestArg(HFQ(()->a));
Writeln;


