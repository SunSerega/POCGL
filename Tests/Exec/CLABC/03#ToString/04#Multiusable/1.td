


#ReqModules
OpenCLABC

#ExpOtp
SimpleSyncQueueArray<System.Int32>#0
	CommandQueueHostBackgoundFunc<System.Int32>#1: Int32 <>lambda*()
	SimpleAsyncQueueArray<System.Int32>#2
		MultiusableCommandQueueNode<System.Int32>#3 => CommandQueueHostBackgoundFunc<System.Int32>#1
		MultiusableCommandQueueNode<System.Int32>#4 => CommandQueueHostBackgoundFunc<System.Int32>#1

------------------------------

SimpleSyncQueueArray<System.Int32>#0
	SimpleAsyncQueueArray<System.Int32>#1
		MultiusableCommandQueueNode<System.Int32>#2 => CommandQueueHostBackgoundFunc<System.Int32>#3
		MultiusableCommandQueueNode<System.Int32>#4 => CommandQueueHostBackgoundFunc<System.Int32>#3
	CommandQueueHostBackgoundFunc<System.Int32>#3: Int32 <>lambda*()

------------------------------

SimpleAsyncQueueArray<System.Int32>#0
	MultiusableCommandQueueNode<System.Int32>#1 => CommandQueueHostBackgoundFunc<System.Int32>#2
	MultiusableCommandQueueNode<System.Int32>#3 => CommandQueueHostBackgoundFunc<System.Int32>#2

CommandQueueHostBackgoundFunc<System.Int32>#2: Int32 <>lambda*()

------------------------------

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 


