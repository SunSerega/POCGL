uses OpenCLABC;

begin
  try
    var q := HPQ(()->
    begin
      raise new Exception('>>> текст исключения <<<');
    end);
    Context.Default.SyncInvoke(q);
  except
    on e: Exception do Writeln(e);
  end;
end.