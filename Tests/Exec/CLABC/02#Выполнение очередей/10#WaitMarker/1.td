﻿


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
nil
final = ErrHandlerInitial#0: (origin-less) branch invoke
(total 1 handlers)
5
final = ErrHandlerInitial#0: (origin-less) branch invoke
(total 1 handlers)
5
[EventDebug]: 7 event's created
[WaitDebug]: 6 wait handler's created
[QueueResNil]: 5
[QueueRes<T>]: 7
	QueueResValDirect<Object>: 3
	QueueResValDirect<integer>: 2
	QueueResValWrap<integer>: 2

#ReqModules
OpenCLABC


