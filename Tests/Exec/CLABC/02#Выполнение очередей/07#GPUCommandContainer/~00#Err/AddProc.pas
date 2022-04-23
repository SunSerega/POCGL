## uses OpenCLABC;

var mem := new CLMemory(1);
Context.Default.SyncInvoke(
  mem.NewQueue
  .ThenThreadedProc(b->raise new Exception($'{mem}, TestOK'))
);