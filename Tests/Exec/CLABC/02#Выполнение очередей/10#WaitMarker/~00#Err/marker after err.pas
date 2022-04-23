## uses OpenCLABC;

var M := WaitMarker.Create;
var t := Context.Default.BeginInvoke(
  WaitFor(M) + HQPQ(()->Println(2))
);

try
  Context.Default.SyncInvoke(
    HQPQ(()->raise new Exception) + M
  );
except
end;
Println(1);
M.SendSignal;
t.Wait;