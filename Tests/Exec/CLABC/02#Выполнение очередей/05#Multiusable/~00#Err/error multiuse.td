


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at error multiuse.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLContext.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at error multiuse.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:line *
   at error multiuse.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at error multiuse.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

---> (Inner Exception #1) System.Exception: TestOK
   at error multiuse.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:line *
   at OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

#ReqModules
OpenCLABC


