


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
CommandQueueQuickArray<Object,array of Object,QueueArraySyncInvoker,SimpleFuncContainer<array of Object,array of Object>,QueueArrayWorkConvert<Object,array of Object,SimpleFuncContainer<array of Object,array of Object>>,TBooleanFalseFlag>#0
	ConstQueue<Object>#1: { nil }
	ConstQueue<Object>#1: { nil }
	function lambda(a: array of Object): array of Object

CommandQueueQuickArray<Object,array of Object,QueueArrayAsyncInvoker,SimpleFuncContainer<array of Object,array of Object>,QueueArrayWorkConvert<Object,array of Object,SimpleFuncContainer<array of Object,array of Object>>,TBooleanFalseFlag>#0
	ConstQueue<Object>#1: { nil }
	ConstQueue<Object>#1: { nil }
	function lambda(a: array of Object): array of Object

#ReqModules
OpenCLABC


