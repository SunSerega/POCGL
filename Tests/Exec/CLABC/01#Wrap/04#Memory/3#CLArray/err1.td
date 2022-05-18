


#DelegateCount
4

#ExpExecErr
System.TypeInitializationException: The type initializer for 'OpenCLABC.CLArray`1' threw an exception. ---> OpenCLABC_implementation______.BlittableException: Значения типа boolean нельзя использовать как элементы CLArray<>
   at OpenCLABC_implementation______.BlittableHelper.RaiseIfBad(Type t, String source_name) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.CLArray`1..cctor() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   --- End of inner exception stack trace ---
   at OpenCLABC.CLArray`1..ctor(Int32 len, CLMemoryUsage kernel_use, CLMemoryUsage map_use)
   at err1.Program.$Main() in *\POCGL\Tests\Exec\CLABC\01#Wrap\04#Memory\3#CLArray\err1.pas:line *
   at err1.Program.Main()

#ReqModules
OpenCLABC


