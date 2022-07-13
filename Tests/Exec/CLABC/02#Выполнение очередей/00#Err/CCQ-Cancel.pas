## uses OpenCLABC;

var mre := new System.Threading.ManualResetEventSlim;
CLContext.Default.SyncInvoke(
  (
    HPQ(()->
    begin
      mre.Wait;
      raise new Exception;
    end) +
    CLProgramCode.Create('kernel void k(global int* a) { a[-1] = -1; }')['k']
    .MakeCCQ.ThenExec1(1, new CLArray<integer>(1))
  ) * HPQ(mre.Set, false)
);