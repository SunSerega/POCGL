


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
					CommandQueueHostFunc<OpenCLABC.MemorySegment>#4: OpenCLABC_implementation______.<>local_variables_class_*`1[OpenCLABC.MemorySegment] => OpenCLABC.MemorySegment <>lambda*(OpenCLABC.Context)
				QueueCommand
					CommandQueueHostFunc<System.Int32>#5: OpenCLABC_implementation______.<>local_variables_class_*`1[System.Int32] => Int32 <>lambda*(OpenCLABC.Context)
				ProcCommand: OpenCLABC_implementation______.<>local_variables_class_* => Void <>lambda*(OpenCLABC.MemorySegment, OpenCLABC.Context)
		args[1]: KernelArgValue<System.Int32> => 5


