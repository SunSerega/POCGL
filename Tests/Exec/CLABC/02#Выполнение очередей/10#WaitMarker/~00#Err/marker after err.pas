## uses OpenCLABC;

var M := WaitMarker.Create;
var t := CLContext.Default.BeginInvoke(
  WaitFor(M) + HPQ(()->Println(2), false)
);

try
  CLContext.Default.SyncInvoke(
    HPQ(()->raise new Exception, false) + M
  );
except
end;
Println(1);
M.SendSignal;
t.Wait;