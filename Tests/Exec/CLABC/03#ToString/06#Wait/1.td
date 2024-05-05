


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
WaitMarkerAll#0
	WaitMarkerDummy#1
	WaitMarkerDummy#2

------------------------------

WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2
	WaitMarkerAll#3
		WaitMarkerDummy#4

------------------------------

WaitMarkerAll#0
	WaitMarkerDummy#1 * 2

------------------------------

WaitMarkerDummy#0

------------------------------

WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2 * 2
	WaitMarkerAll#3
		WaitMarkerDummy#2
		WaitMarkerDummy#4
	WaitMarkerAll#5
		WaitMarkerDummy#4 * 2

------------------------------

==============================

CommandQueueWaitFor#0
	WaitMarkerDummy#1

------------------------------

SimpleSyncQueueArrayNil#0
	WaitMarkerDummyExecutor#1
		WaitMarkerDummy#2
	CommandQueueWaitFor#3
		WaitMarkerDummy#2

------------------------------

SimpleSyncQueueArrayNil#0
	CommandQueueWaitFor#1
		WaitMarkerDummy#2
	WaitMarkerDummyExecutor#3
		WaitMarkerDummy#2

------------------------------

==============================

CLMemoryCCQ#0
	ConstQueue<CLMemory>#1: CLMemory[*] of size 1
	WaitCommand<CLMemory>
		WaitMarkerDummy#2

------------------------------

SimpleSyncQueueArray<CLMemory>#0
	WaitMarkerDummyExecutor#1
		WaitMarkerDummy#2
	CLMemoryCCQ#3
		ConstQueue<CLMemory>#4: CLMemory[*] of size 1
		WaitCommand<CLMemory>
			WaitMarkerDummy#2

------------------------------

SimpleSyncQueueArrayNil#0
	CLMemoryCCQ#1
		ConstQueue<CLMemory>#2: CLMemory[*] of size 1
		WaitCommand<CLMemory>
			WaitMarkerDummy#3
	WaitMarkerDummyExecutor#4
		WaitMarkerDummy#3

------------------------------

#ReqModules
OpenCLABC


