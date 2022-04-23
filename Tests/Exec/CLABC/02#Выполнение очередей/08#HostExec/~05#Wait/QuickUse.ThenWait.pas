## uses OpenCLABC;

var M := WaitMarker.Create;

Context.Default.SyncInvoke(
  HTPQ(()->
  begin
    Sleep(30);
    lock output do 'M'.Println;
    M.SendSignal;
  end) *
  HTFQ(()->5).ThenQuickUse(x->lock output do $'/\{x}/\'.Println).ThenWaitFor(M)
).Println;