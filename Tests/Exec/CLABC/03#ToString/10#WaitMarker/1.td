


#ReqModules
OpenCLABC

#ExpOtp
WaitMarkerDummy#0

------------------------------

PseudoWaitMarker<System.Int32>#0
	PseudoWaitMarkerWrapper#1
	CommandQueueHostFunc<System.Int32>#2: OpenCLABC_implementation______.<>local_variables_class_*`1[System.Int32] => Int32 <>lambda*(OpenCLABC.Context)

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
		CommandQueueHostFunc<System.Int32>#4: OpenCLABC_implementation______.<>local_variables_class_*`1[System.Int32] => Int32 <>lambda*(OpenCLABC.Context)

------------------------------

WaitMarkerAll#0
	PseudoWaitMarkerWrapper#1
		PseudoWaitMarker<System.Int32>#2 * 2

------------------------------

WaitMarkerAny#0
	WaitMarkerAll#1
		PseudoWaitMarkerWrapper#2
			PseudoWaitMarker<System.Int32>#3

------------------------------


