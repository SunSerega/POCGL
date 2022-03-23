


#ReqModules
OpenCLABC

#ExpOtp
CastQueue<byte, Object>#0
	ConstQueue<byte>#1: 5

SimpleAsyncQueueArray<Object>#0
	CommandQueueHostBackgoundFunc<integer>#1: function lambda: integer
	CastQueue<integer, Object>#2
		CommandQueueHostBackgoundFunc<integer>#3: function lambda: integer

MemorySegmentCCQ#0
	CCCObj: MemorySegment[*] of size 1
	QueueCommand
		CommandQueueHostBackgoundFunc<integer>#1: function lambda: integer

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 


