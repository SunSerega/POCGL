uses OpenCLABC;

begin
  var Q1 := HPQ(()->
  begin
    Sleep(10);
    lock output do Writeln('Выполнилась Q1');
  end).ThenWaitMarker;
  
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2')).ThenWaitMarker;
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3')).ThenWaitMarker;
  
  var Q4 := HPQ(()->lock output do Writeln('Выполнилась Q4')).ThenWaitMarker;
  var Q5 := HPQ(()->lock output do Writeln('Выполнилась Q5')).ThenWaitMarker;
  
  var t1 := Context.Default.BeginInvoke(
    ( WaitFor(Q1)+Q2 ) *
    ( WaitFor(Q1)+Q3 )
  );
  var t2 := Context.Default.BeginInvoke(
    ( WaitFor(Q1 and Q2) + Q4 ) *
    ( WaitFor(Q1 and Q3) + Q5 )
  );
  // Каждый вызов Q1 тут - активирует по 1 WaitFor(Q1) в каждом CLTask
  Context.Default.SyncInvoke(
    Q1 + WaitFor(Q2 and Q4) +
    Q1 + WaitFor(Q3 and Q5)
  );
  
  t1.Wait;
  t2.Wait;
end.