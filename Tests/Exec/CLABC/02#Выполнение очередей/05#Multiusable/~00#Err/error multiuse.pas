## uses OpenCLABC;

var Q := HPQ(()->raise new Exception('TestOK'), false).Multiusable;
CLContext.Default.SyncInvoke(Q*Q+Q);