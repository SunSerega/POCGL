


#ReqModules
CLABC

#ExpExecErr
System.AggregateException: %task:errors% ---> System.Exception: >>> текст исключения <<<
   в ErrOtp.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC.<>local_variables_class_7`2.<>lambda11()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в ErrOtp.Program.$Main()
   в ErrOtp.Program.Main()
---> (Внутреннее исключение #0) System.Exception: >>> текст исключения <<<
   в ErrOtp.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC.<>local_variables_class_7`2.<>lambda11()<---


