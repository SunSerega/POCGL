## uses OpenCLABC;

var Q := HFQ(()->123).Multiusable;
CLContext.Default.SyncInvoke(
  Q.DiscardResult
//  CombineConvAsyncQueueN2((a,b)->(a,b), Q, Q, false)
//    Q*Q
//    Q.ThenUse(x->Println(x), false)*Q
);//.Println;
//EventDebug.ReportEventLogs;