## uses OpenCLABC;

Context.Default.SyncInvoke(
  CLMemory.Create(1).NewQueue.ThenWriteArray1(HFQQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);