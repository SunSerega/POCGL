uses OpenCLABC;

begin
  var M := new MarkerQueue;
  
  var Q1 := HPQ(()->
  begin
    Sleep(10);
    lock output do Writeln('Выполнилась Q1');
  end)+M;
  
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2'));
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  
  Context.Default.SyncInvoke(
    (Q1+Q1) *
    (WaitFor(M)+Q2) *
    (WaitFor(M)+Q3)
  );
  
end.