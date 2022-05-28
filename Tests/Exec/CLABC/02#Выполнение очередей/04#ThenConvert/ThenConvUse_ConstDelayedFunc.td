


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
ConstQueue<integer>#0: 2
------------------------------ 
2 
4 
4 
------------------------------ 
2 
4 
5 
============================== 
CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#0: function lambda: integer
------------------------------ 
3 
9 
9 
------------------------------ 
3 
9 
10 
============================== 
CastQueue<Object,integer>#0
	CommandQueueHostThreadedFunc<Object,SimpleFunc0Container<Object>>#1: function lambda: Object
------------------------------ 
4 
16 
16 
------------------------------ 
4 
16 
17 
============================== 
[EventDebug]: 13 event's created 
[QueueRes<T>]: 20 
	QueueResValDirect<integer>: 12 
	QueueResValDirect<Object>: 2 
	QueueResValWrap<integer>: 6 

#ReqModules
OpenCLABC


