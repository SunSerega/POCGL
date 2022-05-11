


#DelegateCount
3

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 0c.Program.<>lambda*(Int32 <>i, CLContext <>c) в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0c.pas:строка *
   в OpenCLABC_implementation______.SimpleFuncContainerC`2.Invoke(TInp inp, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp,TRes](ISimpleFuncContainer`2 self, CLTaskErrHandler err_handler, TInp inp, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLTask`1.WaitRes() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.CLContext.SyncInvoke[T](CommandQueue`1 q, ParameterQueueSetter[] parameters) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в 0c.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0c.pas:строка *
   в 0c.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 0c.Program.<>lambda*(Int32 <>i, CLContext <>c) в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#ThenConvert\~00#Err\0c.pas:строка *
   в OpenCLABC_implementation______.SimpleFuncContainerC`2.Invoke(TInp inp, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.OpenCLABC_implementation______.Invoke[TInp,TRes](ISimpleFuncContainer`2 self, CLTaskErrHandler err_handler, TInp inp, CLContext c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *<---

#ReqModules
OpenCLABC


