## uses OpenCLABC;

function HFQw<T>(x: integer; o: T) := HFQ(()->
begin
  Sleep(100);
  lock output do Writeln(x);
  Result := o;
end);
function HFQQw<T>(x: integer; o: T) := HPQ(()->begin end)+HFQQ(()->
begin
  lock output do Writeln(x);
  Result := o;
end);

var a := new CLArray<integer>(1);
Context.Default.SyncInvoke(
  a.NewQueue.ThenWriteValue(HFQw(3,0), HFQQw(1,0)) +
  CLArrayCCQ&<integer>.Create(HFQw(4,a)).ThenWriteValue(HFQQw(2,0), 0)
);