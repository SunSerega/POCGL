


#ReqModules
OpenCLABC

#ExpOtp
CommandQueueWaitFor#0
	WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArray<System.Object>#0
	WaitMarkerDummy#1
	CommandQueueWaitFor#2
		WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArray<System.Object>#0
	CommandQueueWaitFor#1
		WaitMarkerDummy#2
	CastQueue<System.Object>#3
		WaitMarkerDummy#2

------------------------------

CommandQueueWaitFor#0
	WaitAllMarker#1
		WaitMarkerDummy#2
		WaitMarkerDummy#3

------------------------------

CommandQueueWaitFor#0
	WaitAnyMarker#1
		WaitMarkerDummy#2
		WaitMarkerDummy#3

------------------------------

==================================================

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WaitMarkerDummy#2

------------------------------

SimpleSyncQueueArray<System.Object>#0
	WaitMarkerDummy#1
	CommandQueueThenWaitFor<System.Object>#2
		ConstQueue<System.Object>#3 { nil }
		WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArray<System.Object>#0
	CommandQueueThenWaitFor<System.Object>#1
		ConstQueue<System.Object>#2 { nil }
		WaitMarkerDummy#3
	CastQueue<System.Object>#4
		WaitMarkerDummy#3

------------------------------

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WaitAllMarker#2
		WaitMarkerDummy#3
		WaitMarkerDummy#4

------------------------------

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WaitAnyMarker#2
		WaitMarkerDummy#3
		WaitMarkerDummy#4

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

SimpleSyncQueueArray<System.Object>#0
	MemorySegmentCCQ#1
		CCCObj => MemorySegment[*] of size 1
		WaitCommand
			WaitMarkerDummy#2
	CastQueue<System.Object>#3
		WaitMarkerDummy#2

------------------------------

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WaitAllMarker#1
			WaitMarkerDummy#2
			WaitMarkerDummy#3

------------------------------

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WaitAnyMarker#1
			WaitMarkerDummy#2
			WaitMarkerDummy#3

------------------------------


