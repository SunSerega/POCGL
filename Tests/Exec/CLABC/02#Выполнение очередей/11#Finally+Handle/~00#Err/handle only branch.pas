## uses OpenCLABC;

var A := HTPQ(()->raise new Exception('TestOK'));
var B := HTPQ(()->begin end);
var C := HTPQ(()->raise new Exception('TestError'));

CLContext.Default.SyncInvoke(
  A + B*C.HandleWithoutRes(e->true)
);