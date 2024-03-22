


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
Q выполнилась
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	branch#0/3 = ErrHandlerFlattener#1: MU repeater for CastQueue<integer,Object>
	victim = ErrHandlerInitial#2: Initial MU invoke
	branch#1/3 = ErrHandlerFlattener#3: MU repeater for CastQueue<integer,Object>
	victim = ErrHandlerInitial#2: Initial MU invoke
	branch#2/3 = ErrHandlerFlattener#4: MU repeater for CastQueue<integer,Object>
	victim = ErrHandlerInitial#2: Initial MU invoke
(total 5 handlers)
5 25 625
Q выполнилась
final = ErrHandlerFlattener#0: MU repeater for CastQueue<integer,Object>
victim = ErrHandlerInitial#1: Initial MU invoke
(total 2 handlers)
3125
[EventDebug]: 1 event's created
[QueueRes<T>]: 14
	QueueResValDirect<Object>: 2
	QueueResValDirect<array of integer>: 1
	QueueResValDirect<integer>: 6
	QueueResValDirect<real>: 1
	QueueResValWrap<Object>: 4

#ReqModules
OpenCLABC


