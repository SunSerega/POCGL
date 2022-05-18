## uses OpenCLABC;
var i: integer;

var Qs := ArrGen(10, n->HTPQ(()->if i=n then raise new Exception('Err#'+n)));
var Q :=
  Qs[0] +
  (Qs[1] + Qs[2]*Qs[3] + Qs[4])
  *
  (Qs[5] + Qs[6]*Qs[7] + Qs[8])
  + Qs[9];
for i := 0 to Qs.Length-1 do
try
  CLContext.Default.SyncInvoke(Q);
except
  on e: System.AggregateException do
  begin
    e.InnerExceptions.PrintLines(e->e.Message);
    ('-'*30).Println;
  end;
end;