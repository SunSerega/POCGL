


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: Excepted error
   в Handle only local.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\Handle only local.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueBase q) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в Handle only local.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\Handle only local.pas:строка *
   в Handle only local.Program.Main()
---> (Внутреннее исключение #0) System.Exception: Excepted error
   в Handle only local.Program.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\Handle only local.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---


