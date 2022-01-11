


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 2 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   at error multiuse.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#Multiusable\~00#Err\error multiuse.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueNil q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at error multiuse.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#Multiusable\~00#Err\error multiuse.pas:line *
   at error multiuse.Program.Main()
---> (Inner Exception #0) System.Exception: TestOK
   at error multiuse.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#Multiusable\~00#Err\error multiuse.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---

---> (Inner Exception #1) System.Exception: TestOK
   at error multiuse.Program.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\04#Multiusable\~00#Err\error multiuse.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecProc(Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`1.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


