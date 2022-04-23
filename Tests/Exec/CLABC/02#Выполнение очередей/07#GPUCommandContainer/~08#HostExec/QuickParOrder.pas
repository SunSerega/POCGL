## uses OpenCLABC;

function HFQ1<T>(x: integer; o: T) := HTFQ(()->
begin
  lock output do x.Println;
  Result := o;
end);
function HFQ2<T>(x: integer; o: T) := HTFQ(()->
begin
  Sleep(50);
  lock output do x.Println;
  Result := o;
end);

var a := new CLArray<integer>(1);
Context.Default.SyncInvoke(
  a.NewQueue.ThenWriteValue(HFQ2(3,0), HFQ1(1,0)) +
  CLArrayCCQ&<integer>.Create(HFQ2(4,a)).ThenWriteValue(HFQ1(2,0), 0)
);