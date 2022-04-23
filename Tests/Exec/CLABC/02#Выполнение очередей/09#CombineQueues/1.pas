## uses OpenCLABC;

var q: CommandQueueBase := HTFQ(()->5);
Context.Default.SyncInvoke(
  CombineSyncQueueBase(ArrFill(2,q)).Cast&<integer>.Print
).Println;