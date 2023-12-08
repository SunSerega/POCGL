## uses OpenCLABC;

var m := new CLMemory(1);
var ms := new CLMemorySubSegment(m, 0, 1);
Println(ms);
ms.Dispose;
m.Dispose;