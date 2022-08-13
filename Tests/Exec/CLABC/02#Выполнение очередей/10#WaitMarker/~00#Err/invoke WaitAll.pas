## uses OpenCLABC;

CLContext.Default.SyncInvoke(
  CombineWaitAll(WaitMarker.Create, WaitMarker.Create)
);