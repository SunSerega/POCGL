## uses OpenCLABC;

var Qs := HFQQ(()->(1).Println+1).Multiusable;
Context.Default.SyncInvoke(CombineQuickConvAsyncQueue(a->a, Qs(), Qs())).Println;