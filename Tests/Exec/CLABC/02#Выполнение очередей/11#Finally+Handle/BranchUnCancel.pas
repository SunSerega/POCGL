## uses OpenCLABC;

var A := HPQ(()->raise new Exception('TestOK'));
var S := new CLArray<byte>(1);

//System.Threading.Thread.Create(()->
//begin
//  Sleep(1000);
//  EventDebug.ReportRefCounterInfo;
//end).Start;

Context.Default.SyncInvoke(
  (A + S.NewQueue.AddWriteValue(0, HFQ(()->
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