


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
NullReferenceException 
final = ErrHandlerMURepeater#0: MU repeater for SimpleSyncQueueArray<CLArray<integer>>
	victim = ErrHandlerInitial#1: Initial MU invoke
origin = ErrHandlerBranchCombinator#2: CLArrayCommandWriteArrayAutoSize<integer> origin+par+enq union
	branch#0/3 = ErrHandlerInitial#3: ExecuteEnqFunc container
	branch#1/3 = ErrHandlerFlattener#4: MU repeater for SimpleSyncQueueArray<CLArray<integer>>
	victim = ErrHandlerInitial#1: Initial MU invoke
	branch#2/3 = ErrHandlerInitial#5: (origin-less) branch invoke
(total 6 handlers)
[EventDebug]: 1 event's created
[QueueDebug]: 1 queue's created
[QueueResNil]: 4
[QueueRes<T>]: 2
	QueueResValDirect<array of integer>: 1
	QueueResValDirect<CLArray<integer>>: 1

#ReqModules
OpenCLABC


