## uses OpenCLABC;

var Q := CQ&<object>(nil); 
CombineConvSyncQueue (a->a, |Q, Q|, false).Println;
CombineConvAsyncQueue(a->a, |Q, Q|, false).Println;