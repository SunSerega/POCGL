


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.InvalidCastException: Specified cast is not valid.
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*(Object <>o) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в 1.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\02#Cast\~00#Err\1.pas:строка *
   в 1.Program.Main()
---> (Внутреннее исключение #0) System.InvalidCastException: Specified cast is not valid.
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*(Object <>o) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *<---


