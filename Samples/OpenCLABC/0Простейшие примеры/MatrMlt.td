


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
Матрица A: 
   0.73   0.82   0.77   0.56
   0.21   0.56   0.91   0.44
   0.98   0.27   0.29   0.47
   0.63   0.47   0.98   0.03

Матрица B: 
   0.86   1.00   0.68   0.31
   0.82   0.85   0.99   0.03
   0.70   0.53   0.93   0.69
   0.55   0.08   0.19   0.45

Вектор V1: 
2.97 9.89 6.43 7.63

Матрица С = A*B: 
   2.15   1.52   1.53   1.63
   1.88   1.20   1.40   1.55
   2.13   1.63   1.29   1.81
   1.03   0.91   0.72   0.90

Вектор V2 = C*V1: 
43.642978 38.329481 44.548663 23.561954

final = ErrHandlerBranchCombinator#0: CLArrayCommandGetArrayAutoSize<real> origin+par+enq union
	branch#0/2 = ErrHandlerInitial#1: ExecuteEnqFunc container
	branch#1/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerInitial#3: ExecuteEnqFunc container
		branch#0/2 = ErrHandlerBranchCombinator#4: CLKernelCommandExec1 origin+par+enq union
			branch#0/2 = ErrHandlerInitial#5: ExecuteEnqFunc container
			branch#1/2 = ErrHandlerBranchCombinator#6: CLArrayCommandWriteArrayAutoSize<real> origin+par+enq union
				branch#0/2 = ErrHandlerInitial#7: ExecuteEnqFunc container
				branch#1/2 = ErrHandlerBranchBud#8: branch invoke
				origin = ErrHandlerInitial#3: ExecuteEnqFunc container
		branch#1/2 = ErrHandlerBranchCombinator#9: CLArrayCommandGetArray2<real> origin+par+enq union
			branch#0/2 = ErrHandlerInitial#10: ExecuteEnqFunc container
			branch#1/2 = ErrHandlerBranchBud#11: branch invoke
			origin = ErrHandlerInitial#3: ExecuteEnqFunc container
(total 12 handlers)
[EventDebug]: 10 event's created
[QueueDebug]: 2 queue's created
[ExecDebug]: 2 cache entries created
[QueueResNil]: 23
[QueueRes<T>]: 12
	QueueResValDirect<array [,] of real>: 3
	QueueResValDirect<array of real>: 2
	QueueResValDirect<CLArray<real>>: 2
	QueueResValDirect<integer>: 5

#ReqModules
OpenCLABC

#TestMode
Comp+Exec


