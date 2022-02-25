## uses OpenCLABC;

var empty_q := new ConstQueue<object>(nil);
Writeln(CombineConvSyncQueue(a->a.JoinToString, empty_q, empty_q));
Writeln(CombineConvAsyncQueue(a->a.JoinToString, empty_q, empty_q));