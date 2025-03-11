


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<[T]> = function(ntv: cl_program; var data: [T]): clErrorCode
OpenCLABC_implementation______.EnqFunc<[T]> = function(prev_res: [T]; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event, procedure(CLContext)>
OpenCLABC_implementation______.InvokeParamsFunc<[T]> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure, function([T], cl_command_queue, EventList): ValueTuple<cl_event, procedure(CLContext)>>

#ExpExecErr
System.InvalidProgramException: Преобразовывать комбинацию маркеров в очередь нельзя. Возможно вы забыли написать WaitFor?
   at OpenCLABC_implementation______.WaitMarkerCombination`1.ConvertToQBase() in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at OpenCLABC.WaitMarker.op_Implicit(WaitMarker m) in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\LibSource\OpenCLABC.pas:line @[1..*0..9]
   at invoke WaitAll.Program.$Main() in @[1*A..Z]:@[*0..9A..Z\a..z]\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\10#WaitMarker\~00#Err\invoke WaitAll.pas:line @[1..*0..9]
   at invoke WaitAll.Program.Main()

#ReqModules
OpenCLABC


