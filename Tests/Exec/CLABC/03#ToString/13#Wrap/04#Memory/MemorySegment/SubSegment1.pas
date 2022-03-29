uses OpenCLABC;

begin
  Writeln(new CLMemorySubSegment(new CLMemorySegment(1), 0, 1));
end.