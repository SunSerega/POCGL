## uses OpenCLABC;

var Q := HFQ(()->(1).Println+1, false).Multiusable;
CLContext.Default.SyncInvoke(CombineConvSyncQueue(a->a, |Q,Q|, false,true).Println).Println;