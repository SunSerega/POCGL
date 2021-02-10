uses OpenCLABC;

begin
  var Q := HFQ(()->5);
  var M := new WaitMarker;
  
  var t := Context.Default.BeginInvoke(
    Q.ThenWaitFor(M)
  );
  Context.Default.SyncInvoke(M);
  
  t.WaitRes.Println;
end.