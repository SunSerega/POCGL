## uses OpenCLABC;

var mem := new MemorySegment(sizeof(integer));
mem.WriteValue&<integer>( HFQ(()->5 as object).Cast&<integer> );
mem.GetValue&<integer>.Println;