


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK:1
   at ExecutionCancel.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueBase q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at ExecutionCancel.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at ExecutionCancel.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK:1
   at ExecutionCancel.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

---> (Inner Exception #1) System.Exception: TestOK:2
   at ExecutionCancel.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\00#Err\ExecutionCancel.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


