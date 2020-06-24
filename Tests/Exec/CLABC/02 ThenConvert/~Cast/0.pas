uses OpenCLABC;

begin
  var q := HFQ(()->5);
  Context.Default.SyncInvoke(
    q.Cast&<object>.ThenConvert(i->integer(i).Sqr).Cast&<object>
  ).ToString.Println;
  Context.Default.SyncInvoke(
    q.Cast&<object>.ThenConvert((i,c)->(integer(i).Sqr.Sqr, c=Context.Default)).Cast&<object>
  ).ToString.Println;
end.