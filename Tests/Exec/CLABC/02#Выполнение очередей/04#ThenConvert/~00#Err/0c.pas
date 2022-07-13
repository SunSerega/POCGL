## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HFQ(()->5, false).ThenConvert((i,c)->
  begin
    Result := i;
    raise new Exception('TestOK');
  end, false,true)
);