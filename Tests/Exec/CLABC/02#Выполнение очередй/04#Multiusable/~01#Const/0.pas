uses OpenCLABC;

begin
  var M1 := new WaitMarker;
  var M1s := M1.Multiusable;
  
  var M2 := new WaitMarker;
  
  var t := Context.Default.BeginInvoke(
    WaitFor(M1) +
    (
      WaitFor(M1) +
      HPQ(()->raise new Exception('Error2'))
    ) *
    (
      WaitFor(M2) +
      HPQ(()->
      begin
        Sleep(10);
        raise new Exception('Error1');
      end)
    )
  );
  
  Context.Default.SyncInvoke( M1s()*M1s() );
  Sleep(10);
  M2.SendSignal;
  Sleep(50);
  M1.SendSignal;
  
  t.Wait;
end.