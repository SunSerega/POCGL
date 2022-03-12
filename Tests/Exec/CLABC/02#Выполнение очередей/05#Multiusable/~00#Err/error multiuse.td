


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в error multiuse.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в error multiuse.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в error multiuse.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в error multiuse.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

---> (Внутреннее исключение #1) System.Exception: TestOK
   в error multiuse.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\05#Multiusable\~00#Err\error multiuse.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---


