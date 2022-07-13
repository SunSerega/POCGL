## uses OpenCLABC;

var A := HPQ(()->raise new Exception('TestOK'));
var B := HPQ(()->lock output do Println('TestError1'));
var C := HPQ(()->lock output do Println('TestError2'));

CLContext.Default.SyncInvoke(
  (A + B*C).HandleWithoutRes(e->
  begin
    lock output do e.Message.Println;
    Result := true;
  end)
);