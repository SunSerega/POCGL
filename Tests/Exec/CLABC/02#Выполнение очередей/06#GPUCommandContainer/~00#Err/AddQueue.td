


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: MemorySegment[*] of size 1, TestOK
   at AddQueue.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\06#GPUCommandContainer\~00#Err\AddQueue.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLTaskBase.Wait() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLTask`1.WaitRes() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke[T](CommandQueue`1 q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at AddQueue.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\06#GPUCommandContainer\~00#Err\AddQueue.pas:line *
   at AddQueue.Program.Main()
---> (Inner Exception #0) System.Exception: MemorySegment[*] of size 1, TestOK
   at AddQueue.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\06#GPUCommandContainer\~00#Err\AddQueue.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*(Context <>c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *<---


