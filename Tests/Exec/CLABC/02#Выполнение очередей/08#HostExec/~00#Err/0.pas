## uses OpenCLABC;

var q := HQPQ(()->
begin
  raise new Exception('TestOK');
end);
Context.Default.SyncInvoke(q);