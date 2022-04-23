## uses OpenCLABC;

Context.Default.SyncInvoke(
  CombineConstConvSyncQueue(res->res,
    ArrGen(10, i->HTFQ(()->i), 1)
  )
).Println;

Context.Default.SyncInvoke(
  CombineConstConvSyncQueueN2((i,s)->(i,s),
    HTFQ(()->5),
    HTFQ(()->'abc')
  )
).Println;

Context.Default.SyncInvoke(
  CombineConstConvAsyncQueue(res->res,
    ArrGen(10, i->HTFQ(()->i), 1)
  )
).Println;

Context.Default.SyncInvoke(
  CombineConstConvAsyncQueueN2((i,s)->(i,s),
    HTFQ(()->5),
    HTFQ(()->'abc')
  )
).Println;