


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
ThrCount.$delegate? = procedure
ThrCount.$delegate? = procedure
ThrCount.$delegate? = procedure

#ExpExecOtp
True 
True 
[EventDebug]: 34 event's created 
[QueueDebug]: 1 queue's created 
[QueueResNil]: 38 
[QueueRes<T>]: 1 
	QueueResValDirect<integer>: 1 

#ReqModules
OpenCLABC


