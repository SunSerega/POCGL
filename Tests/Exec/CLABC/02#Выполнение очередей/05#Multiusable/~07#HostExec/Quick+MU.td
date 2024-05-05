


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
CommandQueueQuickArray<integer, array of integer, QueueArraySyncInvoker, SimpleFuncContainer<array of integer, array of integer>, QueueArrayWorkConvert<integer, array of integer, SimpleFuncContainer<array of integer, array of integer>>>#0
	MultiusableCommandQueue<integer>#1 => CommandQueueHostQuickFunc<integer, SimpleFunc0Container<integer>>#2
	MultiusableCommandQueue<integer>#1 => CommandQueueHostQuickFunc<integer, SimpleFunc0Container<integer>>#2
	function lambda(a: array of integer): array of integer

CommandQueueHostQuickFunc<integer, SimpleFunc0Container<integer>>#2: function lambda: integer

1
final = ErrHandlerMURepeater#0: MU repeater for CommandQueueHostQuickFunc<integer, SimpleFunc0Container<integer>>
	victim = ErrHandlerInitial#1: Initial MU invoke
origin = ErrHandlerFlattener#2: MU repeater for CommandQueueHostQuickFunc<integer, SimpleFunc0Container<integer>>
victim = ErrHandlerInitial#1: Initial MU invoke
(total 3 handlers)
2 2
[QueueRes<T>]: 4
	QueueResValDirect<array of integer>: 1
	QueueResValDirect<integer>: 1
	QueueResValWrap<integer>: 2

#ReqModules
OpenCLABC


