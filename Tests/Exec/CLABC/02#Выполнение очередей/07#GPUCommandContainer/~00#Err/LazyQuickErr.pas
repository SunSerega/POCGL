## uses OpenCLABC;

Context.Default.SyncInvoke(
  CLMemoryCCQ.Create(HFQ(()->new CLMemory(1))).ThenWriteArray1(HFQQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);