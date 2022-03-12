## uses OpenCLABC;

var Q := HFQQ(()->1);

(Q >= Q).Println;
Q.HandleWithoutRes(e->true).Println;
Q.HandleDefaultRes(e->true, 2).Println;
Q.HandleReplaceRes(lst->
begin
  lst.Clear;
  Result := 3;
end).Println;