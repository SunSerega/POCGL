


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 1.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\1.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueNil q) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в 1.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\1.pas:строка *
   в 1.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 1.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\1.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---


