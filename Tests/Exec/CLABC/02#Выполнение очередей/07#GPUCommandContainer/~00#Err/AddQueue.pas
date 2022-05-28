## uses OpenCLABC;

var mem := new CLMemory(1);
CLContext.Default.SyncInvoke(
  mem.MakeCCQ
  .ThenQueue(HQPQ(()->raise new Exception($'{mem}, TestOK')))
);