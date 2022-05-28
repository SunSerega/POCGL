## uses OpenCLABC;

procedure Test(min_thrs: integer; Q: Action0->CommandQueueBase);
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
  
  (thr_ids.Distinct.Count>=min_thrs).Println;
end;

Test(2, ati->HTPQ(ati) );
Test(1, ati->CLMemory.Create(4).MakeCCQ.ThenWriteValue(5) );