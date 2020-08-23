uses OpenCLABC;

begin
  var q: CommandQueueBase := HFQ(()->5);
  Context.Default.SyncInvoke(
    CombineSyncQueueBase(SeqFill(2,q))
  ).ToString.Println;
end.