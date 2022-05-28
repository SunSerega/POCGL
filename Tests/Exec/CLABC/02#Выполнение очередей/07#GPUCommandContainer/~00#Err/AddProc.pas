## uses OpenCLABC;

var mem := new CLMemory(1);
CLContext.Default.SyncInvoke(
  mem.MakeCCQ
  .ThenThreadedProc(b->raise new Exception($'{mem}, TestOK'))
);