


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC_implementation______.DCommandQueueThreadedArray2MakeBody<TInp1, TInp2, TR> = function(acts: QueueResComplDelegateData; qr1: QueueRes<TInp1>; qr2: QueueRes<TInp2>; err_handler: CLTaskErrHandler; c: CLContext; own_qr: TR; err_test_reason: string): procedure
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

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


