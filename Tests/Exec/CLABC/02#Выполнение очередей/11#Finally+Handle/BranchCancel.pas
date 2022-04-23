## uses OpenCLABC;

var A := HTPQ(()->raise new Exception('TestOK'));
var B := HTPQ(()->lock output do Println('TestError1'));
var C := HTPQ(()->lock output do Println('TestError2'));

Context.Default.SyncInvoke(
  (A + B*C).HandleWithoutRes(e->
  begin
    lock output do e.Message.Println;
    Result := true;
  end)
);