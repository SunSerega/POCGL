


#ReqModules
OpenCLABC

#ExpExecErr
System.ArgumentException: Wait очереди должны ожидать хотя бы одну очередь
   в OpenCLABC_implementation______.WCQWaiter..ctor(WaitMarkerBase[] markers) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(WaitMarkerBase[] markers)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 markers) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.OpenCLABC.WaitForAll(WaitMarkerBase[] markers) в *\pocgl\tests\LibSource\OpenCLABC.pas:строка *
   в 1.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередй\05#Wait\~00#Err\1.pas:строка *
   в 1.Program.Main()


