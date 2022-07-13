## uses OpenCLABC;
var q := HFQ(()->5, false);

CLContext.Default.SyncInvoke(
  q.Cast&<object>.ThenConvert(i->integer(i).Sqr).Cast&<object>
).ToString.Println;

CLContext.Default.SyncInvoke(
  q.Cast&<object>.ThenConvert((i,c)->(integer(i).Sqr.Sqr, c=CLContext.Default)).Cast&<object>
).ToString.Println;