## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HPQ(()->raise new Exception('TestOK'), false) +
  HPQ(()->raise new Exception('TestError'), false)
);