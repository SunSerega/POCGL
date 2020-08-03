uses OpenCLABC;

begin
  var cq := new ConstQueue<integer>(5);
  var qf := cq.Multiusable;
  
  var mq: CommandQueueBase := nil as object;
  
  var t := Context.Default.BeginInvoke(
    WaitFor(cq) +
    (
      WaitFor(cq) +
      HPQ(()->raise new Exception('TestERROR'))
    ) *
    (
      WaitFor(mq) +
      HPQ(()->raise new Exception('TestOK'))
    )
  );
  
  Context.Default.SyncInvoke( qf()*qf() );
  Sleep(10);
  Context.Default.SyncInvoke(mq);
  
  t.Wait;
end.