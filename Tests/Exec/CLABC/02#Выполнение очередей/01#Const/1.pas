## uses OpenCLABC;

var C := CQ(5);

CLContext.Default.SyncInvoke(
  CombineConvAsyncQueue(a->a, |C,C.ThenConvert(x->x*x, false)|, false).Print
).Println;