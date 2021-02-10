


#ReqModules
OpenCLABC

#ExpOtp
WaitMarker#0

------------------------------

PseudoWaitMarker<System.Int32>#0
	PseudoWaitMarkerWrapper#1
	CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

------------------------------

PseudoWaitMarkerWrapper#0
	PseudoWaitMarker<System.Int32>#1

------------------------------

SimpleAsyncQueueArray<System.Int32>#0
	CommandQueueWaitFor#1
		WCQWaiterAll => PseudoWaitMarkerWrapper#2
	PseudoWaitMarker<System.Int32>#3
		PseudoWaitMarkerWrapper#2
		CommandQueueHostFunc<System.Int32>#4 => System.Func`2[OpenCLABC.Context,System.Int32]

PseudoWaitMarkerWrapper#2
	PseudoWaitMarker<System.Int32>#3

------------------------------


