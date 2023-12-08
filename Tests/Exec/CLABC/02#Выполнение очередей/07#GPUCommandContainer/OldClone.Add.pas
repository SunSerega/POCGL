## uses OpenCLABC;

var m := new CLMemory(1);
var q: CLMemoryCCQ := m.MakeCCQ.ThenProc(mem->Println(1), false);

CLContext.Default.SyncInvoke(q.ThenProc(mem->Println(2), false));
('-'*30).Println;
CLContext.Default.SyncInvoke(q.ThenProc(mem->Println(3), false));
('-'*30).Println;

CLContext.Default.SyncInvoke(q.ThenProc(mem->Println(4), false).ThenProc(mem->Println(5), false));
('-'*30).Println;
CLContext.Default.SyncInvoke(q);
('-'*30).Println;

m.Dispose;