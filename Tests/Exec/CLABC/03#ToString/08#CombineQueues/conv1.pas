uses OpenCLABC;

begin
  var empty_q := new ConstQueue<object>(nil);
  Writeln(CombineSyncQueue&<object>(a->a.JoinToString, empty_q, empty_q));
  Writeln(CombineAsyncQueue&<object>(a->a.JoinToString, empty_q, empty_q));
end.