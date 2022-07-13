## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

var mre := new System.Threading.ManualResetEventSlim(false);
var t := CLContext.Default.BeginInvoke(
  (
    WaitFor(M1 and M2) +
    HPQ(()->Println(2), false)
  ) *
  (
    WaitFor(M1) +
    HPQ(()->Println(1), false) +
    HPQ(mre.Set, false)
  )
);

M1.SendSignal;
mre.Wait;
M2.SendSignal;
M1.SendSignal;

t.Wait;