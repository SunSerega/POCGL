## uses OpenCLABC;

var empty_q := new ConstQueue<object>(nil);
Writeln(CombineSyncQueue(a->a.JoinToString, empty_q, empty_q));
Writeln(CombineAsyncQueue(a->a.JoinToString, empty_q, empty_q));