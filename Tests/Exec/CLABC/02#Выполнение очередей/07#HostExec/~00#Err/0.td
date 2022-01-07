


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at 0.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\0.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueBase q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at 0.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\0.pas:line *
   at 0.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at 0.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\0.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


