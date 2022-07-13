## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CombineConvSyncQueue(res->res,
    ArrGen(10, i->HFQ(()->i), 1), false
  )
).Println;

CLContext.Default.SyncInvoke(
  CombineConvSyncQueueN2((i,s)->(i,s),
    HFQ(()->5),
    HFQ(()->'abc'),
  false)
).Println;

CLContext.Default.SyncInvoke(
  CombineConvAsyncQueue(res->res,
    ArrGen(10, i->HFQ(()->i), 1), false
  )
).Println;

CLContext.Default.SyncInvoke(
  CombineConvAsyncQueueN2((i,s)->(i,s),
    HFQ(()->5),
    HFQ(()->'abc'),
  false)
).Println;