


#ReqModules
OpenCLABC

#ExpExecErr
System.NotSupportedException: Выполнять маркер-комбинацию нельзя. Возможно вы забыли написать WaitFor?
   at OpenCLABC_implementation______.WaitMarkerCombination`1.RegisterWaitables(CLTaskGlobalData g, HashSet`1 prev_hubs) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC_implementation______.CLTaskResLess..ctor(CommandQueueBase q, Context c) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.BeginInvoke(CommandQueueBase q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.Context.SyncInvoke(CommandQueueBase q) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at invoke WaitAll.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\10#WaitMarker\~00#Err\invoke WaitAll.pas:line *
   at invoke WaitAll.Program.Main()


