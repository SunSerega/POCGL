## uses OpenCLABC;

procedure Test(Q: Action0->CommandQueueBase);
begin
  var thr_ids := new System.Collections.Concurrent.ConcurrentBag<integer>;
  var add_thr_id: Action0 := ()->
  begin
    Sleep(10);
    thr_ids.Add(System.Threading.Thread.CurrentThread.ManagedThreadId);
  end;
  
  Context.Default.SyncInvoke(
    Q(add_thr_id) + CombineAsyncQueueNil(SeqFill(16, HPQQ(add_thr_id)))
  );
  
  thr_ids.Distinct.Count.Println;
end;

Test( ati->HPQ(ati) );
Test( ati->CLMemorySegment.Create(1).NewQueue.ThenWriteValue&<byte>(2) );