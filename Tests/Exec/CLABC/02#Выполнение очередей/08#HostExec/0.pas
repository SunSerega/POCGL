## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HPQ(()->Println(5)) +
  HFQ(()->7, false)
).Println;