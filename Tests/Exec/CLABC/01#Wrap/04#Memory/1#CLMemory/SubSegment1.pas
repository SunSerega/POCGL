uses OpenCLABC;

begin
  var align := Context.Default.MainDevice.Properties.MemBaseAddrAlign;
  
  var mem := new CLMemory(align*2);
  var mem1 := new CLMemorySubSegment(mem, 0, 1);
  var mem2 := new CLMemorySubSegment(mem, align, align);
  
  Writeln(mem.Size64/align);
  Writeln(mem.Properties.GetType);
  Writeln(mem1.Size);
  Writeln(mem1.Properties.GetType);
  Writeln(mem2.Size64/align);
  Writeln(mem2.Properties.GetType);
end.