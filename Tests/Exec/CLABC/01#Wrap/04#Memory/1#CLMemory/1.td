


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
1020304
[EventDebug]: 2 event's created
[QueueDebug]: 2 queue's created
[QueueResNil]: 3
[QueueRes<T>]: 5
	QueueResPtr<integer>: 1
	QueueResValDirect<CLMemory>: 2
	QueueResValDirect<integer>: 2

#ReqModules
OpenCLABC


