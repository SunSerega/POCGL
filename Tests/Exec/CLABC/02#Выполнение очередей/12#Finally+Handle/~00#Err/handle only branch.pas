## uses OpenCLABC;

var A := HPQ(()->raise new Exception('TestOK'));
var B := HPQ(()->raise new Exception('TestError1'));
var C := HPQ(()->raise new Exception('TestError2'));

Context.Default.SyncInvoke(
  A + B*C.HandleWithoutRes(e->
  begin
    e.Message.Println;
    Result := true;
  end)
);