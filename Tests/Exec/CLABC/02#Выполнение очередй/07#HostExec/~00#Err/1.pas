## uses OpenCLABC;

Context.Default.SyncInvoke(
  HPQ(()->raise new Exception('TestOK')) +
  HPQ(()->raise new Exception('TestError'))
);