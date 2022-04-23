## uses OpenCLABC;

function ErrQ(err: string) :=
HQPQ(()->raise new Exception(err));

Context.Default.SyncInvoke(
  ( ErrQ('TestOK:1') + ErrQ('TestError') ) *
  ( HTPQ(()->Sleep(100)) + ErrQ('TestOK:2') )
);