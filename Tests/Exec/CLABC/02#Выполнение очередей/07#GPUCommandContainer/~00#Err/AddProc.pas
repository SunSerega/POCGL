## uses OpenCLABC;

var mem := new CLMemory(1);
CLContext.Default.SyncInvoke(
  mem.NewQueue
  .ThenThreadedProc(b->raise new Exception($'{mem}, TestOK'))
);