## uses OpenCLABC;

procedure Test(q: CommandQueue<integer>);
begin
  q.Print;
  
  Writeln('-'*10);
  Context.Default.SyncInvoke(q
    .ThenUse(x->Println(x))
    .ThenConvert(x->(x*x).Println)
    .ThenUse(x->Println(x))
  );
  
  Writeln('-'*10);
  Context.Default.SyncInvoke(q
    .ThenQuickUse(x->Println(x))
    .ThenQuickConvert(x->(x*x).Println)
    .ThenQuickUse(x->Println(x+1))
  );
  
  Writeln('='*30);
end;

Test(2);
Test(HFQ(()->3));
Test(HFQ(()->4 as object).Cast&<integer>);