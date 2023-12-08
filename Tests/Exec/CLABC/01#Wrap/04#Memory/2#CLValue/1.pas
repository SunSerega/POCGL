## uses OpenCLABC;

var a := new CLValue<byte>(5);
Println(a.GetValue);
a.WriteValue(7);
Println(a.GetValue);

a.Dispose;