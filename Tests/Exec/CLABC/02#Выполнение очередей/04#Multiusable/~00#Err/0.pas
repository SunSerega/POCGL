uses OpenCLABC;

begin
  var qf := HPQ(()->
  begin
    Sleep(50);
    raise new Exception('TestOK');
  end).Multiusable;
  
  Context.Default.SyncInvoke(
    CombineAsyncQueueBase(ArrGen(1000, i->qf()))
  );
  
end.