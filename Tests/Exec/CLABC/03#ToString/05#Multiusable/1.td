


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
SimpleSyncQueueArray<integer>#0
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	SimpleAsyncQueueArray<integer>#2
		MultiusableCommandQueue<integer>#3 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1
		MultiusableCommandQueue<integer>#3 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#1

------------------------------
 
SimpleSyncQueueArray<integer>#0
	SimpleAsyncQueueArray<integer>#1
		MultiusableCommandQueue<integer>#2 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3
		MultiusableCommandQueue<integer>#2 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3
	CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#3: function lambda: integer

------------------------------
 
SimpleAsyncQueueArray<integer>#0
	MultiusableCommandQueue<integer>#1 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2
	MultiusableCommandQueue<integer>#1 => CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2

CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#2: function lambda: integer

------------------------------
 

#ReqModules
OpenCLABC


