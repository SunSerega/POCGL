


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в handle only branch.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\11#Finally+Handle\~00#Err\handle only branch.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в handle only branch.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\11#Finally+Handle\~00#Err\handle only branch.pas:строка *
   в handle only branch.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в handle only branch.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\11#Finally+Handle\~00#Err\handle only branch.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


