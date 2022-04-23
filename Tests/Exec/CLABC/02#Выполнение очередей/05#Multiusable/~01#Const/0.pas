## uses OpenCLABC;

var M1 := WaitMarker.Create;
var M1s := CommandQueueBase(M1).Multiusable;

var M2 := WaitMarker.Create;

var t := Context.Default.BeginInvoke(
  WaitFor(M1) +
  (
    WaitFor(M1) +
    HTPQ(()->Println(2))
  ) *
  (
    WaitFor(M2) +
    HTPQ(()->
    begin
      Sleep(10);
      Println(1);
    end)
  )
);

Context.Default.SyncInvoke( M1s()*M1s() );
Sleep(10);
M2.SendSignal;
Sleep(50);
M1.SendSignal;

t.Wait;