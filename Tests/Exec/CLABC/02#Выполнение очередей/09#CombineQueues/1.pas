## uses OpenCLABC;

var Q: CommandQueueBase := HFQ(()->5);
CLContext.Default.SyncInvoke(
  CombineSyncQueue(ArrFill(2,Q)).Cast&<integer>.Print
).Println;