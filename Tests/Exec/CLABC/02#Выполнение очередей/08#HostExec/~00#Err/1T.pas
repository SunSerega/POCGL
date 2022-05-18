## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HTPQ(()->raise new Exception('TestOK')) +
  HTPQ(()->raise new Exception('TestError'))
);