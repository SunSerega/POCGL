## uses OpenCLABC;

Context.Default.SyncInvoke(
  HPQ(()->raise new Exception('Excepted error')) +
  HPQ(()->begin end).HandleWithoutRes(e->e.Message.Println<>nil)
);