uses OpenCLABC;

begin
  var q := HFQ(()->123);
  
  Context.Default.SyncInvoke(
    q.ThenConvert(i -> i*2 )
  ).Println;
  
end.