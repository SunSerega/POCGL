


#ReqModules
OpenCLABC

#ExpOtp
WaitMarkerDummy#0

------------------------------

DetachedMarkerSignal<System.Int32>#0
	DetachedMarkerSignalWrapper#1
	CommandQueueHostFunc<System.Int32>#2: OpenCLABC_implementation______.<>local_variables_class_*`1[System.Int32] => Int32 <>lambda*(OpenCLABC.Context)

------------------------------

DetachedMarkerSignalWrapper#0
	DetachedMarkerSignal<System.Int32>#1

------------------------------

SimpleAsyncQueueArray<System.Int32>#0
	CommandQueueWaitFor#1
		DetachedMarkerSignalWrapper#2
			DetachedMarkerSignal<System.Int32>#3
	DetachedMarkerSignal<System.Int32>#3
		DetachedMarkerSignalWrapper#2
		CommandQueueHostFunc<System.Int32>#4: OpenCLABC_implementation______.<>local_variables_class_*`1[System.Int32] => Int32 <>lambda*(OpenCLABC.Context)

------------------------------

WaitMarkerAll#0
	DetachedMarkerSignalWrapper#1
		DetachedMarkerSignal<System.Int32>#2 * 2

------------------------------

WaitMarkerAny#0
	WaitMarkerAll#1
		DetachedMarkerSignalWrapper#2
			DetachedMarkerSignal<System.Int32>#3

------------------------------


