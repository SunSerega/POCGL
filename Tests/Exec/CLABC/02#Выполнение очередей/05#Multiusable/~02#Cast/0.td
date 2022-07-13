


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
Q выполнилась 
5 25 625
Q выполнилась 
3125 
[EventDebug]: 1 event's created 
[QueueRes<T>]: 14 
	QueueResValDirect<array of integer>: 1 
	QueueResValDirect<integer>: 6 
	QueueResValDirect<Object>: 2 
	QueueResValDirect<real>: 1 
	QueueResValWrap<Object>: 4 

#ReqModules
OpenCLABC


