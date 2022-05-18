## uses OpenCLABC;

var P := new ParameterQueue<integer>('P');

CLContext.Default.SyncInvoke(
  CombineQuickConvAsyncQueue(a->a, P,P.ThenQuickConvert(x->x*x)),
P.NewSetter(5)).Println;