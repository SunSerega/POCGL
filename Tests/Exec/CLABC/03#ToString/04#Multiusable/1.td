


#ReqModules
OpenCLABC

#ExpOtp
SimpleSyncQueueArray<System.Int32>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	SimpleAsyncQueueArray<System.Int32>#2
		MultiusableCommandQueueNode<System.Int32>#3 => CommandQueueHostFunc<System.Int32>#1
		MultiusableCommandQueueNode<System.Int32>#4 => CommandQueueHostFunc<System.Int32>#1

------------------------------

SimpleSyncQueueArray<System.Int32>#0
	SimpleAsyncQueueArray<System.Int32>#1
		MultiusableCommandQueueNode<System.Int32>#2 => CommandQueueHostFunc<System.Int32>#3
		MultiusableCommandQueueNode<System.Int32>#4 => CommandQueueHostFunc<System.Int32>#3
	CommandQueueHostFunc<System.Int32>#3 => System.Func`2[OpenCLABC.Context,System.Int32]

------------------------------

SimpleAsyncQueueArray<System.Int32>#0
	MultiusableCommandQueueNode<System.Int32>#1 => CommandQueueHostFunc<System.Int32>#2
	MultiusableCommandQueueNode<System.Int32>#3 => CommandQueueHostFunc<System.Int32>#2

CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

------------------------------


