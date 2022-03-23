


#ReqModules
OpenCLABC

#ExpExecErr
System.InvalidProgramException: Преобразовывать комбинацию маркеров в очередь нельзя. Возможно вы забыли написать WaitFor?
   в OpenCLABC_implementation______.WaitMarkerCombination`1.ConvertToQBase() в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в OpenCLABC.WaitMarker.op_Implicit(WaitMarker m) в *\POCGL\Tests\LibSource\OpenCLABC.pas:строка *
   в invoke WaitAll.Program.$Main() в *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\10#WaitMarker\~00#Err\invoke WaitAll.pas:строка *
   в invoke WaitAll.Program.Main()

#DelegateCount
3


