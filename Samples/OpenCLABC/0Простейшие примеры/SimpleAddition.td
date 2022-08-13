


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
1 2 3 4 5 6 7 8 9 10
[EventDebug]: 3 event's created 
[QueueDebug]: 2 queue's created 
[ExecDebug]: 1 cache entries created 
[QueueResNil]: 5 
[QueueRes<T>]: 5 
	QueueResValDirect<array of integer>: 1 
	QueueResValDirect<CLArray<integer>>: 2 
	QueueResValDirect<CLKernel>: 1 
	QueueResValDirect<integer>: 1 

#ReqModules
OpenCLABC

#TestMode
Comp+Exec


