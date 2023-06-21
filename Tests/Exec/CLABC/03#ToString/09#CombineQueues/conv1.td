


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
CommandQueueHostQuickFunc<array of Object,SimpleFunc0Container<array of Object>>#0: (((System.Object[] <>lambda*(System.Object[]),nil)),[nil,nil]) => function lambda: array of Object

CommandQueueHostQuickFunc<array of Object,SimpleFunc0Container<array of Object>>#0: (((System.Object[] <>lambda*(System.Object[]),nil)),[nil,nil]) => function lambda: array of Object

#ReqModules
OpenCLABC


