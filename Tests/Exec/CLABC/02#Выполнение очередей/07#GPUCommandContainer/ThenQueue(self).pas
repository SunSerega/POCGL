## uses OpenCLABC;

var m := new CLMemory(1);
var q := m.MakeCCQ
  .ThenProc(mem->Println(1), false)
  .ThenProc(mem->Println(2), false)
;

CLContext.Default.SyncInvoke(
  q.ThenQueue(q)
);

m.Dispose;