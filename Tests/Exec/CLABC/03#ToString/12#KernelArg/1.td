


#ReqModules
OpenCLABC

#DelegateCount
10

#ExpOtp
Const
|	Managed
|	|	Value
|	|	|	KernelArgValue<integer>: 1
|	|	|	KernelArgValue<integer>: 1
|	|	Array
|	|	|	KernelArgArray<real, array of real>: [2]
|	|	|	KernelArgArray<real, array of real>: [2]
|	|	Array3
|	|	|	KernelArgArray<int64, array [,,] of int64>: [[[0,0,0,0],[0,0,0,0],[0,0,0,0]],[[0,0,0,0],[0,0,0,0],[0,0,0,0]]]
|	|	|	KernelArgArray<int64, array of int64>: { nil }
|	|	ArraySegment
|	|	|	KernelArgArraySegment<integer>: [3]
|	|	|	TODO#2650: implicit from segment
|	Native
|	|	Area
|	|	|	KernelArgData: 4[5]
|	|	|	KernelArgValue<NativeMemoryArea>: 4[5]
|	|	Pointer
|	|	|	KernelArgData: 6[8]
|	|	NativeValue
|	|	|	KernelArgNativeValue<byte>: NativeValue<byte>{ 7 }
|	|	|	KernelArgNativeValue<byte>: NativeValue<byte>{ 7 }
|	|	NativeArray
|	|	|	KernelArgNativeArray<integer>: [8,9]
|	|	|	KernelArgNativeArray<integer>: [8,9]
|	OpenCL
|	|	CLMemorySegment
|	|	|	KernelArgCLMemorySegment: CLMemorySegment[*] of size 11
|	|	|	KernelArgCLMemorySegment: CLMemorySegment[*] of size 11
|	|	CLMemorySubSegment
|	|	|	KernelArgCLMemorySegment: CLMemorySubSegment{ CLMemorySubSegment[*] of size 10 inside CLMemorySegment[*] of size 11 }
|	|	|	KernelArgCLMemorySegment: CLMemorySubSegment{ CLMemorySubSegment[*] of size 10 inside CLMemorySegment[*] of size 11 }
|	|	CLValue
|	|	|	KernelArgCLValue<word>: CLValue<word>[*]
|	|	|	KernelArgCLValue<word>: CLValue<word>[*]
|	|	CLArray
|	|	|	KernelArgCLArray<single>: CLArray<single>[*] of length 12
|	|	|	KernelArgCLArray<single>: CLArray<single>[*] of length 12
Queue
|	Managed
|	|	Value
|	|	|	KernelArgValueCQ<integer>
|	|	|		ConstQueue<integer>#0: 1
|	|	|	KernelArgValueCQ<integer>
|	|	|		ConstQueue<integer>#0: 1
|	|	Array
|	|	|	KernelArgArrayCQ<real, array of real>
|	|	|		ConstQueue<array of real>#0: [2]
|	|	|	KernelArgArrayCQ<real, array of real>
|	|	|		ConstQueue<array of real>#0: [2]
|	|	Array3
|	|	|	KernelArgArrayCQ<int64, array [,,] of int64>
|	|	|		ConstQueue<array [,,] of int64>#0: [[[0,0,0,0],[0,0,0,0],[0,0,0,0]],[[0,0,0,0],[0,0,0,0],[0,0,0,0]]]
|	|	|	KernelArgArrayCQ<int64, array of int64>
|	|	|		ConstQueue<array [,,] of int64>#0: [[[0,0,0,0],[0,0,0,0],[0,0,0,0]],[[0,0,0,0],[0,0,0,0],[0,0,0,0]]]
|	|	ArraySegment
|	|	|	KernelArgArraySegmentCQ<integer>
|	|	|		ConstQueue<ArraySegment<integer>>#0: [3]
|	|	|	TODO#2650: implicit from segment
|	Native
|	|	Area
|	|	|	KernelArgDataCQ
|	|	|		ConstQueue<NativeMemoryArea>#0: 4[5]
|	|	|	KernelArgValueCQ<NativeMemoryArea>
|	|	|		ConstQueue<NativeMemoryArea>#0: 4[5]
|	|	NativeValue
|	|	|	KernelArgNativeValueCQ<byte>
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 7 }
|	|	|	KernelArgNativeValueCQ<byte>
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 7 }
|	|	NativeArray
|	|	|	KernelArgNativeArrayCQ<integer>
|	|	|		ConstQueue<NativeArray<integer>>#0: [8,9]
|	|	|	KernelArgNativeArrayCQ<integer>
|	|	|		ConstQueue<NativeArray<integer>>#0: [8,9]
|	OpenCL
|	|	CLMemorySegment
|	|	|	KernelArgCLMemorySegmentCQ
|	|	|		ConstQueue<CLMemorySegment>#0: CLMemorySegment[*] of size 11
|	|	|	KernelArgCLMemorySegmentCQ
|	|	|		ConstQueue<CLMemorySegment>#0: CLMemorySegment[*] of size 11
|	|	CLMemorySubSegment
|	|	|	KernelArgCLMemorySegmentCQ
|	|	|		ConstQueue<CLMemorySegment>#0: CLMemorySubSegment{ CLMemorySubSegment[*] of size 10 inside CLMemorySegment[*] of size 11 }
|	|	|	KernelArgCLMemorySegmentCQ
|	|	|		ConstQueue<CLMemorySegment>#0: CLMemorySubSegment{ CLMemorySubSegment[*] of size 10 inside CLMemorySegment[*] of size 11 }
|	|	CLValue
|	|	|	KernelArgCLValueCQ<word>
|	|	|		ConstQueue<CLValue<word>>#0: CLValue<word>[*]
|	|	|	KernelArgCLValueCQ<word>
|	|	|		ConstQueue<CLValue<word>>#0: CLValue<word>[*]
|	|	CLArray
|	|	|	KernelArgCLArrayCQ<single>
|	|	|		ConstQueue<CLArray<single>>#0: CLArray<single>[*] of length 12
|	|	|	KernelArgCLArrayCQ<single>
|	|	|		ConstQueue<CLArray<single>>#0: CLArray<single>[*] of length 12
[EventDebug]: 0 event's created 
[QueueDebug]: 0 queue's created 
[WaitDebug]: 0 wait handler's created 


