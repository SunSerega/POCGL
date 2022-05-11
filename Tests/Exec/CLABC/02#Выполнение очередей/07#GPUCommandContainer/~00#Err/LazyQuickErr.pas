## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CLMemoryCCQ.Create(HTFQ(()->new CLMemory(1))).ThenWriteArray1(HQFQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);