


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
CommandQueueQuickArray<integer,array of integer,QueueArrayAsyncInvoker,SimpleFuncContainer<array of integer,array of integer>,QueueArrayWorkConvert<integer,array of integer,SimpleFuncContainer<array of integer,array of integer>>>#0
	ConstQueue<integer>#1: 5
	CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#2: (((Int32 <>lambda*(Int32),nil)),5) => function lambda: integer
	function lambda(a: array of integer): array of integer
5 25
[QueueRes<T>]: 3 
	QueueResValDirect<array of integer>: 1 
	QueueResValDirect<integer>: 2 

#ReqModules
OpenCLABC


