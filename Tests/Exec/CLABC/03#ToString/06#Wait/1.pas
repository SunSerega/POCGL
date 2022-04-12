## uses OpenCLABC;

procedure Test<T>(o: T);
begin
  Writeln(o);
  Writeln('-'*30,#10);
end;

var M1 := WaitMarker.Create;
var M2 := WaitMarker.Create;

Test( M1 and M2 );
Test( M1 or M2 );
Test( M1 and M1 );
Test( M1 or M1 );
Test( (M1 or M2) and (M1 or M2) );

Writeln('='*50);
Writeln;

Test( WaitFor(M1) );
Test( (M1+WaitFor(M1)) );
Test( WaitFor(M1)+M1 );

Writeln('='*50);
Writeln;

var mem := new CLMemory(1);
Test( mem.NewQueue.ThenWait(M1) );
Test( M1+mem.NewQueue.ThenWait(M1) );
Test( mem.NewQueue.ThenWait(M1)+M1 );