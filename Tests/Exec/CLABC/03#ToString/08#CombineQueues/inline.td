


#ReqModules
OpenCLABC

#ExpOtp
SimpleSyncQueueArray<System.Int32>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

SimpleAsyncQueueArray<System.Int32>#0
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]
	CommandQueueHostFunc<System.Int32>#1 => System.Func`2[OpenCLABC.Context,System.Int32]

SimpleAsyncQueueArray<System.Int32>#0
	SimpleSyncQueueArray<System.Int32>#1
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]
	SimpleSyncQueueArray<System.Int32>#3
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]

SimpleSyncQueueArray<System.Int32>#0
	SimpleAsyncQueueArray<System.Int32>#1
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]
	SimpleAsyncQueueArray<System.Int32>#3
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]
		CommandQueueHostFunc<System.Int32>#2 => System.Func`2[OpenCLABC.Context,System.Int32]


