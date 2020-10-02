uses OpenCLABC;

procedure TestArg(arg: KernelArg) :=
Writeln(arg.GetType);

begin
  
  TestArg(new Buffer(1));
  TestArg(Buffer.Create(1).NewQueue as CommandQueue<Buffer>);
  Writeln;
  
  TestArg(3);
  //ToDo #2311
  Writeln('WARNING: Generic record test off until #2311 fix');
//  TestArg(new ConstQueue<integer>(5));
  Writeln;
  
  var i := 5;
  //ToDo #2318
  Writeln('WARNING: Ptr test off until #2318 fix');
//  TestArg(@i);
  Writeln;
  
end.