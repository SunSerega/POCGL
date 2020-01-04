uses OpenCLABC;

begin
  var b := new Buffer(10*sizeof(integer));
  // Очищаем весь буфер ноликами, чтобы не было мусора
  b.FillValue(0);
  
  var q := b.NewQueue
    
    // Второй параметр AddWriteValue - отступ от начала буфера
    // Он имеет тип integer, а значит можно передать и CommandQueue<integer>
    // Таким образом, в параметр сохраняется алгоритм, а не готовое значение
    // Поэтому 3 вызова ниже могут получится с 3 разными отступами
    .AddWriteValue(5, HFQ(()-> Random(0,9)*sizeof(integer) ))
    
  as CommandQueue<Buffer>;
  
  Context.Default.SyncInvoke(q);
  Context.Default.SyncInvoke(q);
  Context.Default.SyncInvoke(q);
  
  b.GetArray1&<integer>.Println;
  
end.