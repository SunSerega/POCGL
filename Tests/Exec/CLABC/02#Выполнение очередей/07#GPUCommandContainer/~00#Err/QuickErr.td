


#DelegateCount
4

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в QuickErr.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\QuickErr.pas:строка *
   в OpenCLABC_implementation______.SimpleFunc0Container`1.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostFuncBase`2.InvokeFunc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в QuickErr.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\QuickErr.pas:строка *
   в QuickErr.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в QuickErr.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\QuickErr.pas:строка *
   в OpenCLABC_implementation______.SimpleFunc0Container`1.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostFuncBase`2.InvokeFunc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


