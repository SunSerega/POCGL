## uses OpenCLABC;

var M := WaitMarker.Create;

var mre := new System.Threading.ManualResetEventSlim(false);
CLContext.Default.SyncInvoke(
  HTPQ(()->
  begin
    mre.Wait;
    'M'.Println;
    M.SendSignal;
  end) *
  HTFQ(()->5).ThenQuickUse(x->
  begin
    $'/\{x}/\'.Println;
    mre.Set;
  end).ThenWaitFor(M)
).Println;