## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HQPQ(()->raise new Exception('TestOK')) +
  HQPQ(()->raise new Exception('TestError'))
);