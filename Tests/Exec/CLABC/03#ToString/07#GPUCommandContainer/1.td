


#DelegateCount
5

#ExpOtp
KernelCCQ#0
	CCCObj<Kernel>: Kernel[p1] from ProgramCode[*]
	KernelCommandExec2
		sz1: ConstQueue<integer>#1: 1
		sz2: ConstQueue<integer>#2: 1
		args:
			KernelArgGlobalCLMemory
				CLMemoryCCQ#3
					CCCQueue<CLMemory>
						CommandQueueHostBackgoundFunc<CLMemory>#4: function lambda: CLMemory
					QueueCommand<CLMemory>
						CommandQueueHostBackgoundFunc<integer>#5: function lambda: integer
					BackgroundProcCommand<CLMemory>: procedure lambda(ms: CLMemory)
			KernelArgPrivateValue<integer>
				ConstQueue<integer>#6: 5

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 

#ReqModules
OpenCLABC


