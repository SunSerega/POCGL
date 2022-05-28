## uses OpenCLABC;

var q: CLMemoryCCQ := CLMemory.Create(1).MakeCCQ.ThenQuickProc(mem->Println(1));

CLContext.Default.SyncInvoke(q.ThenQuickProc(mem->Println(2)));
('-'*30).Println;
CLContext.Default.SyncInvoke(q.ThenQuickProc(mem->Println(3)));
('-'*30).Println;

CLContext.Default.SyncInvoke(q.ThenQuickProc(mem->Println(4)).ThenQuickProc(mem->Println(5)));
('-'*30).Println;
CLContext.Default.SyncInvoke(q);
('-'*30).Println;