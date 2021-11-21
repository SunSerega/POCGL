uses OpenCLABC;

begin
  Writeln(new ConstQueue<object>(byte(3)) * (new ConstQueue<byte>(5)).Cast&<object>);
  Writeln(HFQ(()->5).Cast&<object> * HFQ(()->5).Cast&<object>);
  
  MemorySegment.Create(1).NewQueue
  .AddQueue(HFQ(()->5).Cast&<object>)
  .Println;
  
end.