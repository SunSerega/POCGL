## uses OpenCLABC;

procedure Test(Q: Action0->CommandQueueBase);
begin
  var thr_ids := new System.Collections.Concurrent.ConcurrentBag<integer>;
  var add_thr_id := procedure->
  begin
    Sleep(10);
    thr_ids.Add(System.Threading.Thread.CurrentThread.ManagedThreadId);
  end;
  
  CLContext.Default.SyncInvoke(
    Q(add_thr_id) + CombineAsyncQueueNil(ArrFill(16, HQPQ(add_thr_id)))
  );
  
  thr_ids.Distinct.Count.Println;
end;

Test( ati->HTPQ(ati) );
Test( ati->CLMemory.Create(4).NewQueue.ThenWriteValue(5) );