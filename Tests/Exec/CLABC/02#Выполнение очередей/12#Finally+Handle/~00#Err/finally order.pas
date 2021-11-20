## uses OpenCLABC;

Context.Default.SyncInvoke(
  HPQ(()->Writeln(1)) >= HPQ(()->Writeln(2))
);

try
  Context.Default.SyncInvoke(
    HPQ(()->raise new Exception('ErrorOK')) + HPQ(()->Writeln(3))
    >= HPQ(()->Writeln(4)) + HPQ(()->Writeln(5))
  );
except
  on e: System.AggregateException do
    Writeln(e.InnerExceptions.Single.Message);
end;