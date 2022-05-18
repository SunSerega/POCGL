## uses OpenCLABC;

var M := WaitMarker.Create;
var t := CLContext.Default.BeginInvoke(
  WaitFor(M) + HQPQ(()->Println(2))
);

try
  CLContext.Default.SyncInvoke(
    HQPQ(()->raise new Exception) + M
  );
except
end;
Println(1);
M.SendSignal;
t.Wait;