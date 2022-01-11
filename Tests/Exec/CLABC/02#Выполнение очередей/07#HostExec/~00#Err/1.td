


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at 1.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\1.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueNil q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at 1.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\1.pas:line *
   at 1.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at 1.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#HostExec\~00#Err\1.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


