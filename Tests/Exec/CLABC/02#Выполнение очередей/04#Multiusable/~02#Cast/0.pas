## uses OpenCLABC;

var qs := HFQ(()->
begin
  Writeln('q выполнилась');
  Result := 5;
end).Cast&<object>.Multiusable;
Context.Default.SyncInvoke(
  CombineConvAsyncQueue(res->res,
    qs().ThenConvert(o->integer(o).Sqr),
    qs().ThenConvert(o->integer(o).Sqr.Sqr)
  )
).Println;
Context.Default.SyncInvoke(qs().Cast&<integer>.ThenConvert(i->i**i)).Println;