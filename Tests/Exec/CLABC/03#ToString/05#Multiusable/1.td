


#DelegateCount
5

#ExpOtp
SimpleSyncQueueArray<integer>#0
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	SimpleAsyncQueueArray<integer>#2
		MultiusableCommandQueueNode<integer>#3 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1
		MultiusableCommandQueueNode<integer>#4 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1

------------------------------
 
SimpleSyncQueueArray<integer>#0
	SimpleAsyncQueueArray<integer>#1
		MultiusableCommandQueueNode<integer>#2 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3
		MultiusableCommandQueueNode<integer>#4 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3: function lambda: integer

------------------------------
 
SimpleAsyncQueueArray<integer>#0
	MultiusableCommandQueueNode<integer>#1 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2
	MultiusableCommandQueueNode<integer>#3 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2

CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer

------------------------------
 

#ReqModules
OpenCLABC


