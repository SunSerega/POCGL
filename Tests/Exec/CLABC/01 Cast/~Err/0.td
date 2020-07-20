


#ReqModules
OpenCLABC

#ExpExecErr
System.InvalidCastException: Заданное приведение является недопустимым.
   в OpenCLABCBase_implementation______.CastQueue`1.<>lambda56(Object <>o)
   в OpenCLABCBase.QueueResBase.LazyQuickTransformBase[T2](Func`2 f)
   в OpenCLABCBase_implementation______.CastQueue`1.InvokeImpl(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABCBase.CommandQueue`1.Invoke(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABCBase.CommandQueue`1.InvokeBase(CLTaskBase tsk, Context c, cl_device_id main_dvc, Boolean need_ptr_qr, cl_command_queue& cq, EventList prev_ev)
   в OpenCLABCBase_implementation______.CLTaskResLess..ctor(CommandQueueBase q, Context c)
   в 0.Program.$Main()
   в 0.Program.Main()


