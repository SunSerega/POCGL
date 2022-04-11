


#DelegateCount
5

#ExpOtp
WaitMarkerAll#0
	WaitMarkerDummy#1
	WaitMarkerDummy#2

------------------------------

WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2
	WaitMarkerAll#3
		WaitMarkerDummy#4

------------------------------

WaitMarkerAll#0
	WaitMarkerDummy#1 * 2

------------------------------

WaitMarkerDummy#0

------------------------------

WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2 * 2
	WaitMarkerAll#3
		WaitMarkerDummy#2
		WaitMarkerDummy#4
	WaitMarkerAll#5
		WaitMarkerDummy#4 * 2

------------------------------

==================================================

CommandQueueWaitFor#0
	WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArrayNil#0
	WaitMarkerDummyExecutor#1
		WaitMarkerDummy#2
	CommandQueueWaitFor#3
		WaitMarkerDummy#2

------------------------------

SimpleSyncQueueArrayNil#0
	CommandQueueWaitFor#1
		WaitMarkerDummy#2
	WaitMarkerDummyExecutor#3
		WaitMarkerDummy#2

------------------------------

==================================================

CLMemorySegmentCCQ#0
	CCCObj<CLMemorySegment>: CLMemorySegment[*] of size 1
	WaitCommand<CLMemorySegment>
		WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArray<CLMemorySegment>#0
	WaitMarkerDummyExecutor#1
		WaitMarkerDummy#2
	CLMemorySegmentCCQ#3
		CCCObj<CLMemorySegment>: CLMemorySegment[*] of size 1
		WaitCommand<CLMemorySegment>
			WaitMarkerDummy#2

------------------------------

SimpleSyncQueueArrayNil#0
	CLMemorySegmentCCQ#1
		CCCObj<CLMemorySegment>: CLMemorySegment[*] of size 1
		WaitCommand<CLMemorySegment>
			WaitMarkerDummy#2
	WaitMarkerDummyExecutor#3
		WaitMarkerDummy#2

------------------------------

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 

#ReqModules
OpenCLABC


