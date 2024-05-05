


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
final = ErrHandlerBranchCombinator#0: CLMemoryCommandWriteValue<real> origin+par+enq union
	branch#0/2 = ErrHandlerInitial#1: ExecuteEnqFunc container
	branch#1/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		branch#0/2 = ErrHandlerInitial#3: ExecuteEnqFunc container
		branch#1/2 = ErrHandlerInitial#4: ExecuteEnqFunc container
(total 5 handlers)
[EventDebug]: 4 event's created
[QueueDebug]: 2 queue's created
[QueueResNil]: 9
[QueueRes<T>]: 4
	QueueResValDirect<CLMemory>: 1
	QueueResValDirect<integer>: 3

#ReqModules
OpenCLABC


