## uses OpenCLABC;

var Qs := HQFQ(()->5).Multiusable;
var M := WaitMarker.Create;

var t := CLContext.Default.BeginInvoke(
  WaitFor(M) + HTPQ(()->lock output do 'Got signal of M'.Println)
);
var res := CLContext.Default.SyncInvoke( Qs()+M+Qs() );

t.Wait;
res.Println;