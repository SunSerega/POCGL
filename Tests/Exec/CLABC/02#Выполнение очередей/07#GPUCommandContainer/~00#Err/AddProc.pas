uses OpenCLABC;

begin
  var mem := new CLMemory(1);
  Context.Default.SyncInvoke(
    mem.NewQueue
    .ThenProc(b->raise new Exception($'{mem}, TestOK'))
  );
end.