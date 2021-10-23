


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: MemorySegment[*] of size 1, TestOK
   в AddProc.<>local_variables_class_*.<>lambda*(MemorySegment <>b) в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\06#GPUCommandContainer\~00#Err\AddProc.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(MemorySegment <>o, Context <>c) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в AddProc.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\06#GPUCommandContainer\~00#Err\AddProc.pas:строка *
   в AddProc.Program.Main()
---> (Внутреннее исключение #0) System.Exception: MemorySegment[*] of size 1, TestOK
   в AddProc.<>local_variables_class_*.<>lambda*(MemorySegment <>b) в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\06#GPUCommandContainer\~00#Err\AddProc.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(MemorySegment <>o, Context <>c) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *<---


