


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
WaitMarkerDummy#0
 
------------------------------
 
CommandQueueMarkedCap<integer>#0
	CommandQueueMarkedCapWrapper<CommandQueue<integer>>#1
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer
 
------------------------------
 
CommandQueueMarkedCapWrapper<CommandQueue<integer>>#0
	CommandQueueMarkedCap<integer>#1
 
------------------------------
 
CommandQueueMarkedCap<integer>#0
	CommandQueueMarkedCapWrapper<CommandQueue<integer>>#1
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer
 
------------------------------
 
SimpleAsyncQueueArray<integer>#0
	CommandQueueWaitFor#1
		CommandQueueMarkedCapWrapper<CommandQueue<integer>>#2
			CommandQueueMarkedCap<integer>#3
	CommandQueueMarkedCap<integer>#3
		CommandQueueMarkedCapWrapper<CommandQueue<integer>>#2
		CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#4: function lambda: integer
 
------------------------------
 
WaitMarkerAll#0
	CommandQueueMarkedCapWrapper<CommandQueue<integer>>#1
		CommandQueueMarkedCap<integer>#2 * 2
 
------------------------------
 
CommandQueueMarkedCapWrapper<CommandQueue<integer>>#0
	CommandQueueMarkedCap<integer>#1
 
------------------------------
 

#ReqModules
OpenCLABC


