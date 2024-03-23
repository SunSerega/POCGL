


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at handle only branch.Program.<>lambda*() in *\\POCGL\\Tests\\Exec\\CLABC\\02#Выполнение очередей\\11#Finally+Handle\\~00#Err\\handle only branch.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke(ISimpleProc0Container self, CLTaskGlobalData insta_call_g, ErrHandler err_handler, String err_test_reason, CLContext c) in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   at handle only branch.Program.$Main() in *\\POCGL\\Tests\\Exec\\CLABC\\02#Выполнение очередей\\11#Finally+Handle\\~00#Err\\handle only branch.pas:line *
   at handle only branch.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at handle only branch.Program.<>lambda*() in *\\POCGL\\Tests\\Exec\\CLABC\\02#Выполнение очередей\\11#Finally+Handle\\~00#Err\\handle only branch.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke(ISimpleProc0Container self, CLTaskGlobalData insta_call_g, ErrHandler err_handler, String err_test_reason, CLContext c) in *\\POCGL\\Tests\\LibSource\\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


