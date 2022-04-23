## uses OpenCLABC;

Context.Default.SyncInvoke(
  HTPQ(()->raise new Exception('TestOK')) +
  HTPQ(()->raise new Exception('TestError'))
);