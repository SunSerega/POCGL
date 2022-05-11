## uses OpenCLABC;

var S := new CLMemory(8);

CLContext.Default.SyncInvoke(
  (S.NewQueue.ThenWriteValue&<byte>(1,0) * S.NewQueue.ThenWriteValue&<word>(2,1)) +
  S.NewQueue.ThenWriteValue&<real>(3,0)
);