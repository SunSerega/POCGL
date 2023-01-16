## uses OpenCLABC;

var Q := HFQ(()->
begin
  'Q выполнилась'.Println;
  Result := 5;
end, false).Cast&<object>.Multiusable;
CLContext.Default.SyncInvoke(
  CombineConvAsyncQueue(res->res, |
    Q.Cast&<integer>,
    Q.ThenConvert&<integer>(o->Sqr(integer(o)), false),
    Q.ThenConvert&<integer>(o->Sqr(integer(o).Sqr), false)
  |, false)
).Println;
CLContext.Default.SyncInvoke(Q.Cast&<integer>.ThenConvert(i->i**i)).Println;