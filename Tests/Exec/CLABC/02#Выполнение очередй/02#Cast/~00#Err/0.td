


#ReqModules
OpenCLABC

#ExpExecErr
System.InvalidCastException: Заданное приведение является недопустимым.
   в OpenCLABCBase_implementation______.CastQueue`1.<>lambda55(Object <>o)
   в OpenCLABCBase.<>local_variables_class_6`2.<>lambda14(T <>o)
   в OpenCLABCBase.QueueResConst`1.LazyQuickTransform[T2](Func`2 f)
   в OpenCLABCBase.QueueRes`1.LazyQuickTransformBase[T2](Func`2 f)
   в OpenCLABCBase_implementation______.CastQueue`1.InvokeImpl(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABCBase.CommandQueue`1.Invoke(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABCBase.CLTask`1.InvokeQueue(CommandQueue`1 q, Context c, cl_command_queue& cq)
   в OpenCLABCBase.CLTask`1..ctor(CommandQueue`1 q, Context c)
   в 0.Program.$Main()
   в 0.Program.Main()


