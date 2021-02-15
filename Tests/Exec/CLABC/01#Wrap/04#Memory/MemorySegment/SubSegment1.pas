uses OpenCLABC;

begin
  var align := Context.Default.MainDevice.Properties.MemBaseAddrAlign;
  
  var mem := new MemorySegment(align*2);
  var mem1 := new MemorySubSegment(mem, 0, 1);
  var mem2 := new MemorySubSegment(mem, align, align);
  
  Writeln(mem.Size64/align);
  Writeln(mem.Properties.GetType);
  Writeln(mem1.Size);
  Writeln(mem1.Properties.GetType);
  Writeln(mem2.Size64/align);
  Writeln(mem2.Properties.GetType);
end.