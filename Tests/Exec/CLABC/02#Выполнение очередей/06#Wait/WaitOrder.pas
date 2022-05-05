## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

var mre := new System.Threading.ManualResetEventSlim(false);
var t := Context.Default.BeginInvoke(
  (
    WaitFor(M1 and M2) +
    HQPQ(()->Println(2))
  ) *
  (
    WaitFor(M1) +
    HQPQ(()->Println(1)) +
    HQPQ(mre.Set)
  )
);

M1.SendSignal;
mre.Wait;
M2.SendSignal;
M1.SendSignal;

t.Wait;