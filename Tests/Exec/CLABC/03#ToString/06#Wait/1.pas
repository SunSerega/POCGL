## uses OpenCLABC;

procedure Test<T>(o: T);
begin
  Println(o);
  ('-'*30+#10).Println;
end;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

Test( M1 and M2 );
Test( M1 or M2 );
Test( M1 and M1 );
Test( M1 or M1 );
Test( (M1 or M2) and (M1 or M2) );

('='*30+#10).Println;

Test( WaitFor(M1) );
Test( (M1+WaitFor(M1)) );
Test( WaitFor(M1)+M1 );

('='*30+#10).Println;

var mem := new CLMemory(1);
Test( mem.NewQueue.ThenWait(M1) );
Test( M1+mem.NewQueue.ThenWait(M1) );
Test( mem.NewQueue.ThenWait(M1)+M1 );