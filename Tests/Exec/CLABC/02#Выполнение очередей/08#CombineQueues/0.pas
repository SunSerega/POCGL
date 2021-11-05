uses OpenCLABC;

begin
  
  Context.Default.SyncInvoke(
    CombineSyncQueue(
      res->res,
      SeqGen(10, i->HFQ(()->i), 1)
    )
  ).Println;
  
  Context.Default.SyncInvoke(
    CombineSyncQueue2((i,s)->(i,s),
      HFQ(()->5),
      HFQ(()->'abc')
    )
  ).ToString.Println;
  
  Context.Default.SyncInvoke(
    CombineAsyncQueue(
      res->res,
      SeqGen(10, i->HFQ(()->i), 1)
    )
  ).Println;
  
  Context.Default.SyncInvoke(
    CombineAsyncQueue2((i,s)->(i,s),
      HFQ(()->5),
      HFQ(()->'abc')
    )
  ).ToString.Println;
  
end.