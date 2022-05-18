## uses OpenCLABC;

var A := HTPQ(()->raise new Exception('TestOK'));
var S := new CLArray<byte>(1);

CLContext.Default.SyncInvoke(
  (A + S.NewQueue.ThenWriteValue(0, HQFQ(()->
  begin
    lock output do Println('Calculated anyway');
    Result := 0;
  end))).HandleWithoutRes(e->
  begin
    lock output do e.Message.Println;
    Result := true;
  end)
);

;