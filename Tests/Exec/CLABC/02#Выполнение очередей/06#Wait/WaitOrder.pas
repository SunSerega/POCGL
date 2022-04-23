## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

var t := Context.Default.BeginInvoke(
  (WaitFor(M1 and M2) + HQPQ(()->Println(2))) *
  (WaitFor(M1) + HQPQ(()->Println(1)))
);

M1.SendSignal;
Sleep(10);
M2.SendSignal;
Sleep(10);
M1.SendSignal;

t.Wait;