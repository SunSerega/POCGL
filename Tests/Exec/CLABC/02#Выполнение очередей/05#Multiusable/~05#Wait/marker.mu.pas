## uses OpenCLABC;

var M := WaitMarker.Create;
var MQ := CommandQueueBase(M).Multiusable;

var mre := new System.Threading.ManualResetEventSlim(false);

var t := CLContext.Default.BeginInvoke(
  WaitFor(M) + HPQ(()->Println(1)) +
  HPQ(mre.Set, false) +
  WaitFor(M) + HPQ(()->Println(2))
);

CLContext.Default.SyncInvoke( MQ+MQ );
mre.Wait;
Println(1.5);
M.SendSignal;

t.Wait;