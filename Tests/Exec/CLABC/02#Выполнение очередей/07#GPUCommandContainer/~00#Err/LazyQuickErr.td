


#DelegateCount
4

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в LazyQuickErr.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\LazyQuickErr.pas:строка *
   в OpenCLABC_implementation______.SimpleFunc0Container`1.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostFuncBase`2.InvokeFunc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в LazyQuickErr.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\LazyQuickErr.pas:строка *
   в LazyQuickErr.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в LazyQuickErr.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\LazyQuickErr.pas:строка *
   в OpenCLABC_implementation______.SimpleFunc0Container`1.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostFuncBase`2.InvokeFunc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


