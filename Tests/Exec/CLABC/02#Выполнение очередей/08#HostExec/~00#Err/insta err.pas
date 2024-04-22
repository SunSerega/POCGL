## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  (
    HPQ(()->raise new Exception('TestOK'), need_own_thread:=false) +
    HPQ(()->raise new Exception('TestError'), need_own_thread:=false)
  ).HandleWithoutRes(e->e.Message.Println <> nil)
);