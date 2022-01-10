## uses OpenCLABC;

var Qs := HFQ(()->5).Multiusable;
var M := WaitMarker.Create;

var t := Context.Default.BeginInvoke(
  WaitFor(M) + HPQ(()->lock output do Writeln('Got signal of M'))
);
var res := Context.Default.SyncInvoke( Qs()+M+Qs() );

t.Wait;
res.Println;