


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
First#1 
First#2 
Second#1 
Second#2 
final = ErrHandlerMURepeater#0: MU repeater for SimpleSyncQueueArray<CLArray<integer>>
	victim = ErrHandlerInitial#1: Initial MU invoke
origin = ErrHandlerBranchCombinator#2: CLArrayCommandWriteValueQ<integer> origin+par+enq union
	branch#0/3 = ErrHandlerInitial#3: ExecuteEnqFunc container
	branch#1/3 = ErrHandlerMURepeater#4: MU repeater for SimpleSyncQueueArray<CLArray<integer>>
		victim = ErrHandlerInitial#1: Initial MU invoke
	origin = ErrHandlerBranchCombinator#5: CLArrayCommandWriteValueQ<integer> origin+par+enq union
		branch#0/3 = ErrHandlerInitial#6: (origin-less) branch invoke
		branch#1/3 = ErrHandlerInitial#7: ExecuteEnqFunc container
		branch#2/3 = ErrHandlerInitial#8: (origin-less) branch invoke
	branch#2/3 = ErrHandlerInitial#9: (origin-less) branch invoke
(total 10 handlers)
[EventDebug]: 7 event's created
[QueueDebug]: 2 queue's created
[QueueResNil]: 6
[QueueRes<T>]: 6
	QueueResPtr<integer>: 2
	QueueResValDirect<CLArray<integer>>: 1
	QueueResValDirect<integer>: 2
	QueueResValWrap<CLArray<integer>>: 1

#ReqModules
OpenCLABC


