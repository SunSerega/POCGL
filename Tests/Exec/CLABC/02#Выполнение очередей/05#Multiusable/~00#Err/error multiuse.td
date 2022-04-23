


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в error multiuse.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в error multiuse.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в error multiuse.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в error multiuse.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

---> (Внутреннее исключение #1) System.Exception: TestOK
   в error multiuse.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


