## uses OpenCLABC;

Context.Default.SyncInvoke(
  MemorySegment.Create(1).NewQueue.AddWriteArray1(HFQQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);