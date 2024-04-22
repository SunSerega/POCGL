


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function(T, cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecOtp
WaitMarkerAny#0
	WaitMarkerAll#1
		WaitMarkerDummy#2 * 100
	WaitMarkerAll#3
		WaitMarkerDummy#2 * 99
		WaitMarkerDummy#4
	WaitMarkerAll#5
		WaitMarkerDummy#2 * 98
		WaitMarkerDummy#4 * 2
	WaitMarkerAll#6
		WaitMarkerDummy#2 * 97
		WaitMarkerDummy#4 * 3
	WaitMarkerAll#7
		WaitMarkerDummy#2 * 96
		WaitMarkerDummy#4 * 4
	WaitMarkerAll#8
		WaitMarkerDummy#2 * 95
		WaitMarkerDummy#4 * 5
	WaitMarkerAll#9
		WaitMarkerDummy#2 * 94
		WaitMarkerDummy#4 * 6
	WaitMarkerAll#10
		WaitMarkerDummy#2 * 93
		WaitMarkerDummy#4 * 7
	WaitMarkerAll#11
		WaitMarkerDummy#2 * 92
		WaitMarkerDummy#4 * 8
	WaitMarkerAll#12
		WaitMarkerDummy#2 * 91
		WaitMarkerDummy#4 * 9
	WaitMarkerAll#13
		WaitMarkerDummy#2 * 90
		WaitMarkerDummy#4 * 10
	WaitMarkerAll#14
		WaitMarkerDummy#2 * 89
		WaitMarkerDummy#4 * 11
	WaitMarkerAll#15
		WaitMarkerDummy#2 * 88
		WaitMarkerDummy#4 * 12
	WaitMarkerAll#16
		WaitMarkerDummy#2 * 87
		WaitMarkerDummy#4 * 13
	WaitMarkerAll#17
		WaitMarkerDummy#2 * 86
		WaitMarkerDummy#4 * 14
	WaitMarkerAll#18
		WaitMarkerDummy#2 * 85
		WaitMarkerDummy#4 * 15
	WaitMarkerAll#19
		WaitMarkerDummy#2 * 84
		WaitMarkerDummy#4 * 16
	WaitMarkerAll#20
		WaitMarkerDummy#2 * 83
		WaitMarkerDummy#4 * 17
	WaitMarkerAll#21
		WaitMarkerDummy#2 * 82
		WaitMarkerDummy#4 * 18
	WaitMarkerAll#22
		WaitMarkerDummy#2 * 81
		WaitMarkerDummy#4 * 19
	WaitMarkerAll#23
		WaitMarkerDummy#2 * 80
		WaitMarkerDummy#4 * 20
	WaitMarkerAll#24
		WaitMarkerDummy#2 * 79
		WaitMarkerDummy#4 * 21
	WaitMarkerAll#25
		WaitMarkerDummy#2 * 78
		WaitMarkerDummy#4 * 22
	WaitMarkerAll#26
		WaitMarkerDummy#2 * 77
		WaitMarkerDummy#4 * 23
	WaitMarkerAll#27
		WaitMarkerDummy#2 * 76
		WaitMarkerDummy#4 * 24
	WaitMarkerAll#28
		WaitMarkerDummy#2 * 75
		WaitMarkerDummy#4 * 25
	WaitMarkerAll#29
		WaitMarkerDummy#2 * 74
		WaitMarkerDummy#4 * 26
	WaitMarkerAll#30
		WaitMarkerDummy#2 * 73
		WaitMarkerDummy#4 * 27
	WaitMarkerAll#31
		WaitMarkerDummy#2 * 72
		WaitMarkerDummy#4 * 28
	WaitMarkerAll#32
		WaitMarkerDummy#2 * 71
		WaitMarkerDummy#4 * 29
	WaitMarkerAll#33
		WaitMarkerDummy#2 * 70
		WaitMarkerDummy#4 * 30
	WaitMarkerAll#34
		WaitMarkerDummy#2 * 69
		WaitMarkerDummy#4 * 31
	WaitMarkerAll#35
		WaitMarkerDummy#2 * 68
		WaitMarkerDummy#4 * 32
	WaitMarkerAll#36
		WaitMarkerDummy#2 * 67
		WaitMarkerDummy#4 * 33
	WaitMarkerAll#37
		WaitMarkerDummy#2 * 66
		WaitMarkerDummy#4 * 34
	WaitMarkerAll#38
		WaitMarkerDummy#2 * 65
		WaitMarkerDummy#4 * 35
	WaitMarkerAll#39
		WaitMarkerDummy#2 * 64
		WaitMarkerDummy#4 * 36
	WaitMarkerAll#40
		WaitMarkerDummy#2 * 63
		WaitMarkerDummy#4 * 37
	WaitMarkerAll#41
		WaitMarkerDummy#2 * 62
		WaitMarkerDummy#4 * 38
	WaitMarkerAll#42
		WaitMarkerDummy#2 * 61
		WaitMarkerDummy#4 * 39
	WaitMarkerAll#43
		WaitMarkerDummy#2 * 60
		WaitMarkerDummy#4 * 40
	WaitMarkerAll#44
		WaitMarkerDummy#2 * 59
		WaitMarkerDummy#4 * 41
	WaitMarkerAll#45
		WaitMarkerDummy#2 * 58
		WaitMarkerDummy#4 * 42
	WaitMarkerAll#46
		WaitMarkerDummy#2 * 57
		WaitMarkerDummy#4 * 43
	WaitMarkerAll#47
		WaitMarkerDummy#2 * 56
		WaitMarkerDummy#4 * 44
	WaitMarkerAll#48
		WaitMarkerDummy#2 * 55
		WaitMarkerDummy#4 * 45
	WaitMarkerAll#49
		WaitMarkerDummy#2 * 54
		WaitMarkerDummy#4 * 46
	WaitMarkerAll#50
		WaitMarkerDummy#2 * 53
		WaitMarkerDummy#4 * 47
	WaitMarkerAll#51
		WaitMarkerDummy#2 * 52
		WaitMarkerDummy#4 * 48
	WaitMarkerAll#52
		WaitMarkerDummy#2 * 51
		WaitMarkerDummy#4 * 49
	WaitMarkerAll#53
		WaitMarkerDummy#2 * 50
		WaitMarkerDummy#4 * 50
	WaitMarkerAll#54
		WaitMarkerDummy#4 * 51
		WaitMarkerDummy#2 * 49
	WaitMarkerAll#55
		WaitMarkerDummy#4 * 52
		WaitMarkerDummy#2 * 48
	WaitMarkerAll#56
		WaitMarkerDummy#4 * 53
		WaitMarkerDummy#2 * 47
	WaitMarkerAll#57
		WaitMarkerDummy#4 * 54
		WaitMarkerDummy#2 * 46
	WaitMarkerAll#58
		WaitMarkerDummy#4 * 55
		WaitMarkerDummy#2 * 45
	WaitMarkerAll#59
		WaitMarkerDummy#4 * 56
		WaitMarkerDummy#2 * 44
	WaitMarkerAll#60
		WaitMarkerDummy#4 * 57
		WaitMarkerDummy#2 * 43
	WaitMarkerAll#61
		WaitMarkerDummy#4 * 58
		WaitMarkerDummy#2 * 42
	WaitMarkerAll#62
		WaitMarkerDummy#4 * 59
		WaitMarkerDummy#2 * 41
	WaitMarkerAll#63
		WaitMarkerDummy#4 * 60
		WaitMarkerDummy#2 * 40
	WaitMarkerAll#64
		WaitMarkerDummy#4 * 61
		WaitMarkerDummy#2 * 39
	WaitMarkerAll#65
		WaitMarkerDummy#4 * 62
		WaitMarkerDummy#2 * 38
	WaitMarkerAll#66
		WaitMarkerDummy#4 * 63
		WaitMarkerDummy#2 * 37
	WaitMarkerAll#67
		WaitMarkerDummy#4 * 64
		WaitMarkerDummy#2 * 36
	WaitMarkerAll#68
		WaitMarkerDummy#4 * 65
		WaitMarkerDummy#2 * 35
	WaitMarkerAll#69
		WaitMarkerDummy#4 * 66
		WaitMarkerDummy#2 * 34
	WaitMarkerAll#70
		WaitMarkerDummy#4 * 67
		WaitMarkerDummy#2 * 33
	WaitMarkerAll#71
		WaitMarkerDummy#4 * 68
		WaitMarkerDummy#2 * 32
	WaitMarkerAll#72
		WaitMarkerDummy#4 * 69
		WaitMarkerDummy#2 * 31
	WaitMarkerAll#73
		WaitMarkerDummy#4 * 70
		WaitMarkerDummy#2 * 30
	WaitMarkerAll#74
		WaitMarkerDummy#4 * 71
		WaitMarkerDummy#2 * 29
	WaitMarkerAll#75
		WaitMarkerDummy#4 * 72
		WaitMarkerDummy#2 * 28
	WaitMarkerAll#76
		WaitMarkerDummy#4 * 73
		WaitMarkerDummy#2 * 27
	WaitMarkerAll#77
		WaitMarkerDummy#4 * 74
		WaitMarkerDummy#2 * 26
	WaitMarkerAll#78
		WaitMarkerDummy#4 * 75
		WaitMarkerDummy#2 * 25
	WaitMarkerAll#79
		WaitMarkerDummy#4 * 76
		WaitMarkerDummy#2 * 24
	WaitMarkerAll#80
		WaitMarkerDummy#4 * 77
		WaitMarkerDummy#2 * 23
	WaitMarkerAll#81
		WaitMarkerDummy#4 * 78
		WaitMarkerDummy#2 * 22
	WaitMarkerAll#82
		WaitMarkerDummy#4 * 79
		WaitMarkerDummy#2 * 21
	WaitMarkerAll#83
		WaitMarkerDummy#4 * 80
		WaitMarkerDummy#2 * 20
	WaitMarkerAll#84
		WaitMarkerDummy#4 * 81
		WaitMarkerDummy#2 * 19
	WaitMarkerAll#85
		WaitMarkerDummy#4 * 82
		WaitMarkerDummy#2 * 18
	WaitMarkerAll#86
		WaitMarkerDummy#4 * 83
		WaitMarkerDummy#2 * 17
	WaitMarkerAll#87
		WaitMarkerDummy#4 * 84
		WaitMarkerDummy#2 * 16
	WaitMarkerAll#88
		WaitMarkerDummy#4 * 85
		WaitMarkerDummy#2 * 15
	WaitMarkerAll#89
		WaitMarkerDummy#4 * 86
		WaitMarkerDummy#2 * 14
	WaitMarkerAll#90
		WaitMarkerDummy#4 * 87
		WaitMarkerDummy#2 * 13
	WaitMarkerAll#91
		WaitMarkerDummy#4 * 88
		WaitMarkerDummy#2 * 12
	WaitMarkerAll#92
		WaitMarkerDummy#4 * 89
		WaitMarkerDummy#2 * 11
	WaitMarkerAll#93
		WaitMarkerDummy#4 * 90
		WaitMarkerDummy#2 * 10
	WaitMarkerAll#94
		WaitMarkerDummy#4 * 91
		WaitMarkerDummy#2 * 9
	WaitMarkerAll#95
		WaitMarkerDummy#4 * 92
		WaitMarkerDummy#2 * 8
	WaitMarkerAll#96
		WaitMarkerDummy#4 * 93
		WaitMarkerDummy#2 * 7
	WaitMarkerAll#97
		WaitMarkerDummy#4 * 94
		WaitMarkerDummy#2 * 6
	WaitMarkerAll#98
		WaitMarkerDummy#4 * 95
		WaitMarkerDummy#2 * 5
	WaitMarkerAll#99
		WaitMarkerDummy#4 * 96
		WaitMarkerDummy#2 * 4
	WaitMarkerAll#100
		WaitMarkerDummy#4 * 97
		WaitMarkerDummy#2 * 3
	WaitMarkerAll#101
		WaitMarkerDummy#4 * 98
		WaitMarkerDummy#2 * 2
	WaitMarkerAll#102
		WaitMarkerDummy#4 * 99
		WaitMarkerDummy#2
	WaitMarkerAll#103
		WaitMarkerDummy#4 * 100

#ReqModules
OpenCLABC


