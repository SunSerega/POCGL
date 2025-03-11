


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: CLMemory[@[1..*0..9A..F]] of size 1, TestOK
   at AddProc.<>local_variables_class_@[1..*0..9].<>lambda@[1..*0..9](CLMemory <>b) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddProc.pas:line @[1..*0..9]
   at OpenCLABC_implementation______.SimpleProcContainer`1.Invoke(TInp inp, CLContext c) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp](ISimpleProcContainer`1 self, CLTaskGlobalData insta_call_g, ErrHandler err_handler, String err_test_reason, TInp inp, CLContext c) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at OpenCLABC.CLTask`1.WaitRes() in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at AddProc.Program.$Main() in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddProc.pas:line @[1..*0..9]
   at AddProc.Program.Main()
---> (Inner Exception #0) System.Exception: CLMemory[@[1..*0..9A..F]] of size 1, TestOK
   at AddProc.<>local_variables_class_@[1..*0..9].<>lambda@[1..*0..9](CLMemory <>b) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddProc.pas:line @[1..*0..9]
   at OpenCLABC_implementation______.SimpleProcContainer`1.Invoke(TInp inp, CLContext c) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp](ISimpleProcContainer`1 self, CLTaskGlobalData insta_call_g, ErrHandler err_handler, String err_test_reason, TInp inp, CLContext c) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]<---

#ReqModules
OpenCLABC


