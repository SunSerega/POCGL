## uses OpenCLABC;

procedure Test(M: WaitMarker; QErr: CommandQueueBase);
begin
  var mre := new System.Threading.ManualResetEventSlim(false);
  
  var t := CLContext.Default.BeginInvoke(
    WaitFor(M) +
    HPQ(()->
    begin
      Println('Waited');
      mre.Set;
    end, false)
  );
  
  CLContext.Default.SyncInvoke(QErr
    .HandleWithoutRes(e->
    begin
      mre.Wait;
      e.Message.Println;
      Result := true;
    end)
  );
  
  t.Wait;
end;

var QErr := HPQ(()->raise new Exception('TestOK'), false);
begin
  var M := WaitMarker.Create;
  Test(M, QErr>=M);
end;
begin
  var Q := QErr.ThenFinallyMarkerSignal;
  Test(Q, Q);
end;