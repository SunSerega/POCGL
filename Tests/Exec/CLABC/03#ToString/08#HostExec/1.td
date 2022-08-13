


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#0: function lambda: integer

CommandQueueHostQuickProc<SimpleProc0Container>#0: procedure lambda

CommandQueueHostQuickFunc<integer,SimpleFunc0ContainerC<integer>>#0: function lambda(с: CLContext): integer

CommandQueueHostQuickProc<SimpleProc0ContainerC>#0: procedure lambda(с: CLContext)

CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#0: function lambda: integer

CommandQueueHostThreadedProc<SimpleProc0Container>#0: procedure lambda

CommandQueueHostThreadedFunc<integer,SimpleFunc0ContainerC<integer>>#0: function lambda(с: CLContext): integer

CommandQueueHostThreadedProc<SimpleProc0ContainerC>#0: procedure lambda(с: CLContext)

#ReqModules
OpenCLABC


