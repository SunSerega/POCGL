


#DelegateCount
5

#ExpOtp
KernelCCQ#0
	CCCObj<Kernel>: Kernel[p1] from ProgramCode[*]
	KernelCommandExec2
		sz1: ConstQueue<integer>#1: 1
		sz2: ConstQueue<integer>#2: 1
		args:
			KernelArgGlobalCLMemorySegment
				CLMemorySegmentCCQ#3
					CCCQueue<CLMemorySegment>
						CommandQueueHostBackgoundFunc<CLMemorySegment>#4: function lambda: CLMemorySegment
					QueueCommand<CLMemorySegment>
						CommandQueueHostBackgoundFunc<integer>#5: function lambda: integer
					BackgroundProcCommand<CLMemorySegment>: procedure lambda(ms: CLMemorySegment)
			KernelArgPrivateValue<integer>
				ConstQueue<integer>#6: 5

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 

#ReqModules
OpenCLABC


