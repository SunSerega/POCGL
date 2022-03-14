## uses OpenCLABC;

Context.Default.SyncInvoke(
  MemorySegmentCCQ.Create(HFQ(()->new MemorySegment(1))).AddWriteArray1(HFQQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);