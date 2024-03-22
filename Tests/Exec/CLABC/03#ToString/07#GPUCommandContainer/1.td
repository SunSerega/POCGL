


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
CLKernelCCQ#0
	ConstQueue<CLKernel>#1: CLKernel[k] from CLProgramCode[*]
	CLKernelCommandExec2
		sz1: ConstQueue<integer>#2: 1
		sz2: ConstQueue<integer>#3: 1
		args:
			CLKernelArgGlobalCLMemory
				CLMemoryCCQ#4
					MultiusableCommandQueue<CLMemory>#5 => CommandQueueHostThreadedFunc<CLMemory,SimpleFunc0Container<CLMemory>>#6
					QueueCommand<CLMemory>
						CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#7: function lambda: integer
					QuickProcCommand<CLMemory,SimpleProcContainer<CLMemory>>: procedure lambda(m: CLMemory)
					QuickProcCommand<CLMemory,SimpleProcContainer<CLMemory>>: procedure lambda(m: CLMemory)
					ThreadedProcCommand<CLMemory,SimpleProcContainer<CLMemory>>: procedure lambda(m: CLMemory)
			CLKernelArgPrivateValue<integer>
				ConstQueue<integer>#8: 5

CommandQueueHostThreadedFunc<CLMemory,SimpleFunc0Container<CLMemory>>#6: function lambda: CLMemory

[ExecDebug]: 1 cache entries created

#ReqModules
OpenCLABC


