


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK:1
   в ExecutionCancel.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CLTaskResLess.WaitResBase() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTaskBase.WaitRes() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueBase q) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в ExecutionCancel.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в ExecutionCancel.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK:1
   в ExecutionCancel.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

---> (Внутреннее исключение #1) System.Exception: TestOK:2
   в ExecutionCancel.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---


