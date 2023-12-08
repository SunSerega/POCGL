## uses OpenCLABC;

var m := new CLMemory(1);
CLContext.Default.SyncInvoke(
  m.MakeCCQ
  .ThenWriteArray1(HFQ(()->
  begin
    Result := new byte[0];
    raise new Exception('TestOK');
  end, false))
);
m.Dispose;