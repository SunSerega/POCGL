## uses OpenCLABC;

procedure Test(M: WaitMarker; QErr: CommandQueueBase);
begin
  var mre := new System.Threading.ManualResetEventSlim(false);
  
  var t := Context.Default.BeginInvoke(
    WaitFor(M) +
    HQPQ(()->
    begin
      Println('Waited');
      mre.Set;
    end)
  );
  
  Context.Default.SyncInvoke(QErr
    .HandleWithoutRes(e->
    begin
      mre.Wait;
      e.Message.Println;
      Result := true;
    end)
  );
  
  t.Wait;
end;

var QErr := HQPQ(()->raise new Exception('TestOK'));
begin
  var M := WaitMarker.Create;
  Test(M, QErr>=M);
end;
begin
  var Q := QErr.ThenFinallyMarkerSignal;
  Test(Q, Q);
end;