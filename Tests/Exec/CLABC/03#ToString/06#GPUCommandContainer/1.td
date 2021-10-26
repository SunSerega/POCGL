


#ReqModules
OpenCLABC

#ExpOtp
KernelCCQ#0
	CCCObj => Kernel[p1:*] from ProgramCode[*]
	KernelCommandExec2
		sz1: ConstQueue<System.Int32>#1 { 1 }
		sz2: ConstQueue<System.Int32>#2 { 1 }
		args[0]: KernelArgMemorySegmentCQ
			MemorySegmentCCQ#3
				CCCQueue
					CommandQueueHostFunc<OpenCLABC.MemorySegment>#4 => System.Func`2[OpenCLABC.Context,OpenCLABC.MemorySegment]
				QueueCommand
					CommandQueueHostFunc<System.Int32>#5 => System.Func`2[OpenCLABC.Context,System.Int32]
				ProcCommand => System.Action`2[OpenCLABC.MemorySegment,OpenCLABC.Context]
		args[1]: KernelArgValue<System.Int32> => 5


