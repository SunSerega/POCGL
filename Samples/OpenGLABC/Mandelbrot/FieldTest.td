


#Delegates
Blocks.$delegate? = procedure(<>ml: MemoryLayer<PointBlock>)
Blocks.$delegate? = procedure(<>ml: MemoryLayer<PointBlock>)
Blocks.$delegate? = procedure(e: Exception)
Blocks.$delegate? = procedure(ml: MemoryLayer<PointBlock>)
FieldTest.$delegate? = function: boolean
FieldTest.$delegate? = function: boolean
FieldTest.$delegate? = function: boolean
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>
PointComponents.$delegate? = procedure(<>m: string)
PointComponents.$delegate? = procedure(<>m: string)
PointComponents.$delegate? = procedure(m: string)
PointComponents.$delegate? = procedure(m: string)
PointComponents.$delegate? = procedure(m: string)

#ExpExecOtp
Updates: 115036204 
Extracted: 4194304 
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
Used a total of 83886228 VRAM bytes 
[EventDebug]: 56 event's created
[QueueDebug]: 1 queue's created
[ExecDebug]: 32 cache entries created
[QueueResNil]: 158
[QueueRes<T>]: 73
	QueueResPtr<longword>: 2
	QueueResValDirect<array [,] of longword>: 1
	QueueResValDirect<array of longword>: 1
	QueueResValDirect<CLArray<longword>>: 1
	QueueResValDirect<CLValue<longword>>: 2
	QueueResValDirect<integer>: 66

#ReqModules
OpenCLABC

#TestMode
Comp+Exec


