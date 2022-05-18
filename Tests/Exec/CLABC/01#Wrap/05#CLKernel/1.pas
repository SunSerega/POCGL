## uses OpenCLABC;

var code := new CLProgramCode('kernel void k(int x) {}');
var k := code['k'];
Println(k.GetType);
Println(k.Name);
var k2 := new CLKernel(k.AllocNative);
(k=k2).Println;
Arr(k).Contains(k2).Println;
Println(k2.GetType);
Println(k2.Name);