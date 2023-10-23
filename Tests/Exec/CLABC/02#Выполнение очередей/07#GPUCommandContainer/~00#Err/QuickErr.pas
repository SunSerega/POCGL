## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CLMemory.Create(1).MakeCCQ.ThenWriteArray1(HFQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end, false))
);