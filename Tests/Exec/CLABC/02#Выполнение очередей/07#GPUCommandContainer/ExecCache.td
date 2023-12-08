


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
final = ErrHandlerInitial#0: ExecuteEnqFunc container
(total 1 handlers)
final = ErrHandlerMURepeater#0: MU repeater for CommandQueueHostQuickFunc<CLKernel,SimpleFunc0Container<CLKernel>>
	victim = ErrHandlerInitial#1: Initial MU invoke
origin = ErrHandlerBranchCombinator#2: CLKernelCommandExec1 origin+par+enq union
	branch#0/2 = ErrHandlerInitial#3: ExecuteEnqFunc container
	branch#1/2 = ErrHandlerMURepeater#4: MU repeater for CommandQueueHostQuickFunc<CLKernel,SimpleFunc0Container<CLKernel>>
		victim = ErrHandlerInitial#1: Initial MU invoke
	origin = ErrHandlerFlattener#5: MU repeater for CommandQueueHostQuickFunc<CLKernel,SimpleFunc0Container<CLKernel>>
	victim = ErrHandlerInitial#1: Initial MU invoke
(total 6 handlers)
final = ErrHandlerMURepeater#0: MU repeater for CommandQueueHostQuickFunc<CLKernel,SimpleFunc0Container<CLKernel>>
	victim = ErrHandlerInitial#1: Initial MU invoke
origin = ErrHandlerBranchCombinator#2: CLKernelCommandExec1 origin+par+enq union
	branch#0/2 = ErrHandlerInitial#3: ExecuteEnqFunc container
	branch#1/2 = ErrHandlerMURepeater#4: MU repeater for CommandQueueHostQuickFunc<CLKernel,SimpleFunc0Container<CLKernel>>
		victim = ErrHandlerInitial#1: Initial MU invoke
	origin = ErrHandlerFlattener#5: MU repeater for CommandQueueHostQuickFunc<CLKernel,SimpleFunc0Container<CLKernel>>
	victim = ErrHandlerInitial#1: Initial MU invoke
(total 6 handlers)
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
For CLKernel[k1] from CLProgramCode[*] returned cl_kernel[*]
------------------------------
Logging caching tries of CLKernelCommandExec1#2:
For CLKernel[k2] from CLProgramCode[*] made cl_kernel[*]
For CLKernel[k2] from CLProgramCode[*] taken cl_kernel[*]
For CLKernel[k2] from CLProgramCode[*] taken cl_kernel[*]
For CLKernel[k2] from CLProgramCode[*] returned cl_kernel[*]
------------------------------
Logging caching tries of CLKernelCommandExec1#3:
For CLKernel[k3] from CLProgramCode[*] made cl_kernel[*]
For CLKernel[k3] from CLProgramCode[*] taken cl_kernel[*]
------------------------------
========================================
[EventDebug]: 6 event's created
[QueueDebug]: 6 queue's created
[ExecDebug]: 3 cache entries created
[QueueResNil]: 24
[QueueRes<T>]: 10
	QueueResValDirect<CLKernel>: 2
	QueueResValDirect<integer>: 6
	QueueResValWrap<CLKernel>: 2

#ReqModules
OpenCLABC


