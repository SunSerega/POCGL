


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
WaitMarkerAll#0
	WaitMarkerDummy#1
	WaitMarkerDummy#2
 
------------------------------
 
WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2
	WaitMarkerAll#3
		WaitMarkerDummy#4
 
------------------------------
 
WaitMarkerAll#0
	WaitMarkerDummy#1 * 2
 
------------------------------
 
WaitMarkerDummy#0
 
------------------------------
 
WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2 * 2
	WaitMarkerAll#3
		WaitMarkerDummy#2
		WaitMarkerDummy#4
	WaitMarkerAll#5
		WaitMarkerDummy#4 * 2
 
------------------------------
 
==============================
 
CommandQueueWaitFor#0
	WaitMarkerDummy#1
 
------------------------------
 
SimpleSyncQueueArrayNil#0
	WaitMarkerDummyExecutor#1
		WaitMarkerDummy#2
	CommandQueueWaitFor#3
		WaitMarkerDummy#2
 
------------------------------
 
SimpleSyncQueueArrayNil#0
	CommandQueueWaitFor#1
		WaitMarkerDummy#2
	WaitMarkerDummyExecutor#3
		WaitMarkerDummy#2
 
------------------------------
 
==============================
 
CLMemoryCCQ#0
	CCCObj<CLMemory>: CLMemory[*] of size 1
	WaitCommand<CLMemory>
		WaitMarkerDummy#1
 
------------------------------
 
SimpleSyncQueueArray<CLMemory>#0
	WaitMarkerDummyExecutor#1
		WaitMarkerDummy#2
	CLMemoryCCQ#3
		CCCObj<CLMemory>: CLMemory[*] of size 1
		WaitCommand<CLMemory>
			WaitMarkerDummy#2
 
------------------------------
 
SimpleSyncQueueArrayNil#0
	CLMemoryCCQ#1
		CCCObj<CLMemory>: CLMemory[*] of size 1
		WaitCommand<CLMemory>
			WaitMarkerDummy#2
	WaitMarkerDummyExecutor#3
		WaitMarkerDummy#2
 
------------------------------
 

#ReqModules
OpenCLABC


