## uses OpenCLABC;

var Qs := HQPQ(()->raise new Exception('TestOK')).Multiusable;
Context.Default.SyncInvoke(Qs()*Qs()+Qs());