## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CLMemory.Create(1).MakeCCQ.ThenWriteArray1(HQFQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end))
);