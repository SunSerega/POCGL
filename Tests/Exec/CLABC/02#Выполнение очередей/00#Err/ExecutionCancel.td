


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK:1
   в ExecutionCancel.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLContext.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в ExecutionCancel.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в ExecutionCancel.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK:1
   в ExecutionCancel.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

---> (Внутреннее исключение #1) System.Exception: TestOK:2
   в ExecutionCancel.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в OpenCLABC_implementation______.SimpleProc0Container.Invoke(CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProcBase`1.InvokeProc(CLTaskErrHandler err_handler, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


