## uses OpenCLABC;

function ErrQ(err: string) :=
HPQ(()->raise new Exception(err));

Context.Default.SyncInvoke(
  ( ErrQ('TestOK:1') + ErrQ('TestError') ) *
  ( HPQ(()->Sleep(100)) + ErrQ('TestOK:2') )
);