uses OpenCLABC;

begin
  var mem := new MemorySegment(1);
  Context.Default.SyncInvoke(
    mem.NewQueue
    .ThenQueue(HPQ(()->raise new Exception($'{mem}, TestOK')))
  );
end.