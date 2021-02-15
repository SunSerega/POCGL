


#ReqModules
OpenCLABC

#ExpOtp
CommandQueueWaitFor#0
	WCQWaiterAll => WaitMarker#1

WaitMarker#1

SimpleSyncQueueArray<System.Object>#0
	WaitMarker#1
	CommandQueueWaitFor#2
		WCQWaiterAll => WaitMarker#1

SimpleSyncQueueArray<System.Object>#0
	CommandQueueWaitFor#1
		WCQWaiterAll => WaitMarker#2
	CastQueue<System.Object>#3
		WaitMarker#2

CommandQueueWaitFor#0
	WCQWaiterAll => WaitMarker#1

WaitMarker#1

CommandQueueWaitFor#0
	WCQWaiterAny => WaitMarker#1

WaitMarker#1

CommandQueueWaitFor#0
	WCQWaiterAll
		WaitMarker#1
		WaitMarker#2

WaitMarker#1

WaitMarker#2

CommandQueueWaitFor#0
	WCQWaiterAny
		WaitMarker#1
		WaitMarker#2

WaitMarker#1

WaitMarker#2

==============================

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll => WaitMarker#2

WaitMarker#2

SimpleSyncQueueArray<System.Object>#0
	WaitMarker#1
	CommandQueueThenWaitFor<System.Object>#2
		ConstQueue<System.Object>#3 { nil }
		WCQWaiterAll => WaitMarker#1

SimpleSyncQueueArray<System.Object>#0
	CommandQueueThenWaitFor<System.Object>#1
		ConstQueue<System.Object>#2 { nil }
		WCQWaiterAll => WaitMarker#3
	CastQueue<System.Object>#4
		WaitMarker#3

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll => WaitMarker#2

WaitMarker#2

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAny => WaitMarker#2

WaitMarker#2

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll
		WaitMarker#2
		WaitMarker#3

WaitMarker#2

WaitMarker#3

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAny
		WaitMarker#2
		WaitMarker#3

WaitMarker#2

WaitMarker#3

==============================

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WCQWaiterAll => WaitMarker#1

WaitMarker#1

SimpleSyncQueueArray<OpenCLABC.MemorySegment>#0
	WaitMarker#1
	MemorySegmentCCQ#2
		CCCObj => MemorySegment[*] of size 1
		WaitCommand
			WCQWaiterAll => WaitMarker#1

SimpleSyncQueueArray<System.Object>#0
	MemorySegmentCCQ#1
		CCCObj => MemorySegment[*] of size 1
		WaitCommand
			WCQWaiterAll => WaitMarker#2
	CastQueue<System.Object>#3
		WaitMarker#2

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WCQWaiterAll => WaitMarker#1

WaitMarker#1

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WCQWaiterAny => WaitMarker#1

WaitMarker#1

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WCQWaiterAll
			WaitMarker#1
			WaitMarker#2

WaitMarker#1

WaitMarker#2

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	WaitCommand
		WCQWaiterAny
			WaitMarker#1
			WaitMarker#2

WaitMarker#1

WaitMarker#2


