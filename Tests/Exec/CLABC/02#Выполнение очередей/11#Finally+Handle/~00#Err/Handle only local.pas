## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HPQ(()->raise new Exception('TestOK'), false) +
  HPQ(()->begin end, false).HandleWithoutRes(e->e.Message.Println<>nil)
);