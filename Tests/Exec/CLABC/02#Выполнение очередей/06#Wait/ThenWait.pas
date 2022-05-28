## uses OpenCLABC;

var M := WaitMarker.Create;
var t := CLContext.Default.BeginInvoke(
  HTFQ(()->5).ThenWaitFor(M)
);

M.SendSignal;
t.WaitRes.Println;