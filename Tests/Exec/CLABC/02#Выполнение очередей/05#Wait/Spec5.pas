uses OpenCLABC;

begin
  var Q1 := HPQ(()->
  begin
    Sleep(100);
    lock output do Writeln('Выполнилась Q1');
  end).ThenWaitMarker;
  
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2'));
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  
  var t := Context.Default.BeginInvoke(
    ( WaitFor(Q1)+Q2 ) *
    ( WaitFor(Q1)+Q3 )
  );
  Q1.SendSignal;
  Context.Default.SyncInvoke(Q1);
  
  t.Wait;
end.