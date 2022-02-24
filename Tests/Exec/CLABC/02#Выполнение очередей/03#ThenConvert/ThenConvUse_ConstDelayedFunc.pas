## uses OpenCLABC;

procedure Test(q: CommandQueue<integer>);
begin
  q.Print;
  
  Writeln('-'*10);
  Context.Default.SyncInvoke(q
    .ThenUse(x->Println(x))
    .ThenConvert(x->x*x)
    .ThenUse(x->Println(x))
  );
  
  Writeln('-'*10);
  Context.Default.SyncInvoke(q
    .ThenQuickUse(x->Println(x))
    .ThenQuickConvert(x->x*x)
    .ThenQuickUse(x->Println(x))
  );
  
  Writeln('='*30);
end;

Test(2);
Test(HFQ(()->3));
Test(HFQ(()->4 as object).Cast&<integer>);