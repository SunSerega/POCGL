


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
Err#0
------------------------------ 
Err#1
------------------------------ 
Err#2
------------------------------ 
Err#3
------------------------------ 
Err#4
------------------------------ 
Err#5
------------------------------ 
Err#6
------------------------------ 
Err#7
------------------------------ 
Err#8
------------------------------ 
Err#9
------------------------------ 
[EventDebug]: 100 event's created 
[QueueResNil]: 130 

#ReqModules
OpenCLABC


