


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ExpExecOtp
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#0
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#1
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#2
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#3
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#4
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#5
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#6
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#7
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#8
------------------------------
final = ErrHandlerBranchCombinator#0: CLTaskGlobalData.ParallelInvoke branches union
	origin = ErrHandlerInitial#1: Initial CLTask invoke
	branch#0/2 = ErrHandlerBranchCombinator#2: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#3: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#4: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
		branch#1/2 = ErrHandlerBranchBud#5: branch invoke
		origin = ErrHandlerBranchBud#3: branch invoke
	branch#1/2 = ErrHandlerBranchCombinator#6: CLTaskGlobalData.ParallelInvoke branches union
		origin = ErrHandlerBranchBud#7: branch invoke
		origin = ErrHandlerInitial#1: Initial CLTask invoke
		branch#0/2 = ErrHandlerBranchBud#8: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
		branch#1/2 = ErrHandlerBranchBud#9: branch invoke
		origin = ErrHandlerBranchBud#7: branch invoke
(total 10 handlers)
Err#9
------------------------------
[EventDebug]: 100 event's created
[QueueResNil]: 130

#ReqModules
OpenCLABC


