## uses OpenCLABC;

var mem := new CLMemory(sizeof(integer));
mem.WriteValue&<integer>( HFQ(()->5 as object, false).Cast&<integer> );
mem.GetValue&<integer>.Println;
mem.Dispose;