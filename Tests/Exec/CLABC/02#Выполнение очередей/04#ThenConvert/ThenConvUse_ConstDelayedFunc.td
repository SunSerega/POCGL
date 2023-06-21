


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

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
[QueueResNil]: 2 
[QueueRes<T>]: 17 
	QueueResValDirect<integer>: 10 
	QueueResValDirect<Object>: 2 
	QueueResValWrap<integer>: 5 

#ReqModules
OpenCLABC


