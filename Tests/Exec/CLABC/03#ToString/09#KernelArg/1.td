


#ReqModules
OpenCLABC

#ExpOtp
>>> Const

CLArray:
KernelArgCLArray<System.Byte> => CLArray<Byte>[*] of size 1
KernelArgCLArray<System.Byte> => CLArray<Byte>[*] of size 1

MemorySegment:
KernelArgMemorySegment => MemorySegment[*] of size 1
KernelArgMemorySegment => MemorySegment[*] of size 1

Data:
KernelArgData => 1[2]
KernelArgData => 3[4]

Value:
KernelArgValue<System.Int32> => 1
KernelArgValue<System.Int32> => 1

Array:
KernelArgArray<System.Double> => [0]+8b
KernelArgArray<System.Double> => [0]



>>> Invokable

CLArray:
KernelArgCLArrayCQ<System.Byte>
	CLArrayCCQ<System.Byte>#0
		CCCObj => CLArray<Byte>[*] of size 1
TODO: implicit CLArray

MemorySegment:
KernelArgMemorySegmentCQ
	MemorySegmentCCQ#0
		CCCObj => MemorySegment[*] of size 1
KernelArgMemorySegmentCQ
	MemorySegmentCCQ#0
		CCCObj => MemorySegment[*] of size 1

Data:
KernelArgDataCQ
	CommandQueueHostBackgoundFunc<System.IntPtr>#0: IntPtr <>lambda*()
	ConstQueue<System.UIntPtr>#1 { 0 }

Value:
KernelArgValueCQ<System.Int32>
	CommandQueueHostBackgoundFunc<System.Int32>#0: Int32 <>lambda*()
KernelArgValueCQ<System.Int32>
	CommandQueueHostBackgoundFunc<System.Int32>#0: Int32 <>lambda*()

Array:
KernelArgArrayCQ<System.Double>
	CommandQueueHostBackgoundFunc<System.Double[]>#0: 1.<>local_variables_class_* => Double[] <>lambda*()
	ConstQueue<System.Int32>#1 { 1 }
KernelArgArrayCQ<System.Double>
	CommandQueueHostBackgoundFunc<System.Double[]>#0: 1.<>local_variables_class_* => Double[] <>lambda*()
	ConstQueue<System.Int32>#1 { 0 }


