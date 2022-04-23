## uses OpenCLABC;

var mem := new CLMemory(1);
Context.Default.SyncInvoke(
  mem.NewQueue
  .ThenQueue(HQPQ(()->raise new Exception($'{mem}, TestOK')))
);