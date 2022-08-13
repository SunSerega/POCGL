


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
abc 
1 
def 
2 
[EventDebug]: 4 event's created 
[QueueDebug]: 2 queue's created 
[QueueResNil]: 6 
[QueueRes<T>]: 12 
	QueueResPtr<integer>: 4 
	QueueResValDirect<CLMemory>: 2 
	QueueResValDirect<integer>: 4 
	QueueResValDirect<string>: 2 

#ReqModules
OpenCLABC


