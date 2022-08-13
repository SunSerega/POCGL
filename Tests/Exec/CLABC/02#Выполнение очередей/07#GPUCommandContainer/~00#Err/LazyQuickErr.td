


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at LazyQuickErr.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\LazyQuickErr.pas:line *
   at OpenCLABC_implementation______.SimpleFunc0Container`1.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostFuncBase`2.InvokeFunc(CLTaskErrHandler err_handler, CLContext c, String err_test_reason) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLTask`1.WaitRes() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at LazyQuickErr.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\LazyQuickErr.pas:line *
   at LazyQuickErr.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at LazyQuickErr.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\LazyQuickErr.pas:line *
   at OpenCLABC_implementation______.SimpleFunc0Container`1.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostFuncBase`2.InvokeFunc(CLTaskErrHandler err_handler, CLContext c, String err_test_reason) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


