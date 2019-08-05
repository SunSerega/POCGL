uses OpenCLABC;

begin
  var N := ReadInteger('Введите размер буфера:');
  var b := new Buffer( N*sizeof(integer) );
  
  var Q_RNG_val := HFQ(()->
  begin
    Result := Random(1,100);
  end);
  
  // .WriteValue принимает значение размерного типа
  // Но вместо него - мы передали очередь (CommandQueue это класс, то есть точно не размерный тип)
  // Так можно, потому что возвращаемое значение очереди - размерный тип (integer)
  var Q_RNG_FillBuff := b.NewQueue.WriteValue(Q_RNG_val, 0) as CommandQueue<Buffer>;
  
  for var i := 1 to N-1 do // 0 пропускаем, потому что его уже добавили его выше
    Q_RNG_FillBuff *= b.NewQueue.WriteValue(Q_RNG_val.Clone, i*sizeof(integer) ) as CommandQueue<Buffer>; // .Clone необходимо потому что одна и та же очередь не может выполнятся в нескольких местах одновременно
  
  // Вообще, это далеко не самый эффективный и красивый способ заполнить буфер
  // В идеале - это надо делать карнелом
  
  Context.Default.SyncInvoke(Q_RNG_FillBuff);
  
  b.GetArray1&<integer>(N).Println;
end.