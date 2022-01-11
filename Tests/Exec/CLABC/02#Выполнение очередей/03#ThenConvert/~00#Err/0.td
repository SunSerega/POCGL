


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at 0.Program.<>lambda*(Int32 <>i) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\03#ThenConvert\~00#Err\0.pas:line *
   at OpenCLABC_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLTask`1.WaitRes() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at 0.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\03#ThenConvert\~00#Err\0.pas:line *
   at 0.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at 0.Program.<>lambda*(Int32 <>i) in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\03#ThenConvert\~00#Err\0.pas:line *
   at OpenCLABC_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


