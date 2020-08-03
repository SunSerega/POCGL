uses OpenCLABC;

begin
  var Q1 := HPQ(()->
  begin
    Sleep(10);
    lock output do Writeln('Выполнилась Q1');
  end);
  
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2'));
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  
  var Q4 := HPQ(()->lock output do Writeln('Выполнилась Q4'));
  var Q5 := HPQ(()->lock output do Writeln('Выполнилась Q5'));
  
  var t1 := Context.Default.BeginInvoke(
    ( WaitFor(Q1)+Q2 ) *
    ( WaitFor(Q1)+Q3 )
  );
  var t2 := Context.Default.BeginInvoke(
    ( WaitFor(Q1)+WaitFor(Q2)+Q4 ) *
    ( WaitFor(Q1)+WaitFor(Q3)+Q5 )
  );
  // Каждый вызов Q1 тут - активирует по 1 WaitFor(Q1) в каждом CLTask
  Context.Default.SyncInvoke(
    ( Q1 + WaitForAll(Q2,Q4) ) +
    ( Q1 + WaitForAll(Q3,Q5) )
  );
  
  t1.Wait;
  t2.Wait;
end.