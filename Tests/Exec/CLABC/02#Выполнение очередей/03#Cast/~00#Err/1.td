


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecErr
System.InvalidCastException: .Cast не может преобразовывать integer в word
   at OpenCLABC.CommandQueueBase.Cast[T]() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at 1.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\03#Cast\~00#Err\1.pas:line *
   at 1.Program.Main()

#ReqModules
OpenCLABC


