uses OpenCLABC;

procedure p1(q: CommandQueueBase);
begin
  Writeln(q);
  Writeln('-'*30);
  Writeln;
end;

begin
  var Q := HFQ(()->5);
  var Qs := Q.Multiusable;
  p1( Q + Qs() * Qs() );
  p1( Qs() * Qs() +  Q);
  p1( Qs() * Qs() );
end.