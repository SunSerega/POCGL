## uses OpenCLABC;

var S := new CLMemory(8);

CLContext.Default.SyncInvoke(
  (S.MakeCCQ.ThenWriteValue&<byte>(1,0) * S.MakeCCQ.ThenWriteValue&<word>(2,1)) +
  S.MakeCCQ.ThenWriteValue&<real>(3,0)
);

S.Dispose;