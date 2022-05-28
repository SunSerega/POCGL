


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
25 
(625, True) 
[EventDebug]: 2 event's created 
[QueueRes<T>]: 8 
	QueueResValDirect<(integer,boolean)>: 1 
	QueueResValDirect<integer>: 3 
	QueueResValDirect<Object>: 4 

#ReqModules
OpenCLABC


