## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CLMemoryCCQ.Create(HFQ(()->new CLMemory(1))).ThenWriteArray1(HFQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end, false))
);