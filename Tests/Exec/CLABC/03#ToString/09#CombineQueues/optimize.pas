## uses OpenCLABC;

Println(new ConstQueue<object>(byte(3)) * (new ConstQueue<byte>(5)).Cast&<object>);
Println(HFQ(()->5).Cast&<object> * HFQ(()->5).Cast&<object>);

var m := new CLMemory(1);
m.MakeCCQ
.ThenQueue(CQ(0))
.ThenQueue(HFQ(()->5).Cast&<object>)
.Println;
m.Dispose;