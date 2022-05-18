## uses OpenCLABC;

var q: CommandQueueBase := HTFQ(()->5);
CLContext.Default.SyncInvoke(
  CombineSyncQueueBase(ArrFill(2,q)).Cast&<integer>.Print
).Println;