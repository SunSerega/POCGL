uses OpenCLABC;

procedure TestArg(arg: KernelArg) := Write(arg);

begin
  var i: byte;
  var b := new Buffer(1);
  
  
  
  Writeln(#10'>>> Const'#10);
  
  Writeln('Buffer:');
  TestArg(KernelArg.FromBuffer(b));
  TestArg(b);
  Writeln;
  
  Writeln('Record:');
  TestArg(KernelArg.FromRecord(1));
  TestArg(1);
  Writeln;
  
  Writeln('Ptr:');
  TestArg(KernelArg.FromPtr(new System.IntPtr(1), new System.UIntPtr(2)));
  TestArg(KernelArg(PInteger(pointer(3)))); //ToDo #2436
  Writeln;
  
  
  
  Writeln;
  Writeln(#10'>>> Invokable'#10);
  
  Writeln('Buffer:');
  TestArg(KernelArg.FromBufferCQ(b.NewQueue));
  TestArg(b.NewQueue);
  Writeln;
  
  Writeln('Record:');
  TestArg(KernelArg.FromRecordCQ(HFQ(()->1)));
  TestArg(HFQ(()->1));
  Writeln;
  
  Writeln('Ptr:');
  TestArg(KernelArg.FromPtrCQ(HFQ(()->System.IntPtr.Zero), System.UIntPtr.Zero));
  Writeln;
  
  
  
end.