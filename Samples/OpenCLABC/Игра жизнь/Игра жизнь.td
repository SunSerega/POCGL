


#Delegates
GraphWPFBase.$delegate? = procedure(l: real)
GraphWPFBase.$delegate? = procedure(t: real)
GraphWPFBase.$delegate? = procedure(w: real)
GraphWPFBase.$delegate? = procedure(h: real)
GraphWPFBase.$delegate? = procedure(c: string)
GraphWPFBase.$delegate? = procedure(b: boolean)
GraphWPF.$delegate? = procedure(s: string)
GraphWPF.$delegate? = procedure(fs: FontStyle)
GraphWPF.$delegate? = procedure
GraphWPF.$delegate? = procedure(frame: integer)
GraphWPF.$delegate? = procedure(x: real; y: real; mousebutton: integer)
GraphWPF.$delegate? = procedure(x: real; y: real; mousebutton: integer)
GraphWPF.$delegate? = procedure(x: real; y: real; mousebutton: integer)
GraphWPF.$delegate? = procedure(delta: real)
GraphWPF.$delegate? = procedure(k: Key)
GraphWPF.$delegate? = procedure(k: Key)
GraphWPF.$delegate? = procedure(ch: char)
GraphWPF.$delegate? = procedure
GraphWPF.$delegate? = procedure
GraphWPF.$delegate? = procedure(dt: real)
GraphWPF.$delegate? = procedure(dc: DrawingContext)
GraphWPF_implementation______.$delegate? = procedure(x: real; y: real; r1: real; r2: real; c: Color)
GraphWPF_implementation______.$delegate? = procedure(c: Color)
GraphWPF_implementation______.$delegate? = procedure
GraphWPF_implementation______.$delegate? = procedure(frame: integer)
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)
OpenCL.EventCallback = procedure(event: cl_event; event_command_status: CommandExecutionStatus; user_data: System.IntPtr)
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ValueTuple<CLTaskErrHandler,EnqFunc<T>>

#ReqModules
OpenCLABC


