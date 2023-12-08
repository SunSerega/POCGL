


#Delegates
GraphWPF.$delegate? = procedure
GraphWPF.$delegate? = procedure
GraphWPF.$delegate? = procedure
GraphWPF.$delegate? = procedure(ch: char)
GraphWPF.$delegate? = procedure(dc: DrawingContext)
GraphWPF.$delegate? = procedure(delta: real)
GraphWPF.$delegate? = procedure(dt: real)
GraphWPF.$delegate? = procedure(frame: integer)
GraphWPF.$delegate? = procedure(fs: FontStyle)
GraphWPF.$delegate? = procedure(k: Key)
GraphWPF.$delegate? = procedure(k: Key)
GraphWPF.$delegate? = procedure(s: string)
GraphWPF.$delegate? = procedure(x: real; y: real; mousebutton: integer)
GraphWPF.$delegate? = procedure(x: real; y: real; mousebutton: integer)
GraphWPF.$delegate? = procedure(x: real; y: real; mousebutton: integer)
GraphWPF_implementation______.$delegate? = procedure
GraphWPF_implementation______.$delegate? = procedure(c: Color)
GraphWPF_implementation______.$delegate? = procedure(frame: integer)
GraphWPF_implementation______.$delegate? = procedure(x: real; y: real; r1: real; r2: real; c: Color)
GraphWPFBase.$delegate? = procedure(b: boolean)
GraphWPFBase.$delegate? = procedure(c: string)
GraphWPFBase.$delegate? = procedure(h: real)
GraphWPFBase.$delegate? = procedure(l: real)
GraphWPFBase.$delegate? = procedure(t: real)
GraphWPFBase.$delegate? = procedure(w: real)
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: System.IntPtr; cb: System.UIntPtr; user_data: System.IntPtr)
OpenCL.clEventCallback = procedure(event: cl_event; event_command_status: clCommandExecutionStatus; user_data: System.IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCLABC.$delegate? = function(ntv: cl_program; var data: clBool; validate: boolean): clErrorCode
OpenCLABC._GetPropValueFunc<T> = function(ntv: cl_program; var data: T): clErrorCode
OpenCLABC_implementation______.EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): ValueTuple<cl_event,CLContext -> ()>
OpenCLABC_implementation______.InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleList<EventList>; par_err_handlers: DoubleList<ErrHandler>): ValueTuple<procedure,EnqFunc<T>>

#ReqModules
OpenCLABC


