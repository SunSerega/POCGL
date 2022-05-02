


#DelegateCount
3

#ExpOtp
ConstQueue<Object>#0: byte{ 5 }
 
SimpleAsyncQueueArray<Object>#0
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	CastQueue<integer,Object>#2
		CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3: function lambda: integer
 
CLMemoryCCQ#0
	CCCObj<CLMemory>: CLMemory[*] of size 1
	QueueCommand<CLMemory>
		CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer

#ReqModules
OpenCLABC


