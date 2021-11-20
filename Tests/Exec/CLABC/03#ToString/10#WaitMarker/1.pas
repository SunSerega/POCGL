## uses OpenCLABC;

procedure Test<T>(o: T);
begin
  Writeln(o);
  Writeln('-'*30,#10);
end;

Test(WaitMarker.Create);

var Q := HFQ(()->5).ThenMarkerSignal;
Test(Q);
Test(WaitMarker(Q));
Test(WaitFor(Q) * Q);
Test(Q and Q);
Test(Q or Q);