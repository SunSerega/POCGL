uses OpenCLABC;

begin
  
  var b := new Buffer( 3*sizeof(integer) );
  
  // Код с очередями
  
  var Q_BuffWrite :=
    ( b.NewQueue.WriteValue(1, 0*sizeof(integer) ) as CommandQueue<Buffer> ) *
    ( b.NewQueue.WriteValue(5, 1*sizeof(integer) ) as CommandQueue<Buffer> ) *
    ( b.NewQueue.WriteValue(7, 2*sizeof(integer) ) as CommandQueue<Buffer> )
  ;
  
  var A := new integer[3];
  var Q_BuffRead := b.NewQueue.ReadArray(A) as CommandQueue<Buffer>;
  
  var Q_Otp := HPQ(()->
  begin
    A.Println;
  end);
  
  Context.Default.SyncInvoke(
    Q_BuffWrite +
    Q_BuffRead +
    Q_Otp
  );
  
  // Этот же код ещё раз, но без явных очередей
  // Неявно - каждый метод .Write*** и .Read*** всё равно создаёт по очереди
  // Такая запись короче, но выполняется медленнее
  
  System.Threading.Tasks.Parallel.Invoke(
    ()->b.WriteValue(1, 0*sizeof(integer) ),
    ()->b.WriteValue(5, 1*sizeof(integer) ),
    ()->b.WriteValue(7, 2*sizeof(integer) )
  );
  
  b.ReadArray(A);
  
  A.Println;
  
end.