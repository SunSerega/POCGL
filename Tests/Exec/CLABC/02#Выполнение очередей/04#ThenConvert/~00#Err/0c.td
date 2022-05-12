


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at 0c.Program.<>lambda*(Int32 <>i, CLContext <>c) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0c.pas:line *
   at OpenCLABC_implementation______.SimpleFuncContainerC`2.Invoke(TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp,TRes](ISimpleFuncContainer`2 self, CLTaskErrHandler err_handler, TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLTask`1.WaitRes() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at 0c.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0c.pas:line *
   at 0c.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at 0c.Program.<>lambda*(Int32 <>i, CLContext <>c) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0c.pas:line *
   at OpenCLABC_implementation______.SimpleFuncContainerC`2.Invoke(TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp,TRes](ISimpleFuncContainer`2 self, CLTaskErrHandler err_handler, TInp inp, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


