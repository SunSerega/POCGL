## uses OpenCLABC;

begin
  var M := WaitMarker.Create;
  var t := Context.Default.BeginInvoke(WaitFor(M)+HQPQ(()->Println(1)));
  Context.Default.SyncInvoke(
    (HQPQ(()->raise new Exception('TestOK')) >= M)
    .HandleWithoutRes(e->
    begin
      Sleep(30);
      e.Message.Println;
      Result := true;
    end)
  );
  t.Wait;
end;
('-'*30).Println;
begin
  var QErr := HQPQ(()->raise new Exception('TestOK')).ThenFinallyMarkerSignal;
  var t := Context.Default.BeginInvoke(WaitFor(QErr)+HQPQ(()->Println(2)));
  Context.Default.SyncInvoke(QErr.HandleWithoutRes(e->
  begin
    Sleep(30);
    e.Message.Println;
    Result := true;
  end));
  t.Wait;
end;