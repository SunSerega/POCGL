## uses OpenCLABC;

function ErrQ(err: string) :=
HQPQ(()->raise new Exception(err));

var mre := new System.Threading.ManualResetEventSlim(false);
Context.Default.SyncInvoke(
  ( ErrQ('TestOK:1') + ErrQ('TestError') >= HTPQ(mre.Set) ) *
  ( HTPQ(mre.Wait) + ErrQ('TestOK:2') )
);