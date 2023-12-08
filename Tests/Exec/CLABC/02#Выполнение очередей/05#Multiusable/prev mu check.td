


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
123 
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	branch#0/2 = ErrHandlerFlattener#1: MU repeater for SimpleSyncQueueArray<integer>
	victim = ErrHandlerInitial#2: Initial MU invoke
	branch#1/2 = ErrHandlerFlattener#3: MU repeater for SimpleSyncQueueArray<integer>
	victim = ErrHandlerInitial#2: Initial MU invoke
(total 4 handlers)
[EventDebug]: 3 event's created
[QueueResNil]: 2
[QueueRes<T>]: 4
	QueueResValDirect<integer>: 1
	QueueResValWrap<integer>: 3

#ReqModules
OpenCLABC


