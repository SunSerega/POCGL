uses OpenCLABC;

procedure TestArg(arg: KernelArg) :=
Writeln(arg.GetType);

begin
  
  TestArg(new Buffer(1));
  TestArg(Buffer.Create(1).NewQueue as CommandQueue<Buffer>);
  Writeln;
  
  //ToDo #2303
  Writeln('WARNING: Record test off until #2303 fix');
//  TestArg(3);
//  TestArg(new ConstQueue<integer>(5));
  Writeln;
  
  var i := 5;
  //ToDo #2303
  Writeln('WARNING: Ptr test off until #2303 fix');
//  TestArg(@i);
  Writeln;
  
end.