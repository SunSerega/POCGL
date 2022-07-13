## uses OpenCLABC;

var Q := HFQ(()->5, false).Multiusable;
var M := WaitMarker.Create;

var t := CLContext.Default.BeginInvoke(
  WaitFor(M) + HPQ(()->lock output do 'Got signal of M'.Println)
);
var res := CLContext.Default.SyncInvoke( Q+M+Q );

t.Wait;
res.Println;