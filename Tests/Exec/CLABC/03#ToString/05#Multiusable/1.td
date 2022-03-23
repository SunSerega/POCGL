


#ReqModules
OpenCLABC

#ExpOtp
SimpleSyncQueueArray<integer>#0
	CommandQueueHostBackgoundFunc<integer>#1: function lambda: integer
	SimpleAsyncQueueArray<integer>#2
		MultiusableCommandQueueNode<integer>#3 => CommandQueueHostBackgoundFunc<integer>#1
		MultiusableCommandQueueNode<integer>#4 => CommandQueueHostBackgoundFunc<integer>#1

------------------------------

SimpleSyncQueueArray<integer>#0
	SimpleAsyncQueueArray<integer>#1
		MultiusableCommandQueueNode<integer>#2 => CommandQueueHostBackgoundFunc<integer>#3
		MultiusableCommandQueueNode<integer>#4 => CommandQueueHostBackgoundFunc<integer>#3
	CommandQueueHostBackgoundFunc<integer>#3: function lambda: integer

------------------------------

SimpleAsyncQueueArray<integer>#0
	MultiusableCommandQueueNode<integer>#1 => CommandQueueHostBackgoundFunc<integer>#2
	MultiusableCommandQueueNode<integer>#3 => CommandQueueHostBackgoundFunc<integer>#2

CommandQueueHostBackgoundFunc<integer>#2: function lambda: integer

------------------------------

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 


