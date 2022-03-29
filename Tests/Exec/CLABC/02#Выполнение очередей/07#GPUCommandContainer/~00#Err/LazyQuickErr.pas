## uses OpenCLABC;

Context.Default.SyncInvoke(
  CLMemorySegmentCCQ.Create(HFQ(()->new CLMemorySegment(1))).ThenWriteArray1(HFQQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);