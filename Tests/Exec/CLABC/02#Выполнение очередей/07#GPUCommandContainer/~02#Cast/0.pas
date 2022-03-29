## uses OpenCLABC;

var mem := new CLMemorySegment(sizeof(integer));
mem.WriteValue&<integer>( HFQ(()->5 as object).Cast&<integer> );
mem.GetValue&<integer>.Println;