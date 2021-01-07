uses OpenCLABC;

procedure TestArg(arg: KernelArg) :=
Writeln(arg.GetType);

begin
  
  Writeln(#10'>>> Const'#10);
  
  Writeln('Buffer:');
  TestArg(new Buffer(1));
  Writeln('Record:');
  TestArg(1);
  Writeln('Ptr:');
  TestArg(KernelArg.FromPtr(System.IntPtr.Zero, System.UIntPtr.Zero));
  
  Writeln(#10'>>> Invokable'#10);
  
  Writeln('Buffer:');
  TestArg(Buffer.Create(1).NewQueue()); //ToDo Лишние (), разобраться когда путаница пройдёт
  Writeln('Record:');
  TestArg(HFQ(()->1));
  Writeln('Ptr:');
  TestArg(KernelArg.FromPtrCQ(HFQ(()->System.IntPtr.Zero), System.UIntPtr.Zero));
  
end.