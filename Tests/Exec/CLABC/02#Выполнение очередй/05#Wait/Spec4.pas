uses OpenCLABC;

begin
  var M1 := new MarkerQueue;
  var Q1 := HPQ(()->
  begin
    Sleep(10);
    lock output do Writeln('Выполнилась Q1');
  end) + M1;
  
  var M2 := new MarkerQueue;
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2')) + M2;
  
  var M3 := new MarkerQueue;
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3')) + M3;
  
  var M4 := new MarkerQueue;
  var Q4 := HPQ(()->lock output do Writeln('Выполнилась Q4')) + M4;
  
  var M5 := new MarkerQueue;
  var Q5 := HPQ(()->lock output do Writeln('Выполнилась Q5')) + M5;
  
  var t1 := Context.Default.BeginInvoke(
    ( WaitFor(M1)+Q2 ) *
    ( WaitFor(M1)+Q3 )
  );
  var t2 := Context.Default.BeginInvoke(
    ( WaitFor(M1)+WaitFor(M2)+Q4 ) *
    ( WaitFor(M1)+WaitFor(M3)+Q5 )
  );
  // Каждый вызов Q1 тут - активирует по 1 WaitFor(Q1) в каждом CLTask
  Context.Default.SyncInvoke(
    ( Q1 + WaitForAll(M2, M4) ) +
    ( Q1 + WaitForAll(M3, M5) )
  );
  
  t1.Wait;
  t2.Wait;
end.