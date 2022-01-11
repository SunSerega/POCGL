


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: Excepted error
   at Handle only local.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\Handle only local.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueNil q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at Handle only local.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\Handle only local.pas:line *
   at Handle only local.Program.Main()
---> (Inner Exception #0) System.Exception: Excepted error
   at Handle only local.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\12#Finally+Handle\~00#Err\Handle only local.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


