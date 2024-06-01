


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
CommandQueueQuickArray<integer, array of integer, QueueArrayAsyncInvoker, SimpleFuncContainer<array of integer, array of integer>, QueueArrayWorkConvert<integer, array of integer, SimpleFuncContainer<array of integer, array of integer>>>#0
	ConstQueue<integer>#1: 5
	CommandQueueHostQuickFunc<integer, SimpleFunc0Container<integer>>#2: ((function lambda(x: integer): integer),5) => function lambda: integer
	function lambda(a: array of integer): array of integer
final = ErrHandlerInitial#0: (origin-less) branch invoke
(total 1 handlers)
5 25
[QueueRes<T>]: 3
	QueueResValDirect<array of integer>: 1
	QueueResValDirect<integer>: 2

#ReqModules
OpenCLABC


