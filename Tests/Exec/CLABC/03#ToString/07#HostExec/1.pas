uses OpenCLABC;

begin
  HFQ(()->1).Println;
  //ToDo Почему без begin не работает?
  HPQ(()->begin exit() end).Println;
end.