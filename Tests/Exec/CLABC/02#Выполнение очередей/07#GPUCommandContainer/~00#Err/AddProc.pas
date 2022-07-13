## uses OpenCLABC;

var mem := new CLMemory(1);
CLContext.Default.SyncInvoke(
  mem.MakeCCQ
  .ThenProc(b->raise new Exception($'{mem}, TestOK'))
);