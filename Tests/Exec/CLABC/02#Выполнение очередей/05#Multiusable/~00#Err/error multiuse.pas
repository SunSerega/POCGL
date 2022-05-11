## uses OpenCLABC;

var Qs := HQPQ(()->raise new Exception('TestOK')).Multiusable;
CLContext.Default.SyncInvoke(Qs()*Qs()+Qs());