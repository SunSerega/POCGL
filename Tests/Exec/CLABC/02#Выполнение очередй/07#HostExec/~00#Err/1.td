


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 1.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\07#HostExec\~00#Err\1.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CLTaskResLess.WaitResBase() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTaskBase.WaitRes() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueBase q) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в 1.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\07#HostExec\~00#Err\1.pas:строка *
   в 1.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 1.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\07#HostExec\~00#Err\1.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *<---


