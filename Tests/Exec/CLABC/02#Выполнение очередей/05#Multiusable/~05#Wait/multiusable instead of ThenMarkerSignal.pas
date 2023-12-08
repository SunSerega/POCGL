## uses OpenCLABC;

var Q := HFQ(()->5, false).Multiusable;
var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

var t := CLContext.Default.BeginInvoke(
  WaitFor(M1) + HPQ(()->lock output do 'Got signal of M'.Println) + M2
);
var res := CLContext.Default.SyncInvoke( Q+M1+WaitFor(M2)+Q );

t.Wait;
res.Println;