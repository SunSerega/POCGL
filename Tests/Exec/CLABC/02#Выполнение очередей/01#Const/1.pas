## uses OpenCLABC;

var C := CQ(5);

Context.Default.SyncInvoke(
  CombineQuickConvAsyncQueue(a->a, C,C.ThenQuickConvert(x->x*x))
).Println;