uses OpenCLABC;

begin
  Context.Default.SyncInvoke(
    HPQ(()->Writeln(5))+
    HFQ(()->7)
  ).Println;
end.