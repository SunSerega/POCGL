uses OpenCLABC;

begin
  var q := HPQ(()->
  begin
    raise new Exception('>>> текст исключения <<<');
  end);
  Context.Default.SyncInvoke(q);
end.