## uses OpenCLABC;

var mem := new CLMemory(sizeof(integer));
mem.WriteValue&<integer>( HQFQ(()->5 as object).Cast&<integer> );
mem.GetValue&<integer>.Println;