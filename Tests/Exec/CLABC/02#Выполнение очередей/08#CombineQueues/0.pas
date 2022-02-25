uses OpenCLABC;

begin
  
  Context.Default.SyncInvoke(
    CombineConvSyncQueue(res->res,
      SeqGen(10, i->HFQ(()->i), 1)
    )
  ).Println;
  
  Context.Default.SyncInvoke(
    CombineConvSyncQueueN2((i,s)->(i,s),
      HFQ(()->5),
      HFQ(()->'abc')
    )
  ).ToString.Println;
  
  Context.Default.SyncInvoke(
    CombineConvAsyncQueue(res->res,
      SeqGen(10, i->HFQ(()->i), 1)
    )
  ).Println;
  
  Context.Default.SyncInvoke(
    CombineConvAsyncQueueN2((i,s)->(i,s),
      HFQ(()->5),
      HFQ(()->'abc')
    )
  ).ToString.Println;
  
end.