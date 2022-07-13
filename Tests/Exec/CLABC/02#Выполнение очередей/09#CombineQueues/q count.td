


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
[EventDebug]: 4 event's created 
[QueueDebug]: 2 queue's created 
[QueueResNil]: 9 
[QueueRes<T>]: 4 
	QueueResValDirect<CLMemory>: 1 
	QueueResValDirect<integer>: 3 

#ReqModules
OpenCLABC


