## uses OpenCLABC;

var mre := new System.Threading.ManualResetEventSlim(false);

var fast_id := 0;
var Q_fast := HTFQ(()->
begin
  lock output do
  begin
    fast_id += 1;
    $'Fast#{fast_id}'.Println;
  end;
  if fast_id=2 then mre.Set;
  Result := 0;
end);

var slow_id := 0;
var Q_slow := HTFQ(()->
begin
  mre.Wait;
  lock output do
  begin
    slow_id += 1;
    $'Slow#{slow_id}'.Println;
  end;
  Result := 0;
end);

var a := new CLArray<integer>(1);
CLContext.Default.SyncInvoke(
  a.NewQueue.ThenWriteValue(Q_slow, Q_fast) +
  CLArrayCCQ&<integer>.Create(Q_slow+CQ(a)).ThenWriteValue(Q_fast, 0)
);