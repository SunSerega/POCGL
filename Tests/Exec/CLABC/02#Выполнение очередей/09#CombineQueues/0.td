


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.DCommandQueueThreadedArray2MakeBody<[TInp1], [TInp2], [TR]> = function(acts: QueueResComplDelegateData; qr1: QueueRes<[TInp1]>; qr2: QueueRes<[TInp2]>; err_handler: ErrHandler; c: CLContext; own_qr: [TR]; err_test_reason: string): procedure
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
final = ErrHandlerInitial#0: Initial CLTask invoke
(total 1 handlers)
1 2 3 4 5 6 7 8 9 10
final = ErrHandlerInitial#0: Initial CLTask invoke
(total 1 handlers)
(5,abc)
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	branch#0/10 = ErrHandlerInitial#1: (origin-less) branch invoke
	branch#1/10 = ErrHandlerInitial#2: (origin-less) branch invoke
	branch#2/10 = ErrHandlerInitial#3: (origin-less) branch invoke
	branch#3/10 = ErrHandlerInitial#4: (origin-less) branch invoke
	branch#4/10 = ErrHandlerInitial#5: (origin-less) branch invoke
	branch#5/10 = ErrHandlerInitial#6: (origin-less) branch invoke
	branch#6/10 = ErrHandlerInitial#7: (origin-less) branch invoke
	branch#7/10 = ErrHandlerInitial#8: (origin-less) branch invoke
	branch#8/10 = ErrHandlerInitial#9: (origin-less) branch invoke
	branch#9/10 = ErrHandlerInitial#10: (origin-less) branch invoke
(total 11 handlers)
1 2 3 4 5 6 7 8 9 10
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	branch#0/2 = ErrHandlerInitial#1: (origin-less) branch invoke
	branch#1/2 = ErrHandlerInitial#2: (origin-less) branch invoke
(total 3 handlers)
(5,abc)
[EventDebug]: 24 event's created
[QueueRes<T>]: 28
	QueueResValDirect<(integer, string)>: 2
	QueueResValDirect<array of integer>: 2
	QueueResValDirect<integer>: 22
	QueueResValDirect<string>: 2

#ReqModules
OpenCLABC


