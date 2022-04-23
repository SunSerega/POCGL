## uses OpenCLABC;

procedure Test(q: CommandQueue<integer>);
begin
  q.Print;
  
  ('-'*30).Println;
  Context.Default.SyncInvoke(q
    .ThenUse(x->Println(x))
    .ThenConvert(x->(x*x).Println)
    .ThenUse(x->Println(x))
  );
  
  ('-'*30).Println;
  Context.Default.SyncInvoke(q
    .ThenQuickUse(x->Println(x))
    .ThenQuickConvert(x->(x*x).Println)
    .ThenQuickUse(x->Println(x+1))
  );
  
  ('='*30).Println;
end;

Test(2);
Test(HTFQ(()->3));
Test(HTFQ(()->4 as object).Cast&<integer>);