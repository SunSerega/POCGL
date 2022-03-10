## uses OpenCLABC;

var S := new MemorySegment(8);

Context.Default.SyncInvoke(
  (S.NewQueue.AddWriteValue&<byte>(1,0) * S.NewQueue.AddWriteValue&<word>(2,1)) +
  S.NewQueue.AddWriteValue&<real>(3,0)
);