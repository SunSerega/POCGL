## uses OpenCLABC;

procedure Test(q: CommandQueue<integer>);
begin
  q.Print;
  
  ('-'*30).Println;
  CLContext.Default.SyncInvoke(q
    .ThenUse(x->Println(x))
    .ThenConvert(x->(x*x).Println)
    .ThenUse(x->Println(x))
  );
  
  ('-'*30).Println;
  CLContext.Default.SyncInvoke(q
    .ThenUse(x->Println(x), false)
    .ThenConvert(x->(x*x).Println, false)
    .ThenUse(x->Println(x+1), false)
  );
  
  ('='*30).Println;
end;

Test(2);
Test(HFQ(()->3));
Test(HFQ(()->4 as object).Cast&<integer>);