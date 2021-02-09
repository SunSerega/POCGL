uses OpenCLABC;

procedure p1(q: CommandQueueBase) :=
try
  WaitFor(q);
except
  on e: Exception do Writeln(e);
end;

begin
  p1(new MarkerQueue);
  p1(nil as object);
  p1(HFQ(()->5).Cast&<object>);
  p1(WaitFor(new MarkerQueue));
end.