uses OpenCLABC;
uses NamedQData;

begin
  // График выполнения очередей:
  //
  //     D
  //    /
  //   B
  //  / \
  // A   E
  //  \ /
  //   C
  //    \
  //     F
  //
  
  var A       := NamedQ('A')[0];
  var (B, Bm) := NamedQ('B');
  var (C, Cm) := NamedQ('C');
  var D       := NamedQ('D')[0];
  var E       := NamedQ('E')[0];
  var F       := NamedQ('F')[0];
  
  Context.Default.SyncInvoke(
    A +
    (B+D) *
    (C+F) *
    (WaitForAll(Bm,Cm) + E)
  );
  
end.