


#ReqModules
OpenCLABC

#ExpExecErr
System.NotSupportedException: Err:WaitMarkerCombination.Invoke
   в OpenCLABC_implementation______.WaitMarkerCombination`1.RegisterWaitables(CLTaskGlobalData g, HashSet`1 prev_hubs) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.CLTaskResLess..ctor(CommandQueueBase q, Context c) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.BeginInvoke(CommandQueueBase q) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.Context.SyncInvoke(CommandQueueBase q) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в invoke WaitAll.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\10#WaitMarker\~00#Err\invoke WaitAll.pas:строка *
   в invoke WaitAll.Program.Main()


