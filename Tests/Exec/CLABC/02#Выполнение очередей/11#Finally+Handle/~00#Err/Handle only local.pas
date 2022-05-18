## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HQPQ(()->raise new Exception('TestOK')) +
  HQPQ(()->begin end).HandleWithoutRes(e->e.Message.Println<>nil)
);