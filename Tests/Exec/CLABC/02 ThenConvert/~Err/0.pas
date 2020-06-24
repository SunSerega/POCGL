uses OpenCLABC;

begin
  Context.Default.SyncInvoke(
    HFQ(()->5).ThenConvert(i->
    begin
      Result := i;
      raise new Exception('>>> текст ошибки <<<');
    end)
  );
end.