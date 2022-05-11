


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 1T.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\08#HostExec\~00#Err\1T.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLContext.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в 1T.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\08#HostExec\~00#Err\1T.pas:строка *
   в 1T.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 1T.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\08#HostExec\~00#Err\1T.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


