


#ReqModules
OpenCLABC

#ExpOtp
WaitMarkerDummy#0

------------------------------

DetachedMarkerSignal<System.Int32>#0
	DetachedMarkerSignalWrapper<System.Int32>#1
	CommandQueueHostFunc<System.Int32>#2: Int32 <>lambda*()

------------------------------

DetachedMarkerSignalWrapper<System.Int32>#0
	DetachedMarkerSignal<System.Int32>#1

------------------------------

DetachedMarkerSignal<System.Int32>#0
	DetachedMarkerSignalWrapper<System.Int32>#1
	CommandQueueHostFunc<System.Int32>#2: Int32 <>lambda*()

------------------------------

SimpleAsyncQueueArray<System.Int32>#0
	CommandQueueWaitFor#1
		DetachedMarkerSignalWrapper<System.Int32>#2
			DetachedMarkerSignal<System.Int32>#3
	DetachedMarkerSignal<System.Int32>#3
		DetachedMarkerSignalWrapper<System.Int32>#2
		CommandQueueHostFunc<System.Int32>#4: Int32 <>lambda*()

------------------------------

WaitMarkerAll#0
	DetachedMarkerSignalWrapper<System.Int32>#1
		DetachedMarkerSignal<System.Int32>#2 * 2

------------------------------

DetachedMarkerSignalWrapper<System.Int32>#0
	DetachedMarkerSignal<System.Int32>#1

------------------------------


