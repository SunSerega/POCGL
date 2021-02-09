uses OpenCLABC;
uses NamedQData;

begin
  // График выполнения очередей:
  //
  // A1--B--C1-----E1
  //      \       /
  //       \     /
  // A2-----C2--D--E2
  //
  
  var A1      := NamedQ('A1')[0];
  var A2      := NamedQ('A2')[0];
  
  var (B, Bm) := NamedQ('B');
  
  var C1      := NamedQ('C1')[0];
  var C2      := NamedQ('C2')[0];
  
  var (D, Dm) := NamedQ('D');
  
  var E1      := NamedQ('E1')[0];
  var E2      := NamedQ('E2')[0];
  
  Context.Default.SyncInvoke(
    ( A1 + B           + C1 + WaitFor(Dm) + E1 ) *
    ( A2 + WaitFor(Bm) + C2 + D           + E2 )
  );
  
end.