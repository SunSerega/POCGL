## uses OpenCLABC;

var q := CLMemory.Create(1).MakeCCQ
  .ThenProc(mem->Println(1), false)
  .ThenProc(mem->Println(2), false)
;

CLContext.Default.SyncInvoke(
  q.ThenQueue(q)
);