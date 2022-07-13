## uses OpenCLABC;

var M := WaitMarker.Create;

var mre := new System.Threading.ManualResetEventSlim(false);
CLContext.Default.SyncInvoke(
  HPQ(()->
  begin
    mre.Wait;
    'M'.Println;
    M.SendSignal;
  end) *
  HFQ(()->5).ThenUse(x->
  begin
    $'/\{x}/\'.Println;
    mre.Set;
  end, false).ThenWaitFor(M)
).Println;