uses OpenCLABC;

begin
  var Q1 := HFQ(()->1);
  var Q2 := HFQ(()->1);
  
  WaitFor(Q1).Println;
  (Q1+WaitFor(Q1)).Println;
  (WaitFor(Q1)+Q1).Println;
  WaitForAll(Q1).Println;
  WaitForAny(Q1).Println;
  WaitForAll(Q1,Q2).Println;
  WaitForAny(Q1,Q2).Println;
  
  Writeln('='*30);
  Writeln;
  
  var Q0: CommandQueueBase := nil as object;
  Q0.ThenWaitFor(Q1).Println;
  (Q1+Q0.ThenWaitFor(Q1)).Println;
  (Q0.ThenWaitFor(Q1)+Q1).Println;
  Q0.ThenWaitForAll(Q1).Println;
  Q0.ThenWaitForAny(Q1).Println;
  Q0.ThenWaitForAll(Q1,Q2).Println;
  Q0.ThenWaitForAny(Q1,Q2).Println;
  
  Writeln('='*30);
  Writeln;
  
  var b := new Buffer(1);
  b.NewQueue.AddWait(Q1).Println;
  (Q1+b.NewQueue.AddWait(Q1)).Println;
  (b.NewQueue.AddWait(Q1)+Q1).Println;
  b.NewQueue.AddWaitAll(Q1).Println;
  b.NewQueue.AddWaitAny(Q1).Println;
  b.NewQueue.AddWaitAll(Q1,Q2).Println;
  b.NewQueue.AddWaitAny(Q1,Q2).Println;
  
end.