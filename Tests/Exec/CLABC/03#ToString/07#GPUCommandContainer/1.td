


#ReqModules
OpenCLABC

#ExpOtp
KernelCCQ#0
	CCCObj: Kernel[p1:*] from ProgramCode[*]
	KernelCommandExec2
		sz1: ConstQueue<integer>#1: 1
		sz2: ConstQueue<integer>#2: 1
		args[0]: KernelArgMemorySegmentCQ
			MemorySegmentCCQ#3
				CCCQueue
					CommandQueueHostBackgoundFunc<MemorySegment>#4: function lambda: MemorySegment
				QueueCommand
					CommandQueueHostBackgoundFunc<integer>#5: function lambda: integer
				BackgroundProcCommand: procedure lambda(ms: MemorySegment)
		args[1]: KernelArgValue<integer>: 5

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 


