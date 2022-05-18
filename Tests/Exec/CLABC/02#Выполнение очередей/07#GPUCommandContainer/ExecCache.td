


#DelegateCount
5

#ExpExecOtp
   at System.Environment.GetStackTrace(Exception e, Boolean needFileInfo)
   at System.Environment.get_StackTrace()
   at OpenCLABC.ExecDebug.ReportExecCache(TextWriter otp) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at ExecCache.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\07#GPUCommandContainer\ExecCache.pas:line *
   at ExecCache.Program.Main()
   at System.RuntimeMethodHandle.InvokeMethod(Object target, Object[] arguments, Signature sig, Boolean constructor)
   at System.Reflection.RuntimeMethodInfo.UnsafeInvokeInternal(Object obj, Object[] parameters, Object[] arguments)
   at System.Reflection.RuntimeMethodInfo.Invoke(Object obj, BindingFlags invokeAttr, Binder binder, Object[] parameters, CultureInfo culture)
   at TestExecutor.Program.$Main()
   at TestExecutor.Program.Main()
Logging caching tries of CLKernelCommandExec1#1:
For CLKernel[k1] from CLProgramCode[*] made cl_kernel[*]
For CLKernel[k1] from CLProgramCode[*] taken cl_kernel[*]
For CLKernel[k1] from CLProgramCode[*] taken cl_kernel[*]
------------------------------
Logging caching tries of CLKernelCommandExec1#2:
For CLKernel[k2] from CLProgramCode[*] made cl_kernel[*]
For CLKernel[k2] from CLProgramCode[*] taken cl_kernel[*]
For CLKernel[k2] from CLProgramCode[*] taken cl_kernel[*]
------------------------------
Logging caching tries of CLKernelCommandExec1#3:
For CLKernel[k3] from CLProgramCode[*] made cl_kernel[*]
For CLKernel[k3] from CLProgramCode[*] taken cl_kernel[*]
------------------------------
========================================
[EventDebug]: 6 event's created 
[QueueDebug]: 6 queue's created 
[ExecDebug]: 3 cache entries created 
[QueueResNil]: 12 
[QueueRes<T>]: 14 
	QueueResValDirect<CLKernel>: 4 
	QueueResValDirect<integer>: 6 
	QueueResValWrap<CLKernel>: 4 

#ReqModules
OpenCLABC


