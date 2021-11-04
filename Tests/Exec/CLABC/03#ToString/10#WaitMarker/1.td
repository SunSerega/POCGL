


#ReqModules
OpenCLABC

#ExpOtp
WaitMarkerDummy#0

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
		PseudoWaitMarkerWrapper#2
			PseudoWaitMarker<System.Int32>#3
	PseudoWaitMarker<System.Int32>#3
		PseudoWaitMarkerWrapper#2
		CommandQueueHostFunc<System.Int32>#4 => System.Func`2[OpenCLABC.Context,System.Int32]

------------------------------

WaitAllMarker#0
	PseudoWaitMarkerWrapper#1
		PseudoWaitMarker<System.Int32>#2
	PseudoWaitMarkerWrapper#1
		PseudoWaitMarker<System.Int32>#2

------------------------------

WaitAnyMarker#0
	PseudoWaitMarkerWrapper#1
		PseudoWaitMarker<System.Int32>#2
	PseudoWaitMarkerWrapper#1
		PseudoWaitMarker<System.Int32>#2

------------------------------


