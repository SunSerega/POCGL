## uses OpenCLABC;

var mem := new CLMemory(sizeof(integer));
mem.WriteValue(1 shl 24 + 2 shl 16 + 3 shl 8 + 4 shl 0);
mem.GetValue&<integer>.ToString('X').Println;
mem.Dispose;