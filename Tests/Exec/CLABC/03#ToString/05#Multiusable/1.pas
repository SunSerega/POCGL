## uses OpenCLABC;

procedure p1(q: CommandQueueBase);
begin
  q.Println;
  ('-'*30+#10).Println;
end;

var Q := HTFQ(()->5);
var Qs := Q.Multiusable;
p1( Q + Qs() * Qs() );
p1( Qs() * Qs() +  Q);
p1( Qs() * Qs() );