## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  HPQ(()->Println(1)) >= HPQ(()->Println(2))
);

try
  CLContext.Default.SyncInvoke(
    HPQ(()->raise new Exception('ErrorOK')) + HPQ(()->Println(3))
    >= HPQ(()->Println(4)) + HPQ(()->Println(5))
  );
except
  on e: System.AggregateException do
    e.InnerExceptions.PrintLines(e->e.Message);
end;