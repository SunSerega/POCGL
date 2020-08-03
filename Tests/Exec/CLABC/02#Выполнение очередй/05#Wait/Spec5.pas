uses OpenCLABC;

begin
  var Q1 := HPQ(()->lock output do Writeln('Выполнилась Q1'));
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2'));
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  var Q4 := HPQ(()->lock output do Writeln('Выполнилась Q4'));
  
  var t1 := Context.Default.BeginInvoke(
    ( WaitFor(Q1)+Q3 ) *
    ( WaitFor(Q1)+Q4 )
  );
  var t2 := Context.Default.BeginInvoke(WaitFor(Q1)+WaitFor(Q3)+Q2+Q1);
  Context.Default.SyncInvoke(Q1);
  
  t1.Wait;
  t2.Wait;
end.