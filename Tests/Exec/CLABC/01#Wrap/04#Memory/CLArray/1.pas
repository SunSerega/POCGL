uses OpenCLABC;

begin
  var a := new CLArray<integer>(1);
  a[0] := 1 shl 24 + 2 shl 16 + 3 shl 8 + 4 shl 0;
  a[0].ToString('X').Println;
end.