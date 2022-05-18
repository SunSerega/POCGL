## uses OpenCLABC;

var Qs := HQFQ(()->(1).Println+1).Multiusable;
CLContext.Default.SyncInvoke(CombineConstConvAsyncQueue(a->a, Qs(), Qs())).Println;