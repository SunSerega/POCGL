uses OpenCLABC;

begin
  HFQ(()->5).Cast&<object>.Println;
  HFQ(()->5).Cast&<object>.Cast&<integer>.Println;
  HFQ(()->5).Cast&<object>.Cast&<integer?>.Println;
end.