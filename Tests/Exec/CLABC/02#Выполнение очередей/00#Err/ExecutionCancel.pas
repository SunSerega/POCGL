## uses OpenCLABC;

function ErrQ(err: string) :=
HPQ(()->raise new Exception(err), false);

var mre := new System.Threading.ManualResetEventSlim(false);
CLContext.Default.SyncInvoke(
  ( ErrQ('TestOK:1') + ErrQ('TestError') >= HPQ(mre.Set) ) *
  ( HPQ(mre.Wait) + ErrQ('TestOK:2') )
);