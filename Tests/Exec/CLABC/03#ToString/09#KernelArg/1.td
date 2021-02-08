


#ReqModules
OpenCLABC

#ExpOtp
>>> Const

Buffer:
KernelArgBuffer => Buffer[0] of size 1
KernelArgBuffer => Buffer[0] of size 1

Record:
KernelArgRecord<System.Int32> => 1
KernelArgRecord<System.Int32> => 1

Ptr:
KernelArgPtr => 1[2]
KernelArgPtr => 3[4]



>>> Invokable

Buffer:
KernelArgBufferCQ
	BufferCommandQueue#0
		CCCObj => Buffer[0] of size 1
KernelArgBufferCQ
	BufferCommandQueue#0
		CCCObj => Buffer[0] of size 1

Record:
KernelArgRecordCQ<System.Int32>
	CommandQueueHostFunc<System.Int32>#0 => System.Func`2[OpenCLABC.Context,System.Int32]
KernelArgRecordCQ<System.Int32>
	CommandQueueHostFunc<System.Int32>#0 => System.Func`2[OpenCLABC.Context,System.Int32]

Ptr:
KernelArgPtrCQ
	CommandQueueHostFunc<System.IntPtr>#0 => System.Func`2[OpenCLABC.Context,System.IntPtr]
	ConstQueue<System.UIntPtr>#1 { 0 }


