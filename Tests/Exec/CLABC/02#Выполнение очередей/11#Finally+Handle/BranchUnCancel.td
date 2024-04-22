


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function(T, cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
Calculated anyway
TestOK
final = ErrHandlerBranchCombinator#0: CLArrayCommandWriteValue<byte> origin+par+enq union
	branch#0/2 = ErrHandlerInitial#1: (origin-less) CommandQueueHandleWithoutRes: try_do
	branch#1/2 = ErrHandlerInitial#2: (origin-less) branch invoke
(total 3 handlers)
[EventDebug]: 1 event's created
[QueueDebug]: 1 queue's created
[QueueResNil]: 4
[QueueRes<T>]: 1
	QueueResValDirect<integer>: 1

#ReqModules
OpenCLABC


