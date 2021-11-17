## uses OpenCLABC;

var M := WaitMarker.Create;
var t := Context.Default.BeginInvoke(
  WaitFor(M) + HPQ(()->Writeln(2))
);

try
  Context.Default.SyncInvoke(
    HPQ(()->raise new Exception) + M
  );
except
end;
Writeln(1);
M.SendSignal;
t.Wait;