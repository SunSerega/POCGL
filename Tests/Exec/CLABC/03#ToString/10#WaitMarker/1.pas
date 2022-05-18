## uses OpenCLABC;

procedure Test<T>(o: T);
begin
  Println(o);
  ('-'*30+#10).Println;
end;

Test(WaitMarker.Create);

var Q := HTFQ(()->5).ThenMarkerSignal;
Test(Q);
Test(WaitMarker(Q));
Test(CommandQueueBase(WaitMarker(Q)));
Test(WaitFor(Q) * Q);
Test(Q and Q);
Test(Q or Q);