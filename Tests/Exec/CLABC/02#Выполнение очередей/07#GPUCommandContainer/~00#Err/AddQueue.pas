## uses OpenCLABC;

var mem := new CLMemory(1);
CLContext.Default.SyncInvoke(
  mem.MakeCCQ
  .ThenQueue(HPQ(()->raise new Exception($'{mem}, TestOK'), false))
);