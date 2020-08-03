uses OpenCLABC;

begin
  var c := Context.Default;
  Writeln(c.GetType);
  Writeln(c.Properties.GetType);
  var c2 := new Context(c.Native);
  (c=c2).Println;
  c.AllDevices.SequenceEqual(c2.AllDevices).Println;
  Arr(c).Contains(c2).Println;
  Writeln(c2.GetType);
  Writeln(c2.Properties.GetType);
end.