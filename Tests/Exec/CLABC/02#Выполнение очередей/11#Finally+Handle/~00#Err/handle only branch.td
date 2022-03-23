


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в handle only branch.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\11#Finally+Handle\~00#Err\handle only branch.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueNil q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в handle only branch.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\11#Finally+Handle\~00#Err\handle only branch.pas:строка *
   в handle only branch.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в handle only branch.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\11#Finally+Handle\~00#Err\handle only branch.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#DelegateCount
3


