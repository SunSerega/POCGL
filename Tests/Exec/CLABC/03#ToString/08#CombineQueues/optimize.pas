uses OpenCLABC;

begin
  Writeln(new ConstQueue<byte>(5) * HFQ(()->3));
end.