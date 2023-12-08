## uses OpenCLABC;

var a := new CLArray<integer>(1);
var wh := new System.Threading.ManualResetEventSlim(false);
CLContext.Default.SyncInvoke(
  (
    HPQ(()->
    begin
      wh.Wait;
      $'HPQ+1'.Println;
      raise new Exception('TestOK+1');
    end) +
    CQ(a)
  ).MakeCCQ.ThenWriteValue(0, HFQ(()->
  begin
    Result := 0;
    $'HFQ+2'.Println;
    wh.Set;
    raise new Exception('TestOK+2');
  end))
  .HandleWithoutRes(e->e.Message.Println <> nil)
);
a.Dispose;
$'Expect 3 evs: HPQ + HFQ + async enq'.Println;