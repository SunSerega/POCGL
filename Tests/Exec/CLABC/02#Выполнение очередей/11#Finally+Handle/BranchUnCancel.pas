## uses OpenCLABC;

var A := HPQ(()->raise new Exception('TestOK'));
var S := new CLArray<byte>(1);

CLContext.Default.SyncInvoke(
  (A + S.MakeCCQ.ThenWriteValue(0, HFQ(()->
  begin
    lock output do Println('Calculated anyway');
    Result := 0;
  end, false))).HandleWithoutRes(e->
  begin
    lock output do e.Message.Println;
    Result := true;
  end)
);

;