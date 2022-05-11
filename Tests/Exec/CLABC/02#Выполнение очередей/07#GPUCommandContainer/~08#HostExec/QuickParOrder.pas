## uses OpenCLABC;

var mre := new System.Threading.ManualResetEventSlim(false);

var fast_id := 0;
var Q_fast := HTFQ(()->
begin
  var fast_id := System.Threading.Interlocked.Increment(fast_id);
  lock output do $'Fast#{fast_id}'.Println;
  if fast_id=2 then mre.Set;
  Result := 0;
end);

var slow_id := 0;
var Q_slow := HTFQ(()->
begin
  mre.Wait;
  var slow := System.Threading.Interlocked.Increment(slow_id);
  lock output do $'Slow#{slow}'.Println;
  Result := 0;
end);

var a := new CLArray<integer>(1);
CLContext.Default.SyncInvoke(
  a.NewQueue.ThenWriteValue(Q_slow, Q_fast) +
  CLArrayCCQ&<integer>.Create(Q_slow+CQ(a)).ThenWriteValue(Q_fast, 0)
);