## uses OpenCLABC;

var Q := HTFQ(()->5);
var M := WaitMarker.Create;

var t := CLContext.Default.BeginInvoke(
Q.ThenWaitFor(M)
);
M.SendSignal;

t.WaitRes.Println;