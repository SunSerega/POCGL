


#ReqModules
OpenCLABC

#ExpOtp
>>> Const

CLArray:
KernelArgCLArray<byte>: CLArray<Byte>[*] of size 1
KernelArgCLArray<byte>: CLArray<Byte>[*] of size 1

MemorySegment:
KernelArgMemorySegment: MemorySegment[*] of size 1
KernelArgMemorySegment: MemorySegment[*] of size 1

Data:
KernelArgData => 1[2]
KernelArgData => 3[4]

Value:
KernelArgValue<integer>: 1
KernelArgValue<integer>: 1

Array:
KernelArgArray<real>: [5]+8b
KernelArgArray<real>: [5]



>>> Invokable

CLArray:
KernelArgCLArrayCQ<byte>
	CLArrayCCQ<byte>#0
		CCCObj: CLArray<Byte>[*] of size 1
TODO: implicit CLArray

MemorySegment:
KernelArgMemorySegmentCQ
	MemorySegmentCCQ#0
		CCCObj: MemorySegment[*] of size 1
KernelArgMemorySegmentCQ
	MemorySegmentCCQ#0
		CCCObj: MemorySegment[*] of size 1

Data:
KernelArgDataCQ
	CommandQueueHostBackgoundFunc<>#0: function lambda: 
	ConstQueue<>#1: 0

Value:
KernelArgValueCQ<integer>
	CommandQueueHostBackgoundFunc<integer>#0: function lambda: integer
KernelArgValueCQ<integer>
	CommandQueueHostBackgoundFunc<integer>#0: function lambda: integer

Array:
KernelArgArrayCQ<real>
	CommandQueueHostBackgoundFunc<array of real>#0: ([5]) => function lambda: array of real
	ConstQueue<integer>#1: 1
KernelArgArrayCQ<real>
	CommandQueueHostBackgoundFunc<array of real>#0: ([5]) => function lambda: array of real
	ConstQueue<integer>#1: 0

[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 


