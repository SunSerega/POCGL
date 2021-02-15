


#ReqModules
OpenCLABC

#ExpOtp
SimpleAsyncQueueArray<System.Object>#0
	ConstQueue<System.Object>#1 System.Byte{ 5 }

SimpleAsyncQueueArray<System.Object>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CastQueue<System.Object>#2
		CommandQueueHostFunc<System.Int32>#3 => System.Func`2[OpenCLABC.Context,System.Int32]

MemorySegmentCCQ#0
	CCCObj => MemorySegment[*] of size 1
	QueueCommand
		CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]


