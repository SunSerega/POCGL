uses OpenCLABC;

begin
  var M1 := new WaitMarker;
  var M2 := new WaitMarker;
  
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
  
  var mem := new MemorySegment(1);
  mem.NewQueue.AddWait(M1).Println;
  (M1+mem.NewQueue.AddWait(M1)).Println;
  (mem.NewQueue.AddWait(M1)+M1).Println;
  mem.NewQueue.AddWaitAll(M1).Println;
  mem.NewQueue.AddWaitAny(M1).Println;
  mem.NewQueue.AddWaitAll(M1,M2).Println;
  mem.NewQueue.AddWaitAny(M1,M2).Println;
  
end.