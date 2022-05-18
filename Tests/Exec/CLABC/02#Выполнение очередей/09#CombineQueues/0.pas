## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CombineConstConvSyncQueue(res->res,
    ArrGen(10, i->HTFQ(()->i), 1)
  )
).Println;

CLContext.Default.SyncInvoke(
  CombineConstConvSyncQueueN2((i,s)->(i,s),
    HTFQ(()->5),
    HTFQ(()->'abc')
  )
).Println;

CLContext.Default.SyncInvoke(
  CombineConstConvAsyncQueue(res->res,
    ArrGen(10, i->HTFQ(()->i), 1)
  )
).Println;

CLContext.Default.SyncInvoke(
  CombineConstConvAsyncQueueN2((i,s)->(i,s),
    HTFQ(()->5),
    HTFQ(()->'abc')
  )
).Println;