uses OpenCLABC;

const W = 10;

begin
  Randomize(0);
  
  var B := new MemorySegment(W*W*sizeof(real));
  B.WriteArray2&<real>(MatrRandomReal(W,W).Println);
  
  var BRes := new MemorySegment(B.Size);
  
  var code := new ProgramCode(Context.Default, ReadAllText('2D.cl'));
  var k := code['CalcTick'];
  
  //ToDo #2511 - убрать все KernelArg.From
  var Q_1Cycle: CommandQueueBase := k.NewQueue
    // Сначала читаем предыдущее состояние из B и пишем результат в BRes
    .AddExec2(W,W,
      KernelArg.FromMemorySegment(B), KernelArg.FromMemorySegment(BRes),
      KernelArg.FromRecord(W)
    )
    // А затем то же самое в обратную сторону
    .AddExec2(W,W,
      KernelArg.FromMemorySegment(BRes), KernelArg.FromMemorySegment(B),
      KernelArg.FromRecord(W)
    )
  ;
  
  var Marker := new WaitMarker;
  var Q_1CycleAndOtp: CommandQueueBase := k.NewQueue
    
    .AddExec2(W,W,
      KernelArg.FromMemorySegment(B), KernelArg.FromMemorySegment(BRes),
      KernelArg.FromRecord(W)
    )
    
    .AddQueue(Marker)
    .AddExec2(W,W,
      KernelArg.FromMemorySegment(BRes), KernelArg.FromMemorySegment(B),
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