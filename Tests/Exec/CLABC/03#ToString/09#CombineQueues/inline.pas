uses OpenCLABC;

begin
  var Q1 := HFQ(()->5);
  
  Writeln( (Q1+Q1) + (Q1+Q1) );
  Writeln( (Q1*Q1) * (Q1*Q1) );
  
  Writeln( (Q1+Q1) * (Q1+Q1) );
  Writeln( (Q1*Q1) + (Q1*Q1) );
  
end.