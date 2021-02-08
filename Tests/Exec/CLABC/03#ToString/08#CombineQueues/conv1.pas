uses OpenCLABC;

begin
  Writeln(CombineSyncQueue(a->a.JoinToString, nil as object, nil as object));
  Writeln(CombineAsyncQueue(a->a.JoinToString, nil as object, nil as object));
end.