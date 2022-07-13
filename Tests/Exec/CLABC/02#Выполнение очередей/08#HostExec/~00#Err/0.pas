## uses OpenCLABC;

var Q := HPQ(()->
begin
  raise new Exception('TestOK');
end, false);
CLContext.Default.SyncInvoke(Q);