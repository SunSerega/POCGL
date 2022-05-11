## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  WaitAll(WaitMarker.Create, WaitMarker.Create)
);