uses OpenCLABC;

begin
  
  Writeln(new WaitMarker);
  Writeln('-'*30,#10);
  
  var Q := HFQ(()->5).ThenWaitMarker;
  
  Writeln(Q);
  Writeln('-'*30,#10);
  
  Writeln(WaitMarkerBase(Q));
  Writeln('-'*30,#10);
  
  Writeln(WaitFor(Q) * Q);
  Writeln('-'*30,#10);
  
end.