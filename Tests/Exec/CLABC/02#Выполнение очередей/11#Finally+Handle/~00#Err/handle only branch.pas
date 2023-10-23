## uses OpenCLABC;

var A := HPQ(()->raise new Exception('TestOK'));
var B := HPQ(()->begin end);
var C := HPQ(()->raise new Exception('TestError'));

CLContext.Default.SyncInvoke(
  A + B*C.HandleWithoutRes(e->true)
);