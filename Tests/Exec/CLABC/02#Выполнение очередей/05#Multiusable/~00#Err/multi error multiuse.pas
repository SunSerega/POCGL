## uses OpenCLABC;

var i := 0;
var QErr := HPQ(()->
begin
  i += 1;
  raise new Exception('TestOK'+i);
end, false);

var Q1 := QErr.Multiusable;
var Q2 := QErr.Multiusable;

CLContext.Default.SyncInvoke((Q1*Q1*Q2).HandleWithoutRes(e->
begin
  e.Message.Println;
  Result := true;
end));