


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

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
[QueueResNil]: 18 
[QueueRes<T>]: 10 
	QueueResValDirect<CLKernel>: 2 
	QueueResValDirect<integer>: 6 
	QueueResValWrap<CLKernel>: 2 

#ReqModules
OpenCLABC


