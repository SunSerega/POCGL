## uses OpenCLABC;

Writeln(
  (HPQ(()->begin end) + new ConstQueue<byte>(5) as CommandQueue<byte>)
  + HPQ(()->begin end)
);