uses OpenCLABC;

procedure p1(q: CommandQueueBase) := Write(q);
procedure p2<T>(q: CommandQueue<T>) := Write(q);

begin
  
  p1(new object);
  p1(nil as object);
  p1(5 as object);
  
  Writeln;
  
  p2&<object>(new object);
  p2&<object>(new Exception as object);
  p2&<object>(nil as object);
  p2&<object>(5 as object);
  p2&<integer>(5);
  
end.