uses OpenCLABC;

begin
  
  var M1 := new MarkerQueue;
  var Q1 := HPQ(()->lock output do Writeln('Выполнилась Q1')) + M1;
  
  var M2 := new MarkerQueue;
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2')) + M2;
  
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  var Q4 := HPQ(()->lock output do Writeln('Выполнилась Q4'));
  
  var t1 := Context.Default.BeginInvoke(
    ( WaitFor(M1)+Q2 ) *
    ( WaitFor(M1)+Q4 )
  );
  var t2 := Context.Default.BeginInvoke(WaitFor(M1)+WaitFor(M2)+Q3+Q1);
  Context.Default.SyncInvoke(Q1);
  
  t1.Wait;
  t2.Wait;
end.