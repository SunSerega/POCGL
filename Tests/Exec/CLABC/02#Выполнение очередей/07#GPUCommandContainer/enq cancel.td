


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
HFQ+2
HPQ+1
TestOK+2
TestOK+1
TestOK+1
final = ErrHandlerMURepeater#0: MU repeater for SimpleSyncQueueArray<CLArray<integer>>
	victim = ErrHandlerInitial#1: Initial MU invoke
origin = ErrHandlerBranchCombinator#2: CLArrayCommandWriteValue<integer> origin+par+enq union
	branch#0/3 = ErrHandlerInitial#3: (origin-less) branch invoke
	branch#1/3 = ErrHandlerInitial#4: ExecuteEnqFunc container
	branch#2/3 = ErrHandlerFlattener#5: MU repeater for SimpleSyncQueueArray<CLArray<integer>>
	victim = ErrHandlerInitial#1: Initial MU invoke
(total 6 handlers)
Expect 3 evs: HPQ + HFQ + async enq
[EventDebug]: 3 event's created
[QueueDebug]: 1 queue's created
[QueueResNil]: 4
[QueueRes<T>]: 2
	QueueResValDirect<CLArray<integer>>: 1
	QueueResValDirect<integer>: 1

#ReqModules
OpenCLABC


