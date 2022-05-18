﻿## uses OpenCLABC;

procedure Invoke(q: CommandQueueBase) :=
Println( CLContext.Default.SyncInvoke(q.Cast&<object>) );

var M1 := WaitMarker.Create;
Invoke( WaitFor(M1) * M1 );

var M2 := HTFQ(()->5).ThenMarkerSignal;
Invoke( WaitFor(M2) * M2 );
Invoke( WaitFor(M2) * WaitMarker(M2) );