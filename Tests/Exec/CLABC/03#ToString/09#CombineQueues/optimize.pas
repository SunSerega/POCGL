uses OpenCLABC;

begin
  Writeln(new ConstQueue<object>(byte(3)) * (new ConstQueue<byte>(5)).Cast&<object>);
  Writeln(HFQ(()->5).Cast&<object> * HFQ(()->5).Cast&<object>);
  
  CLMemorySegment.Create(1).NewQueue
  .ThenQueue(new ConstQueue<byte>(0))
  .ThenQueue(HFQ(()->5).Cast&<object>)
  .Println;
  
end.