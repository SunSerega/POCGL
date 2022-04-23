


#DelegateCount
5

#ExpOtp
WaitMarkerDummy#0
 
------------------------------
 
DetachedMarkerSignal<integer>#0
	DetachedMarkerSignalWrapper<integer>#1
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer
 
------------------------------
 
DetachedMarkerSignalWrapper<integer>#0
	DetachedMarkerSignal<integer>#1
 
------------------------------
 
DetachedMarkerSignal<integer>#0
	DetachedMarkerSignalWrapper<integer>#1
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer
 
------------------------------
 
SimpleAsyncQueueArray<integer>#0
	CommandQueueWaitFor#1
		DetachedMarkerSignalWrapper<integer>#2
			DetachedMarkerSignal<integer>#3
	DetachedMarkerSignal<integer>#3
		DetachedMarkerSignalWrapper<integer>#2
		CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#4: function lambda: integer
 
------------------------------
 
WaitMarkerAll#0
	DetachedMarkerSignalWrapper<integer>#1
		DetachedMarkerSignal<integer>#2 * 2
 
------------------------------
 
DetachedMarkerSignalWrapper<integer>#0
	DetachedMarkerSignal<integer>#1
 
------------------------------
 
[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 

#ReqModules
OpenCLABC


