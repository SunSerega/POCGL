


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function(T, cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
SimpleSyncQueueArray<integer>#0
	CLArrayCCQ<byte>#1
		ConstQueue<CLArray<byte>>#2: CLArray<byte>[*] of length 1
		CLArrayCommandWriteValue<byte>
			val: 1
			ind: ConstQueue<integer>#3: 2
	ConstQueue<integer>#4: 3

SimpleSyncQueueArray<integer>#0
	CLArrayCCQ<byte>#1
		ConstQueue<CLArray<byte>>#2: CLArray<byte>[*] of length 1
		CLArrayCommandWriteValueQ<byte>
			val: ConstQueue<byte>#3: 1
			ind: ConstQueue<integer>#4: 2
	ConstQueue<integer>#5: 3

#ReqModules
OpenCLABC


