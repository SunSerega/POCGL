


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

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


