


#ReqModules
OpenCLABC

#ExpExecErr
System.InvalidCastException: Заданное приведение является недопустимым.
   в OpenCLABC_implementation______.CastQueue`1.<>lambda44(Object <>o)
   в OpenCLABC_implementation______.<>local_variables_class_8`2.<>lambda17(T <>o)
   в OpenCLABC_implementation______.QueueResConst`1.LazyQuickTransform[T2](Func`2 f)
   в OpenCLABC_implementation______.QueueRes`1.LazyQuickTransformBase[T2](Func`2 f)
   в OpenCLABC_implementation______.CastQueue`1.InvokeImpl(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABC.CommandQueue`1.Invoke(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABC.CLTask`1..ctor(CommandQueue`1 q, Context c)
   в 0.Program.$Main()
   в 0.Program.Main()


