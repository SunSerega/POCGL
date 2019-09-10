uses OpenCLABC;

begin
  
  var q1 := HPQ(()->
  begin
    // lock надо чтоб при параллельном выполнении 2 потока не пытались использовать вывод одновременно. Иначе выйдет каша
    lock output do writeln('Очередь 1 начала выполняться');
    Sleep(500);
    lock output do writeln('Очередь 1 закончила выполняться');
  end);
  var q2 := HPQ(()->
  begin
    lock output do writeln('Очередь 2 начала выполняться');
    Sleep(500);
    lock output do writeln('Очередь 2 закончила выполняться');
  end);
  
  writeln('Последовательное выполнение:');
  Context.Default.SyncInvoke( q1 + q2 );
  
  writeln;
  writeln('Параллельное выполнение:');
  Context.Default.SyncInvoke( q1 * q2 );
  
end.