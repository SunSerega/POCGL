


#DelegateCount
5

#ExpExecOtp
CLKernelCCQ#0
	CCCObj<CLKernel>: CLKernel[k] from CLProgramCode[*]
	CLKernelCommandExec2
		sz1: ConstQueue<integer>#1: 1
		sz2: ConstQueue<integer>#2: 1
		args:
			CLKernelArgGlobalCLMemory
				CLMemoryCCQ#3
					CCCQueue<CLMemory>
						CommandQueueHostThreadedFunc<CLMemory,SimpleFunc0Container<CLMemory>>#4: function lambda: CLMemory
					QueueCommand<CLMemory>
						CommandQueueHostThreadedFunc<integer,SimpleFunc0Container<integer>>#5: function lambda: integer
					QuickProcCommand<CLMemory,SimpleProcContainer<CLMemory>,TBooleanTrueFlag>: procedure lambda(m: CLMemory)
					QuickProcCommand<CLMemory,SimpleProcContainer<CLMemory>,TBooleanFalseFlag>: procedure lambda(m: CLMemory)
					ThreadedProcCommand<CLMemory,SimpleProcContainer<CLMemory>>: procedure lambda(m: CLMemory)
			CLKernelArgPrivateValue<integer>
				ConstQueue<integer>#6: 5

#ReqModules
OpenCLABC


