


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
ConstQueue<Object>#0: byte{ 5 }
 
SimpleAsyncQueueArray<Object>#0
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	CastQueue<integer,Object>#2
		CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3: function lambda: integer
 
CLMemoryCCQ#0
	ConstQueue<CLMemory>#1: CLMemory[*] of size 1
	QueueCommand<CLMemory>
		CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer

#ReqModules
OpenCLABC


