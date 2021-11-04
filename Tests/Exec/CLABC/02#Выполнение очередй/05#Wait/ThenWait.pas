uses OpenCLABC;

begin
  var Q := HFQ(()->5);
  var M := WaitMarker.Create;
  
  var t := Context.Default.BeginInvoke(
    Q.ThenWaitFor(M)
  );
  M.SendSignal;
  
  t.WaitRes.Println;
end.