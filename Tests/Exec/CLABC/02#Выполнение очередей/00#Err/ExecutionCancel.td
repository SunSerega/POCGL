


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK:1
   at ExecutionCancel.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c, String err_test_reason) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at ExecutionCancel.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at ExecutionCancel.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK:1
   at ExecutionCancel.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c, String err_test_reason) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

---> (Inner Exception #1) System.Exception: TestOK:2
   at ExecutionCancel.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c, String err_test_reason) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


