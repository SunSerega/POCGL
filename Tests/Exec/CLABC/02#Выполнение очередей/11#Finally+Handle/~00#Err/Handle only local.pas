## uses OpenCLABC;

Context.Default.SyncInvoke(
  HQPQ(()->raise new Exception('TestOK')) +
  HQPQ(()->begin end).HandleWithoutRes(e->e.Message.Println<>nil)
);