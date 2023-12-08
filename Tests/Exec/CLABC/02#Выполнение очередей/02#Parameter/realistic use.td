


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
abc 
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
1 
def 
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
2 
[EventDebug]: 4 event's created
[QueueDebug]: 2 queue's created
[QueueResNil]: 6
[QueueRes<T>]: 8
	QueueResPtr<integer>: 4
	QueueResValDirect<CLValue<integer>>: 2
	QueueResValDirect<string>: 2

#ReqModules
OpenCLABC


