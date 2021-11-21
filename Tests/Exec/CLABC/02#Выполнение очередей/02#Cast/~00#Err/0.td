


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.InvalidCastException: Заданное приведение является недопустимым.
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*(Object <>o) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в 0.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\02#Cast\~00#Err\0.pas:строка *
   в 0.Program.Main()
---> (Внутреннее исключение #0) System.InvalidCastException: Заданное приведение является недопустимым.
   в OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*(Object <>o) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---


