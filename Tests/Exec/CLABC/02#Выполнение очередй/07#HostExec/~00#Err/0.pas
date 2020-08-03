uses OpenCLABC;

begin
  var q := HPQ(()->
  begin
    raise new Exception('TestOK');
  end);
  Context.Default.SyncInvoke(q);
end.