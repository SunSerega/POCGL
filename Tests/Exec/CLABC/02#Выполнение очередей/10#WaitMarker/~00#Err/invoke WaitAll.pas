## uses OpenCLABC;

Context.Default.SyncInvoke(
  WaitAll(WaitMarker.Create, WaitMarker.Create)
);