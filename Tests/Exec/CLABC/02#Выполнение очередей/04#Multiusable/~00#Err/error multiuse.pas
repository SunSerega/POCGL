## uses OpenCLABC;

var Qs := HPQ(()->raise new Exception('TestOK')).Multiusable;
Context.Default.SyncInvoke(Qs()*Qs()+Qs());