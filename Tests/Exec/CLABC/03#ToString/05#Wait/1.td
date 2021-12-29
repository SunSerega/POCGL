


#ReqModules
OpenCLABC

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

SimpleSyncQueueArray<System.Object>#0
	WaitMarkerDummy#1
	CommandQueueWaitFor#2
		WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArrayBase#0
	CommandQueueWaitFor#1
		WaitMarkerDummy#2
	WaitMarkerDummy#2

------------------------------

==================================================

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArray<OpenCLABC.MemorySegment>#0
	WaitMarkerDummy#1
	MemorySegmentCCQ#2
		CCCObj => MemorySegment[*] of size 1
		WaitCommand
			WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArrayBase#0
	MemorySegmentCCQ#1
		CCCObj => MemorySegment[*] of size 1
		WaitCommand
			WaitMarkerDummy#2
	WaitMarkerDummy#2

------------------------------


