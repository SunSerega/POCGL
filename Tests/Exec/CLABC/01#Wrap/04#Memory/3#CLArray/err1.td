


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function(T, cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecErr
System.TypeInitializationException: The type initializer for 'OpenCLABC.CLArray`1' threw an exception. ---> OpenCLABC_implementation______.BlittableException: Значения типа boolean нельзя использовать как элементы CLArray<>
   at OpenCLABC_implementation______.BlittableHelper.RaiseIfBad(Type t, String source_name) in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   at OpenCLABC.CLArray`1..cctor() in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLArray`1..ctor(Int32 len, CLMemoryUsage kernel_use, CLMemoryUsage map_use)
   at err1.Program.$Main() in *\\POCGL\\Tests\\Exec\\CLABC\\01#Wrap\\04#Memory\\3#CLArray\\err1.pas:line *
   at err1.Program.Main()

#ReqModules
OpenCLABC


