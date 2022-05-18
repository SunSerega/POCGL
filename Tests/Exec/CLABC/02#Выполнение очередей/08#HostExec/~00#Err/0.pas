## uses OpenCLABC;

var q := HQPQ(()->
begin
  raise new Exception('TestOK');
end);
CLContext.Default.SyncInvoke(q);