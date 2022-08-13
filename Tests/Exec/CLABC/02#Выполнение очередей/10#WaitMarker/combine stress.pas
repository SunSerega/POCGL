## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;
Write(
  CombineWaitAll(SeqFill(100, M1 or M2))
);