


#ReqModules
OpenCLABC

#ExpOtp
KernelCommandQueue#0
	CCCObj => Kernel[p1:2] from ProgramCode[1]
	KernelCommandExec2
		sz1: ConstQueue<System.Int32>#1 { 1 }
		sz2: ConstQueue<System.Int32>#2 { 1 }
		args[0]: KernelArgBufferCQ
			BufferCommandQueue#3
				CCCQueue
					CommandQueueThenConvert<OpenCLABC.Buffer, OpenCLABC.Buffer>#4 => System.Func`3[OpenCLABC.Buffer,OpenCLABC.Context,OpenCLABC.Buffer]
						CommandQueueHostFunc<OpenCLABC.Buffer>#5 => System.Func`2[OpenCLABC.Context,OpenCLABC.Buffer]
				QueueCommand
					ConstQueue<System.Object>#6 { nil }
				QueueCommand
					CommandQueueHostFunc<System.Int32>#7 => System.Func`2[OpenCLABC.Context,System.Int32]
				ProcCommand => System.Action`2[OpenCLABC.Buffer,OpenCLABC.Context]
		args[1]: KernelArgRecord<System.Int32> => 5


