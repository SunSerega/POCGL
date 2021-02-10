uses OpenCLABC;

begin
  var M1 := new WaitMarker;
  var M1s := M1.Multiusable;
  
  var M2 := new WaitMarker;
  
  var t := Context.Default.BeginInvoke(
    WaitFor(M1) +
    (
      WaitFor(M1) +
      HPQ(()->raise new Exception('TestERROR'))
    ) *
    (
      WaitFor(M2) +
      HPQ(()->raise new Exception('TestOK'))
    )
  );
  
  Context.Default.SyncInvoke( M1s()*M1s() );
  Sleep(10);
  Context.Default.SyncInvoke(M2);
  
  t.Wait;
end.