## uses OpenCLABC;

var qs := HQFQ(()->
begin
  'q выполнилась'.Println;
  Result := 5;
end).Cast&<object>.Multiusable;
CLContext.Default.SyncInvoke(
  CombineConstConvAsyncQueue(res->res,
    qs().Cast&<integer>,
    qs().ThenConstConvert(o->integer(o).Sqr),
    qs().ThenConstConvert(o->integer(o).Sqr.Sqr)
  )
).Println;
CLContext.Default.SyncInvoke(qs().Cast&<integer>.ThenConvert(i->i**i)).Println;