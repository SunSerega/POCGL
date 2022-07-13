## uses OpenCLABC;

Println(new ConstQueue<object>(byte(3)) * (new ConstQueue<byte>(5)).Cast&<object>);
Println(HFQ(()->5).Cast&<object> * HFQ(()->5).Cast&<object>);

CLMemory.Create(1).MakeCCQ
.ThenQueue(CQ(0))
.ThenQueue(HFQ(()->5).Cast&<object>)
.Println;