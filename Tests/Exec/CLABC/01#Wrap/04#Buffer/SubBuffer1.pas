uses OpenCLABC;

begin
  var align := Context.Default.MainDevice.Properties.MemBaseAddrAlign;
  
  var b := new Buffer(align*2, Context.Default);
  var b1 := new SubBuffer(b, 0, 1);
  var b2 := new SubBuffer(b, align, align);
  
  Writeln(b1.Size);
  Writeln(b1.Properties.GetType);
  Writeln(b2.Size64/align);
  Writeln(b2.Properties.GetType);
end.