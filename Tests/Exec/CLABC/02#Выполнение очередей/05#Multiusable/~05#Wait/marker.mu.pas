## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M1s := CommandQueueBase(M1).Multiusable;

var mre := new System.Threading.ManualResetEventSlim(false);

var t := Context.Default.BeginInvoke(
  WaitFor(M1) + HTPQ(()->Println(1)) +
  HQPQ(mre.Set) +
  WaitFor(M1) + HTPQ(()->Println(2))
);

Context.Default.SyncInvoke( M1s()*M1s() );
mre.Wait;
Println(1.5);
M1.SendSignal;

t.Wait;