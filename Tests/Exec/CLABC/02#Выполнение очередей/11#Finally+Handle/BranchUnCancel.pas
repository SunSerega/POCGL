## uses OpenCLABC;

var A := HPQ(()->raise new Exception('TestOK'));
var S := new CLArray<byte>(1);

Context.Default.SyncInvoke(
  (A + S.NewQueue.ThenWriteValue(0, HFQ(()->
  begin
    lock output do Writeln('Calculated anyway');
    Result := 0;
  end))).HandleWithoutRes(e->
  begin
    lock output do Writeln(e);
    Result := true;
  end)
);

;