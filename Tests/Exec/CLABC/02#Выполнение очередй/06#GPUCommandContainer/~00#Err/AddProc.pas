uses OpenCLABC;

begin
  var b := new Buffer(1);
  Context.Default.SyncInvoke(
    b.NewQueue
    .AddProc(b->raise new Exception($'{b.Size}, TestOK'))
  );
end.