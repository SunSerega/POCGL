


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at handle only branch.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\handle only branch.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueNil q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at handle only branch.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\handle only branch.pas:line *
   at handle only branch.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at handle only branch.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\handle only branch.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


