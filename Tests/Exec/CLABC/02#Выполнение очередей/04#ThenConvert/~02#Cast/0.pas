## uses OpenCLABC;
var q := HQFQ(()->5);

Context.Default.SyncInvoke(
  q.Cast&<object>.ThenConvert(i->integer(i).Sqr).Cast&<object>
).ToString.Println;

Context.Default.SyncInvoke(
  q.Cast&<object>.ThenConvert((i,c)->(integer(i).Sqr.Sqr, c=Context.Default)).Cast&<object>
).ToString.Println;