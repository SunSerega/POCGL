## uses OpenCLABC;

var P := new ParameterQueue<integer>('P');

CLContext.Default.SyncInvoke(
  CombineConvAsyncQueue(a->a, |P,P.ThenConvert(x->x*x, false)|, false),
P.NewSetter(5)).Println;