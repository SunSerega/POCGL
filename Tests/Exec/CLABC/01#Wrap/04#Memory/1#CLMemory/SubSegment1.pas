## uses OpenCLABC;

var align := CLContext.Default.MainDevice.Properties.MemBaseAddrAlign;

var mem := new CLMemory(align*2);
var mem1 := new CLMemorySubSegment(mem, 0, 1);
var mem2 := new CLMemorySubSegment(mem, align, align);

Println(mem.Size64/align);
Println(mem.Properties.GetType);
Println(mem1.Size);
Println(mem1.Properties.GetType);
Println(mem2.Size64/align);
Println(mem2.Properties.GetType);