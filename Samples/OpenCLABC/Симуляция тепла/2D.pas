uses OpenCLABC;

const W = 10;

begin
  Randomize(0);
  
  var B := new Buffer(W*W*sizeof(real));
  B.WriteArray2&<real>(MatrRandomReal(W,W).Println);
  
  var BRes := new Buffer(B.Size);
  
  var code := new ProgramCode(Context.Default, ReadAllText('2D.cl'));
  var k := code['CalcTick'];
  
  var Q_1Cycle: CommandQueueBase := k.NewQueue
    // Сначала читаем предыдущее состояние из B и пишем результат в BRes
    .AddExec2(W,W,
      B, BRes,
      KernelArg.FromRecord(W)
    )
    // А затем то же самое в обратную сторону
    .AddExec2(W,W,
      BRes, B,
      KernelArg.FromRecord(W)
    )
  ;
  
  // В будущем сделаю более красивый способ делать маркеры
  var Marker: CommandQueueBase := nil as object;
  var Q_1CycleAndOtp: CommandQueueBase := k.NewQueue
    
    .AddExec2(W,W,
      B, BRes,
      KernelArg.FromRecord(W)
    )
    
    .AddQueue(Marker)
    .AddExec2(W,W,
      BRes, B,
      KernelArg.FromRecord(W)
    )
  * // Читаем паралельно с вторым выполнением
    // code['CalcTick'] не меняет состояние первого буфера, а только читает из него, поэтому так можно
    (
      WaitFor(Marker) +
      BRes.NewQueue
      .AddGetArray2&<real>(W,W)
      .ThenConvert(res->
      begin
        Writeln('='*100);
        Result := res.Println;
      end)
    )
  ;
  
  var Q_FullCycle := CombineSyncQueueBase(
    // Сначала несколько раз выполняем цикл без вывода, чтобы не читать состояние на каждой точке
    SeqFill(4, Q_1Cycle)
    .Append(Q_1CycleAndOtp)
  );
  
  Context.Default.SyncInvoke(CombineSyncQueueBase(
    SeqFill(20, Q_FullCycle)
  ));
  
end.