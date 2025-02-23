## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HFQ(()->new CLMemory(1)).MakeCCQ
  .ThenWriteArray1(HFQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end, need_own_thread := false))
);