## uses OpenCLABC;

var q: CLMemorySegmentCCQ := CLMemorySegment.Create(1).NewQueue.ThenQuickProc(mem->Writeln(1));

Context.Default.SyncInvoke(q.ThenQuickProc(mem->Writeln(2)));
Writeln('-'*10);
Context.Default.SyncInvoke(q.ThenQuickProc(mem->Writeln(3)));
Writeln('-'*10);

Context.Default.SyncInvoke(q.ThenQuickProc(mem->Writeln(4)).ThenQuickProc(mem->Writeln(5)));
Writeln('-'*10);
Context.Default.SyncInvoke(q);
Writeln('-'*10);