## uses OpenCLABC;

var q := CLMemory.Create(1).NewQueue
  .ThenQuickProc(mem->Println(1))
  .ThenQuickProc(mem->Println(2))
;

CLContext.Default.SyncInvoke(
  q.ThenQueue(q)
);