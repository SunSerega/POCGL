uses OpenCLABC;

begin
  var code := new ProgramCode(Context.Default, ReadAllText('1.cl'));
  var k := code['TEST'];
  Writeln(k.GetType);
  Writeln(k.Properties.GetType);
  Writeln(k.Name);
  Writeln(k.Properties.FunctionName);
  var k2 := new Kernel(k.Native);
  (k=k2).Println;
  Arr(k).Contains(k2).Println;
  Writeln(k2.GetType);
  Writeln(k2.Properties.GetType);
  Writeln(k2.Name);
  Writeln(k2.Properties.FunctionName);
end.