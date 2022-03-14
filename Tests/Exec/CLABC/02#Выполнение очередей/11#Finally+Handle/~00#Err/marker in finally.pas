## uses OpenCLABC;

begin
  var M := WaitMarker.Create;
  var t := Context.Default.BeginInvoke(WaitFor(M)+HPQ(()->Writeln(1)));
  Context.Default.SyncInvoke(
    (HPQ(()->raise new Exception('ErrorOK')) >= M)
    .HandleWithoutRes(e->
    begin
      Sleep(50);
      Writeln(e.Message);
      Result := true;
    end)
  );
  t.Wait;
end;
Writeln('-'*10);
begin
  var QErr := HPQ(()->raise new Exception('ErrorOK')).ThenFinallyMarkerSignal;
  var t := Context.Default.BeginInvoke(WaitFor(QErr)+HPQ(()->Writeln(2)));
  Context.Default.SyncInvoke(QErr.HandleWithoutRes(e->
  begin
    Sleep(100);
    Writeln(e.Message);
    Result := true;
  end));
  t.Wait;
end;