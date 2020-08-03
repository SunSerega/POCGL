uses OpenCLABC;

begin
  var b := new Buffer(1);
  Context.Default.SyncInvoke(
    b.NewQueue
    .AddQueue(HPQ(()->raise new Exception($'{b.Size}, TestOK')))
  );
end.