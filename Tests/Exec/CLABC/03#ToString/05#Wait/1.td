


#ReqModules
OpenCLABC

#ExpOtp
CommandQueueWaitFor#0
	WCQWaiterAll => MarkerQueue#1

MarkerQueue#1

SimpleSyncQueueArray<System.Object>#0
	MarkerQueue#1
	CommandQueueWaitFor#2
		WCQWaiterAll => MarkerQueue#1

SimpleSyncQueueArray<System.Object>#0
	CommandQueueWaitFor#1
		WCQWaiterAll => MarkerQueue#2
	CastQueue<System.Object>#3
		MarkerQueue#2

CommandQueueWaitFor#0
	WCQWaiterAll => MarkerQueue#1

MarkerQueue#1

CommandQueueWaitFor#0
	WCQWaiterAny => MarkerQueue#1

MarkerQueue#1

CommandQueueWaitFor#0
	WCQWaiterAll
		MarkerQueue#1
		MarkerQueue#2

MarkerQueue#1

MarkerQueue#2

CommandQueueWaitFor#0
	WCQWaiterAny
		MarkerQueue#1
		MarkerQueue#2

MarkerQueue#1

MarkerQueue#2

==============================

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll => MarkerQueue#2

MarkerQueue#2

SimpleSyncQueueArray<System.Object>#0
	MarkerQueue#1
	CommandQueueThenWaitFor<System.Object>#2
		ConstQueue<System.Object>#3 { nil }
		WCQWaiterAll => MarkerQueue#1

SimpleSyncQueueArray<System.Object>#0
	CommandQueueThenWaitFor<System.Object>#1
		ConstQueue<System.Object>#2 { nil }
		WCQWaiterAll => MarkerQueue#3
	CastQueue<System.Object>#4
		MarkerQueue#3

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll => MarkerQueue#2

MarkerQueue#2

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAny => MarkerQueue#2

MarkerQueue#2

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll
		MarkerQueue#2
		MarkerQueue#3

MarkerQueue#2

MarkerQueue#3

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAny
		MarkerQueue#2
		MarkerQueue#3

MarkerQueue#2

MarkerQueue#3

==============================

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAll => MarkerQueue#1

MarkerQueue#1

SimpleSyncQueueArray<OpenCLABC.Buffer>#0
	MarkerQueue#1
	BufferCommandQueue#2
		CCCObj => Buffer[0] of size 1
		WaitCommand
			WCQWaiterAll => MarkerQueue#1

SimpleSyncQueueArray<System.Object>#0
	BufferCommandQueue#1
		CCCObj => Buffer[0] of size 1
		WaitCommand
			WCQWaiterAll => MarkerQueue#2
	CastQueue<System.Object>#3
		MarkerQueue#2

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAll => MarkerQueue#1

MarkerQueue#1

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAny => MarkerQueue#1

MarkerQueue#1

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAll
			MarkerQueue#1
			MarkerQueue#2

MarkerQueue#1

MarkerQueue#2

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAny
			MarkerQueue#1
			MarkerQueue#2

MarkerQueue#1

MarkerQueue#2


