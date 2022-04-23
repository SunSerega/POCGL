## uses OpenCLABC;

Context.Default.SyncInvoke(
  HTPQ(()->Println(1)) >= HTPQ(()->Println(2))
);

try
  Context.Default.SyncInvoke(
    HTPQ(()->raise new Exception('ErrorOK')) + HTPQ(()->Println(3))
    >= HTPQ(()->Println(4)) + HTPQ(()->Println(5))
  );
except
  on e: System.AggregateException do
    e.InnerExceptions.PrintLines(e->e.Message);
end;