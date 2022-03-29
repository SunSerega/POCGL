## uses OpenCLABC;

Context.Default.SyncInvoke(
  CLMemorySegment.Create(1).NewQueue.ThenWriteArray1(HFQQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);