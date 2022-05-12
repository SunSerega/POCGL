


#DelegateCount
3

#ExpExecErr
System.InvalidProgramException: Преобразовывать комбинацию маркеров в очередь нельзя. Возможно вы забыли написать WaitFor?
   at OpenCLABC_implementation______.WaitMarkerCombination`1.ConvertToQBase() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.WaitMarker.op_Implicit(WaitMarker m) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at invoke WaitAll.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\10#WaitMarker\~00#Err\invoke WaitAll.pas:line *
   at invoke WaitAll.Program.Main()

#ReqModules
OpenCLABC


