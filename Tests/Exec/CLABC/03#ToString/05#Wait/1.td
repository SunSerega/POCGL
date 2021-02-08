


#ReqModules
OpenCLABC

#ExpOtp
CommandQueueWaitFor#0
	WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

SimpleSyncQueueArray<System.Object>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueWaitFor#2
		WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

SimpleSyncQueueArray<System.Int32>#0
	CommandQueueWaitFor#1
		WCQWaiterAll => CommandQueueHostFunc<System.Int32>#2
	CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueWaitFor#0
	WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueWaitFor#0
	WCQWaiterAny => CommandQueueHostFunc<System.Int32>#1

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueWaitFor#0
	WCQWaiterAll
		CommandQueueHostFunc<System.Int32>#1
		CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueWaitFor#0
	WCQWaiterAny
		CommandQueueHostFunc<System.Int32>#1
		CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

==============================

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll => CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

SimpleSyncQueueArray<System.Object>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueThenWaitFor<System.Object>#2
		ConstQueue<System.Object>#3 { nil }
		WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

SimpleSyncQueueArray<System.Int32>#0
	CommandQueueThenWaitFor<System.Object>#1
		ConstQueue<System.Object>#2 { nil }
		WCQWaiterAll => CommandQueueHostFunc<System.Int32>#3
	CommandQueueHostFunc<System.Int32>#3 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll => CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAny => CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAll
		CommandQueueHostFunc<System.Int32>#2
		CommandQueueHostFunc<System.Int32>#3

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueHostFunc<System.Int32>#3 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueThenWaitFor<System.Object>#0
	ConstQueue<System.Object>#1 { nil }
	WCQWaiterAny
		CommandQueueHostFunc<System.Int32>#2
		CommandQueueHostFunc<System.Int32>#3

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueHostFunc<System.Int32>#3 => System.Func`2[OpenCLABC.Context,System.Int32]

==============================

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

SimpleSyncQueueArray<OpenCLABC.Buffer>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	BufferCommandQueue#2
		CCCObj => Buffer[0] of size 1
		WaitCommand
			WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

SimpleSyncQueueArray<System.Int32>#0
	BufferCommandQueue#1
		CCCObj => Buffer[0] of size 1
		WaitCommand
			WCQWaiterAll => CommandQueueHostFunc<System.Int32>#2
	CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAll => CommandQueueHostFunc<System.Int32>#1

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAny => CommandQueueHostFunc<System.Int32>#1

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAll
			CommandQueueHostFunc<System.Int32>#1
			CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

BufferCommandQueue#0
	CCCObj => Buffer[0] of size 1
	WaitCommand
		WCQWaiterAny
			CommandQueueHostFunc<System.Int32>#1
			CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]


