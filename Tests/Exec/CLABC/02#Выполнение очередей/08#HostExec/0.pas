## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HTPQ(()->Println(5))+
  HQFQ(()->7)
).Println;