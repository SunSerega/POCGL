


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ExpExecErr
System.InvalidProgramException: Преобразовывать комбинацию маркеров в очередь нельзя. Возможно вы забыли написать WaitFor?
   at OpenCLABC_implementation______.WaitMarkerCombination`1.ConvertToQBase() in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at OpenCLABC.WaitMarker.op_Implicit(WaitMarker m) in *\POCGL\Tests\LibSource\OpenCLABC.pas:line *
   at invoke WaitAll.Program.$Main() in *\POCGL\Tests\Exec\CLABC\02#Выполнение очередей\10#WaitMarker\~00#Err\invoke WaitAll.pas:line *
   at invoke WaitAll.Program.Main()

#ReqModules
OpenCLABC


