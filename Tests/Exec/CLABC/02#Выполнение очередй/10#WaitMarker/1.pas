uses OpenCLABC;

begin
  
  var M1 := new WaitMarker;
  Context.Default.SyncInvoke( WaitFor(M1) * M1 );
  
  var M2 := HFQ(()->5).ThenWaitMarker;
  Context.Default.SyncInvoke( WaitFor(M2) * M2 ).Println;
  Context.Default.SyncInvoke( WaitFor(M2) * WaitMarkerBase(M2) );
  
end.