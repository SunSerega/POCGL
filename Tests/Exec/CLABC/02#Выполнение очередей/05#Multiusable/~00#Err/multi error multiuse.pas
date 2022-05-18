## uses OpenCLABC;

var i := 0;
var QErr := HQPQ(()->
begin
  i += 1;
  raise new Exception('TestOK'+i);
end);

var Q1s := QErr.Multiusable;
var Q2s := QErr.Multiusable;

CLContext.Default.SyncInvoke((Q1s()*Q1s()*Q2s()).HandleWithoutRes(e->
begin
  e.Message.Println;
  Result := true;
end));