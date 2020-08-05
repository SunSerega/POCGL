uses OpenCLABC;

begin
  var b := new Buffer(sizeof(integer));
  b.WriteValue&<integer>( HFQ(()->
  begin
    Sleep(10);
    Result := 5 as object;
  end).Cast&<integer> );
  b.GetValue&<integer>.Println;
end.