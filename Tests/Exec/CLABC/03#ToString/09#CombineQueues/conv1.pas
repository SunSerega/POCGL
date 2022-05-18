## uses OpenCLABC;

var empty_q := new ConstQueue<object>(nil);
CombineQuickConvSyncQueue(a->a, empty_q, empty_q).Println;
CombineQuickConvAsyncQueue(a->a, empty_q, empty_q).Println;