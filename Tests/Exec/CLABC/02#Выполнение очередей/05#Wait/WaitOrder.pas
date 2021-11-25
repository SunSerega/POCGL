## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

var t := Context.Default.BeginInvoke(
  (WaitFor(M1 and M2) + HPQ(()->Writeln(2))) *
  (WaitFor(M1) + HPQ(()->Writeln(1)))
);

M1.SendSignal;
Sleep(10);
M2.SendSignal;
Sleep(10);
M1.SendSignal;

t.Wait;