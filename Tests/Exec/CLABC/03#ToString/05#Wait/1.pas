uses OpenCLABC;

begin
  var M1 := new MarkerQueue;
  var M2 := new MarkerQueue;
  
  WaitFor(M1).Println;
  (M1+WaitFor(M1)).Println;
  (WaitFor(M1)+M1).Println;
  WaitForAll(M1).Println;
  WaitForAny(M1).Println;
  WaitForAll(M1,M2).Println;
  WaitForAny(M1,M2).Println;
  
  Writeln('='*30);
  Writeln;
  
  var Q0: CommandQueueBase := nil as object;
  Q0.ThenWaitFor(M1).Println;
  (M1+Q0.ThenWaitFor(M1)).Println;
  (Q0.ThenWaitFor(M1)+M1).Println;
  Q0.ThenWaitForAll(M1).Println;
  Q0.ThenWaitForAny(M1).Println;
  Q0.ThenWaitForAll(M1,M2).Println;
  Q0.ThenWaitForAny(M1,M2).Println;
  
  Writeln('='*30);
  Writeln;
  
  var b := new Buffer(1);
  b.NewQueue.AddWait(M1).Println;
  (M1+b.NewQueue.AddWait(M1)).Println;
  (b.NewQueue.AddWait(M1)+M1).Println;
  b.NewQueue.AddWaitAll(M1).Println;
  b.NewQueue.AddWaitAny(M1).Println;
  b.NewQueue.AddWaitAll(M1,M2).Println;
  b.NewQueue.AddWaitAny(M1,M2).Println;
  
end.