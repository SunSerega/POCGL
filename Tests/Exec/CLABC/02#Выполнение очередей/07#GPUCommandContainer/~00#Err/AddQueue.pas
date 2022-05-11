## uses OpenCLABC;

var mem := new CLMemory(1);
CLContext.Default.SyncInvoke(
  mem.NewQueue
  .ThenQueue(HQPQ(()->raise new Exception($'{mem}, TestOK')))
);