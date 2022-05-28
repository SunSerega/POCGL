


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>

#ExpExecOtp
CommandQueueTryFinally<integer>#0
	CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer

CommandQueueHandleWithoutRes#0
	CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	function lambda(e: Exception): boolean

CommandQueueHandleDefaultRes<integer>#0: 2
	CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	function lambda(e: Exception): boolean

CommandQueueHandleReplaceRes<integer>#0
	CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer
	function lambda(lst: List<Exception>): integer

#ReqModules
OpenCLABC


