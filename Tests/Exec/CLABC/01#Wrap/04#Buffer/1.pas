uses OpenCLABC;

begin
  var b := new Buffer(sizeof(integer));
  b.WriteValue(1 shl 24 + 1 shl 16 + 1 shl 8 + 1 shl 0);
  b.GetValue&<integer>.ToString('X').Println;
end.