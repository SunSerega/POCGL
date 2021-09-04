uses OpenCLABC;

begin
  Writeln(new MemorySubSegment(new MemorySegment(1), 0, 1));
end.