


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: CLMemorySegment[*] of size 1, TestOK
   в AddQueue.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddQueue.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в AddQueue.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddQueue.pas:строка *
   в AddQueue.Program.Main()
---> (Внутреннее исключение #0) System.Exception: CLMemorySegment[*] of size 1, TestOK
   в AddQueue.<>local_variables_class_*.<>lambda*() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\~00#Err\AddQueue.pas:строка *
   в OpenCLABC_implementation______.CommandQueueHostBackgoundProc.ExecProc(Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#DelegateCount
3


