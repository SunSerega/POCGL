## uses OpenCLABC;
var cq := new ConstQueue<integer>(5);

Context.Default.SyncInvoke(
  cq.ThenConvert(i->i*i)
).Println;

Context.Default.SyncInvoke(
  cq.ThenConvert((i,c)->(i*i*i, c=Context.Default))
).Println;