uses OpenCLABC;

begin
  HFQ(()->5).ThenConvert(i->i*2).Print;
end.