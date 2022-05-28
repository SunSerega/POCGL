


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
1 2 3 4 5 6 7 8 9 10
(5,abc) 
1 2 3 4 5 6 7 8 9 10
(5,abc) 
[EventDebug]: 24 event's created 
[QueueRes<T>]: 28 
	QueueResValDirect<(integer,string)>: 2 
	QueueResValDirect<array of integer>: 2 
	QueueResValDirect<integer>: 22 
	QueueResValDirect<string>: 2 

#ReqModules
OpenCLABC


