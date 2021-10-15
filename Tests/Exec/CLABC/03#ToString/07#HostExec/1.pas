uses OpenCLABC;

begin
  HFQ(()->1).Println;
  //TODO Почему без begin не работает?
  HPQ(()->begin exit() end).Println;
end.