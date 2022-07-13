


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
5 
7 
[EventDebug]: 3 event's created 
[QueueDebug]: 3 queue's created 
[QueueResNil]: 4 
[QueueRes<T>]: 5 
	QueueResPtr<byte>: 2 
	QueueResValDirect<CLValue<byte>>: 3 

#ReqModules
OpenCLABC


