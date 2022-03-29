## uses OpenCLABC;

var a := new CLValue<byte>(5);
Writeln(a.GetValue);
a.WriteValue(7);
Writeln(a.GetValue);