## uses OpenCLABC;

var q: CLMemoryCCQ := CLMemory.Create(1).NewQueue.ThenQuickProc(mem->Println(1));

Context.Default.SyncInvoke(q.ThenQuickProc(mem->Println(2)));
('-'*30).Println;
Context.Default.SyncInvoke(q.ThenQuickProc(mem->Println(3)));
('-'*30).Println;

Context.Default.SyncInvoke(q.ThenQuickProc(mem->Println(4)).ThenQuickProc(mem->Println(5)));
('-'*30).Println;
Context.Default.SyncInvoke(q);
('-'*30).Println;