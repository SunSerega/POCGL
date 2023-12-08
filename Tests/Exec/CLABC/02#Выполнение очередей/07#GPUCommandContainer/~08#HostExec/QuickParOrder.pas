## uses OpenCLABC;

var mre := new System.Threading.ManualResetEventSlim(false);

var first_id := 0;
var Q_first := HFQ(()->
begin
  lock output do
  begin
    first_id += 1;
    $'First#{first_id}'.Println;
  end;
  if first_id=2 then mre.Set;
  Result := 0;
end);
//  Q_first.GetHashCode.Println;

var second_id := 0;
var Q_second := HFQ(()->
begin
//    Sleep(100);
  mre.Wait;
  lock output do
  begin
    second_id += 1;
    $'Second#{second_id}'.Println;
  end;
  Result := 0;
end);
//  Q_second.GetHashCode.Println;

var a := new CLArray<integer>(1);
CLContext.Default.SyncInvoke(
  a.MakeCCQ.ThenWriteValue(
    
//      HPQ(()->Sleep(100))+
    Q_second
//      .ThenConvert(x->begin Sleep(100); Result := x end)
    
    ,
    
//      HPQ(()->Sleep(100))+
    Q_first
//      .ThenConvert(x->begin Sleep(100); Result := x end)
    
  ) +
  (Q_second+CQ(a)).MakeCCQ.ThenWriteValue(Q_first, 0)
);
a.Dispose;