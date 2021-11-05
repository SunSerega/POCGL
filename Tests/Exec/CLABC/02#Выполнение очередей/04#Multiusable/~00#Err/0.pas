uses OpenCLABC;

begin
  var qf := HPQ(()->
  begin
    Sleep(10);
    raise new Exception('TestOK');
  end).Multiusable;
  
  Context.Default.SyncInvoke(
    CombineAsyncQueueBase(ArrGen(100, i->qf()))
  );
  
end.