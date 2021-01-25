uses OpenCLABC;

procedure TestArg(arg: KernelArg) :=
Writeln(arg.GetType);

begin
  var i: byte;
  var b := new Buffer(1);
  
  
  
  Writeln(#10'>>> Const'#10);
  
  Writeln('Buffer:');
  TestArg(KernelArg.FromBuffer(b));
  TestArg(b);
  
  Writeln('Record:');
  TestArg(KernelArg.FromRecord(1));
  TestArg(1);
  
  Writeln('Ptr:');
  TestArg(KernelArg.FromPtr(System.IntPtr.Zero, System.UIntPtr.Zero));
  TestArg(@i);
  
  
  
  Writeln(#10'>>> Invokable'#10);
  
  Writeln('Buffer:');
  TestArg(KernelArg.FromBufferCQ(b.NewQueue));
  TestArg(b.NewQueue);
  
  Writeln('Record:');
  TestArg(KernelArg.FromRecordCQ(HFQ(()->1)));
  TestArg(HFQ(()->1));
  
  Writeln('Ptr:');
  TestArg(KernelArg.FromPtrCQ(HFQ(()->System.IntPtr.Zero), System.UIntPtr.Zero));
  Writeln('OpenCLABCBase_implementation______.Nope >_>');
  
  
  
end.