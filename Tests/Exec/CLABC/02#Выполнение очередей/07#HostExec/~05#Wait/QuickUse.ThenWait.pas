## uses OpenCLABC;

var M := WaitMarker.Create;

Context.Default.SyncInvoke(
  HPQ(()->
  begin
    Sleep(100);
    Writeln('M');
    M.SendSignal;
  end) *
  HFQ(()->5).ThenQuickUse(x->Writeln($'/\{x}/\')).ThenWaitFor(M)
).Println;