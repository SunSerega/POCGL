


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at 0.Program.<>lambda*(Int32 <>i) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0.pas:line *
   at OpenCLABC_implementation______.SimpleFuncContainer`2.Invoke(TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp,TRes](ISimpleFuncContainer`2 self, CLTaskErrHandler err_handler, String err_test_reason, TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLTask`1.WaitRes() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at 0.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0.pas:line *
   at 0.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at 0.Program.<>lambda*(Int32 <>i) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0.pas:line *
   at OpenCLABC_implementation______.SimpleFuncContainer`2.Invoke(TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp,TRes](ISimpleFuncContainer`2 self, CLTaskErrHandler err_handler, String err_test_reason, TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


