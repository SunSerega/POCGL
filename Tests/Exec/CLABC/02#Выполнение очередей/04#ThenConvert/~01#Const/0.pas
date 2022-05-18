## uses OpenCLABC;
var cq := new ConstQueue<integer>(5);

CLContext.Default.SyncInvoke(
  cq.ThenConvert(i->i*i)
).Println;

CLContext.Default.SyncInvoke(
  cq.ThenConvert((i,c)->(i*i*i, c=CLContext.Default))
).Println;