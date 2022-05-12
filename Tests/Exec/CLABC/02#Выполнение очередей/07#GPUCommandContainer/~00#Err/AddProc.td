


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: CLMemory[*] of size 1, TestOK
   at AddProc.<>local_variables_class_*.<>lambda*(CLMemory <>b) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddProc.pas:line *
   at OpenCLABC_implementation______.SimpleProcContainer`1.Invoke(TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp](ISimpleProcContainer`1 self, CLTaskErrHandler err_handler, TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLTask`1.WaitRes() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at AddProc.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddProc.pas:line *
   at AddProc.Program.Main()
---> (Inner Exception #0) System.Exception: CLMemory[*] of size 1, TestOK
   at AddProc.<>local_variables_class_*.<>lambda*(CLMemory <>b) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddProc.pas:line *
   at OpenCLABC_implementation______.SimpleProcContainer`1.Invoke(TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp](ISimpleProcContainer`1 self, CLTaskErrHandler err_handler, TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


