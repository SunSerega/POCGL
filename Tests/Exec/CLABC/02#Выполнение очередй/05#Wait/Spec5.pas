uses OpenCLABC;

begin
  
  var Q1 := HPQ(()->lock output do Writeln('Выполнилась Q1')).ThenWaitMarker;
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2')).ThenWaitMarker;
  
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  var Q4 := HPQ(()->lock output do Writeln('Выполнилась Q4'));
  
  var t1 := Context.Default.BeginInvoke(
    ( WaitFor(Q1)+Q2 ) *
    ( WaitFor(Q1)+Q4 )
  );
  var t2 := Context.Default.BeginInvoke(WaitFor(Q1)+WaitFor(Q2)+Q3+Q1);
  Context.Default.SyncInvoke(Q1);
  
  t1.Wait;
  t2.Wait;
end.