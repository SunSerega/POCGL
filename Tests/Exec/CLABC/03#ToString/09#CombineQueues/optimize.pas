## uses OpenCLABC;

Println(new ConstQueue<object>(byte(3)) * (new ConstQueue<byte>(5)).Cast&<object>);
Println(HTFQ(()->5).Cast&<object> * HTFQ(()->5).Cast&<object>);

CLMemory.Create(1).NewQueue
.ThenQueue(CQ(0))
.ThenQueue(HTFQ(()->5).Cast&<object>)
.Println;