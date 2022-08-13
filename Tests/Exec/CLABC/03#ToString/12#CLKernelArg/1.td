


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecOtp
Global 
|	CL 
|	|	CLMemory 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ParameterQueue<CLMemory>#0["cl_mem"]: Default=CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		CLMemoryCCQ#0 
|	|	|			ConstQueue<CLMemory>#1: CLMemory[*] of size 1 
|	|	CLValue 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ParameterQueue<CLValue<byte>>#0["cl_val"]: Default=CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		CLValueCCQ<byte>#0 
|	|	|			ConstQueue<CLValue<byte>>#1: CLValue<byte>[*] 
|	|	CLArray 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ParameterQueue<CLArray<byte>>#0["cl_arr"]: Default=CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		CLArrayCCQ<byte>#0 
|	|	|			ConstQueue<CLArray<byte>>#1: CLArray<byte>[*] of length 4 
Constant 
|	CL 
|	|	CLMemory 
|	|	|	CLKernelArgConstantCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgConstantCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgConstantCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgConstantCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgConstantCLMemory 
|	|	|		ParameterQueue<CLMemory>#0["cl_mem"]: Default=CLMemory[*] of size 1 
|	|	|	CLKernelArgConstantCLMemory 
|	|	|		CLMemoryCCQ#0 
|	|	|			ConstQueue<CLMemory>#1: CLMemory[*] of size 1 
|	|	CLValue 
|	|	|	CLKernelArgConstantCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgConstantCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgConstantCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgConstantCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgConstantCLValue<byte> 
|	|	|		ParameterQueue<CLValue<byte>>#0["cl_val"]: Default=CLValue<byte>[*] 
|	|	|	CLKernelArgConstantCLValue<byte> 
|	|	|		CLValueCCQ<byte>#0 
|	|	|			ConstQueue<CLValue<byte>>#1: CLValue<byte>[*] 
|	|	CLArray 
|	|	|	CLKernelArgConstantCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgConstantCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgConstantCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgConstantCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgConstantCLArray<byte> 
|	|	|		ParameterQueue<CLArray<byte>>#0["cl_arr"]: Default=CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgConstantCLArray<byte> 
|	|	|		CLArrayCCQ<byte>#0 
|	|	|			ConstQueue<CLArray<byte>>#1: CLArray<byte>[*] of length 4 
Local 
|	FromBytes 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 123 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueHostQuickFunc<System.UIntPtr,SimpleFunc0Container<System.UIntPtr>>#0: function lambda: System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 123 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<longword,System.UIntPtr,SimpleFuncContainer<longword,System.UIntPtr>>#0 
|	|			CommandQueueHostQuickFunc<longword,SimpleFunc0Container<longword>>#1: function lambda: longword 
|	|			function lambda(bytes: longword): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 123 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<integer,System.UIntPtr,SimpleFuncContainer<integer,System.UIntPtr>>#0 
|	|			CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer 
|	|			function lambda(bytes: integer): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 123 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<uint64,System.UIntPtr,SimpleFuncContainer<uint64,System.UIntPtr>>#0 
|	|			CommandQueueHostQuickFunc<uint64,SimpleFunc0Container<uint64>>#1: function lambda: uint64 
|	|			function lambda(bytes: uint64): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 123 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<int64,System.UIntPtr,SimpleFuncContainer<int64,System.UIntPtr>>#0 
|	|			CommandQueueHostQuickFunc<int64,SimpleFunc0Container<int64>>#1: function lambda: int64 
|	|			function lambda(bytes: int64): System.UIntPtr 
|	FromItemCount 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 256 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<longword,System.UIntPtr,SimpleFuncContainer<longword,System.UIntPtr>>#0 
|	|			CommandQueueHostQuickFunc<longword,SimpleFunc0Container<longword>>#1: function lambda: longword 
|	|			function lambda(item_count: longword): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 256 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<integer,System.UIntPtr,SimpleFuncContainer<integer,System.UIntPtr>>#0 
|	|			CommandQueueHostQuickFunc<integer,SimpleFunc0Container<integer>>#1: function lambda: integer 
|	|			function lambda(item_count: integer): System.UIntPtr 
|	LikeArray 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 4 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<integer,System.UIntPtr,SimpleFuncContainer<integer,System.UIntPtr>>#0 
|	|			CommandQueueThenQuickConvert<array of byte,integer,SimpleFuncContainer<array of byte,integer>>#1 
|	|				CommandQueueHostQuickFunc<array of byte,SimpleFunc0Container<array of byte>>#2: function lambda: array of byte 
|	|				function lambda(a: array of byte): integer 
|	|			function lambda(item_count: integer): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 6 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<integer,System.UIntPtr,SimpleFuncContainer<integer,System.UIntPtr>>#0 
|	|			CommandQueueThenQuickConvert<array [,] of byte,integer,SimpleFuncContainer<array [,] of byte,integer>>#1 
|	|				CommandQueueHostQuickFunc<array [,] of byte,SimpleFunc0Container<array [,] of byte>>#2: function lambda: array [,] of byte 
|	|				function lambda(a: array [,] of byte): integer 
|	|			function lambda(item_count: integer): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 24 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<integer,System.UIntPtr,SimpleFuncContainer<integer,System.UIntPtr>>#0 
|	|			CommandQueueThenQuickConvert<array [,,] of byte,integer,SimpleFuncContainer<array [,,] of byte,integer>>#1 
|	|				CommandQueueHostQuickFunc<array [,,] of byte,SimpleFunc0Container<array [,,] of byte>>#2: function lambda: array [,,] of byte 
|	|				function lambda(a: array [,,] of byte): integer 
|	|			function lambda(item_count: integer): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 5 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<longword,System.UIntPtr,SimpleFuncContainer<longword,System.UIntPtr>>#0 
|	|			CommandQueueThenQuickConvert<NativeArrayArea<byte>,longword,SimpleFuncContainer<NativeArrayArea<byte>,longword>>#1 
|	|				CommandQueueHostQuickFunc<NativeArrayArea<byte>,SimpleFunc0Container<NativeArrayArea<byte>>>#2: function lambda: NativeArrayArea<byte> 
|	|				function lambda(a: NativeArrayArea<byte>): longword 
|	|			function lambda(item_count: longword): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 4 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<longword,System.UIntPtr,SimpleFuncContainer<longword,System.UIntPtr>>#0 
|	|			CommandQueueThenQuickConvert<NativeArray<byte>,longword,SimpleFuncContainer<NativeArray<byte>,longword>>#1 
|	|				CommandQueueHostQuickFunc<NativeArray<byte>,SimpleFunc0Container<NativeArray<byte>>>#2: function lambda: NativeArray<byte> 
|	|				function lambda(a: NativeArray<byte>): longword 
|	|			function lambda(item_count: longword): System.UIntPtr 
|	|	CLKernelArgLocalBytes 
|	|		ConstQueue<System.UIntPtr>#0: 4 
|	|	CLKernelArgLocalBytes 
|	|		CommandQueueThenQuickConvert<integer,System.UIntPtr,SimpleFuncContainer<integer,System.UIntPtr>>#0 
|	|			CommandQueueThenQuickConvert<CLArray<byte>,integer,SimpleFuncContainer<CLArray<byte>,integer>>#1 
|	|				CommandQueueHostQuickFunc<CLArray<byte>,SimpleFunc0Container<CLArray<byte>>>#2: function lambda: CLArray<byte> 
|	|				function lambda(a: CLArray<byte>): integer 
|	|			function lambda(item_count: integer): System.UIntPtr 
Private 
|	Managed 
|	|	Array 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ParameterQueue<array of byte>#0["a"]: Default=[1,2,3,4] 
|	|	Array2 
|	|	|	CLKernelArgPrivateArray2<byte> 
|	|	|		ConstQueue<array [,] of byte>#0: [[1,2,3],[4,5,6]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: array [,] of byte{ [[1,2,3],[4,5,6]] } 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,] of byte>#0: [[1,2,3],[4,5,6]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,] of byte>#0: [[1,2,3],[4,5,6]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ParameterQueue<array [,] of byte>#0["a2"]: Default=[[1,2,3],[4,5,6]] 
|	|	Array3 
|	|	|	CLKernelArgPrivateArray3<byte> 
|	|	|		ConstQueue<array [,,] of byte>#0: [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: array [,,] of byte{ [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] } 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,,] of byte>#0: [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,,] of byte>#0: [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ParameterQueue<array [,,] of byte>#0["a3"]: Default=[[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	ArraySegment 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ParameterQueue<ArraySegment<byte>>#0["seg"]: Default=[2,3] 
|	NativeArea 
|	|	NativeMemoryArea 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ParameterQueue<NativeMemoryArea>#0["ntv_mem_area"]: Default=NativeMemoryArea:$1[2] 
|	|	NativeValueArea 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ParameterQueue<NativeValueArea<byte>>#0["ntv_val_area"]: Default=NativeValueArea<byte>:$3 
|	|	NativeArrayArea 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ParameterQueue<NativeArrayArea<byte>>#0["ntv_arr_area"]: Default=NativeArrayArea<byte>:$4[5] 
|	Native 
|	|	NativeMemory 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ParameterQueue<NativeMemory>#0["ntv_mem"]: Default=NativeMemory:$*[2] 
|	|	NativeValue 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ParameterQueue<NativeValue<byte>>#0["ntv_val"]: Default=NativeValue<byte>{ 123 } 
|	|	NativeArray 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ParameterQueue<NativeArray<byte>>#0["ntv_arr"]: Default=[1,2,3,4] 
|	Value 
|	|	CLKernelArgPrivateValue<integer> 
|	|		ConstQueue<integer>#0: 1 
|	|	CLKernelArgPrivateValue<integer> 
|	|		ConstQueue<integer>#0: 1 
|	|	CLKernelArgPrivateValue<integer> 
|	|		ConstQueue<integer>#0: 1 
|	|	CLKernelArgPrivateValue<byte> 
|	|		ConstQueue<byte>#0: 1 
|	|	CLKernelArgPrivateValue<byte> 
|	|		ParameterQueue<byte>#0["val"]: Default=1 
Generic 
|	Managed 
|	|	Array 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ParameterQueue<array of byte>#0["a"]: Default=[1,2,3,4] 
|	|	Array2 
|	|	|	CLKernelArgPrivateArray2<byte> 
|	|	|		ConstQueue<array [,] of byte>#0: [[1,2,3],[4,5,6]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: array [,] of byte{ [[1,2,3],[4,5,6]] } 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,] of byte>#0: [[1,2,3],[4,5,6]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,] of byte>#0: [[1,2,3],[4,5,6]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ParameterQueue<array [,] of byte>#0["a2"]: Default=[[1,2,3],[4,5,6]] 
|	|	Array3 
|	|	|	CLKernelArgPrivateArray3<byte> 
|	|	|		ConstQueue<array [,,] of byte>#0: [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array of byte>#0: array [,,] of byte{ [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] } 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,,] of byte>#0: [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ConstQueue<array [,,] of byte>#0: [[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	|	CLKernelArgPrivateArray<byte> 
|	|	|		ParameterQueue<array [,,] of byte>#0["a3"]: Default=[[[1,2,3,4],[5,6,7,8],[9,0,1,2]],[[3,4,5,6],[7,8,9,0],[1,2,3,4]]] 
|	|	ArraySegment 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ConstQueue<ArraySegment<byte>>#0: [2,3] 
|	|	|	CLKernelArgPrivateArraySegment<byte> 
|	|	|		ParameterQueue<ArraySegment<byte>>#0["seg"]: Default=[2,3] 
|	NativeArea 
|	|	NativeMemoryArea 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ConstQueue<NativeMemoryArea>#0: NativeMemoryArea:$1[2] 
|	|	|	CLKernelArgPrivateNativeMemoryArea 
|	|	|		ParameterQueue<NativeMemoryArea>#0["ntv_mem_area"]: Default=NativeMemoryArea:$1[2] 
|	|	NativeValueArea 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ConstQueue<NativeValueArea<byte>>#0: NativeValueArea<byte>:$3 
|	|	|	CLKernelArgPrivateNativeValueArea<byte> 
|	|	|		ParameterQueue<NativeValueArea<byte>>#0["ntv_val_area"]: Default=NativeValueArea<byte>:$3 
|	|	NativeArrayArea 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ConstQueue<NativeArrayArea<byte>>#0: NativeArrayArea<byte>:$4[5] 
|	|	|	CLKernelArgPrivateNativeArrayArea<byte> 
|	|	|		ParameterQueue<NativeArrayArea<byte>>#0["ntv_arr_area"]: Default=NativeArrayArea<byte>:$4[5] 
|	Native 
|	|	NativeMemory 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ConstQueue<NativeMemory>#0: NativeMemory:$*[2] 
|	|	|	CLKernelArgPrivateNativeMemory 
|	|	|		ParameterQueue<NativeMemory>#0["ntv_mem"]: Default=NativeMemory:$*[2] 
|	|	NativeValue 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ConstQueue<NativeValue<byte>>#0: NativeValue<byte>{ 123 } 
|	|	|	CLKernelArgPrivateNativeValue<byte> 
|	|	|		ParameterQueue<NativeValue<byte>>#0["ntv_val"]: Default=NativeValue<byte>{ 123 } 
|	|	NativeArray 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ConstQueue<NativeArray<byte>>#0: [1,2,3,4] 
|	|	|	CLKernelArgPrivateNativeArray<byte> 
|	|	|		ParameterQueue<NativeArray<byte>>#0["ntv_arr"]: Default=[1,2,3,4] 
|	CL 
|	|	CLMemory 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ConstQueue<CLMemory>#0: CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		ParameterQueue<CLMemory>#0["cl_mem"]: Default=CLMemory[*] of size 1 
|	|	|	CLKernelArgGlobalCLMemory 
|	|	|		CLMemoryCCQ#0 
|	|	|			ConstQueue<CLMemory>#1: CLMemory[*] of size 1 
|	|	CLValue 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ConstQueue<CLValue<byte>>#0: CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		ParameterQueue<CLValue<byte>>#0["cl_val"]: Default=CLValue<byte>[*] 
|	|	|	CLKernelArgGlobalCLValue<byte> 
|	|	|		CLValueCCQ<byte>#0 
|	|	|			ConstQueue<CLValue<byte>>#1: CLValue<byte>[*] 
|	|	CLArray 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ConstQueue<CLArray<byte>>#0: CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		ParameterQueue<CLArray<byte>>#0["cl_arr"]: Default=CLArray<byte>[*] of length 4 
|	|	|	CLKernelArgGlobalCLArray<byte> 
|	|	|		CLArrayCCQ<byte>#0 
|	|	|			ConstQueue<CLArray<byte>>#1: CLArray<byte>[*] of length 4 
|	Value 
|	|	CLKernelArgPrivateValue<integer> 
|	|		ConstQueue<integer>#0: 1 
|	|	CLKernelArgPrivateValue<integer> 
|	|		ConstQueue<integer>#0: 1 
|	|	CLKernelArgPrivateValue<integer> 
|	|		ConstQueue<integer>#0: 1 
|	|	CLKernelArgPrivateValue<byte> 
|	|		ConstQueue<byte>#0: 1 
|	|	CLKernelArgPrivateValue<byte> 
|	|		ParameterQueue<byte>#0["val"]: Default=1 

#ReqModules
OpenCLABC


