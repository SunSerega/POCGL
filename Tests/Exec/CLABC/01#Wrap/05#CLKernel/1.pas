## uses OpenCLABC;

var code := new CLProgramCode('kernel void k(int x) {}');
var k := code['k'];
Println(k.GetType);
Println(k.Properties.GetType);
Println(k.Name);
Println(k.Properties.FunctionName);
var k2 := new CLKernel(k.Native);
(k=k2).Println;
Arr(k).Contains(k2).Println;
Println(k2.GetType);
Println(k2.Properties.GetType);
Println(k2.Name);
Println(k2.Properties.FunctionName);