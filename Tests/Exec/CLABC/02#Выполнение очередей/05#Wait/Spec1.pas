uses OpenCLABC;

begin
  var Q1 := HPQ(()->
  begin
    Sleep(10);
    lock output do Writeln('Выполнилась Q1');
  end).ThenWaitMarker;
  
  var Q2 := HPQ(()->lock output do Writeln('Выполнилась Q2'));
  var Q3 := HPQ(()->lock output do Writeln('Выполнилась Q3'));
  
  var t1 := Context.Default.BeginInvoke(
    (WaitFor(Q1)+Q2) *
    (WaitFor(Q1)+Q3)
  );
  Context.Default.SyncInvoke(Q1+Q1);
  
  t1.Wait; // Чтобы вывести ошибки, если возникнут при выполнении
end.