


#ExpOtp
System.AggregateException: При выполнении очереди было вызвано (1) исключений. Используйте try чтоб получить больше информации ---> System.Exception: >>> текст исключения <<<
   в ErrOtp.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC.<>local_variables_class_9`2.<>lambda11()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTask`1.Wait()
   в OpenCLABC.CLTask`1.GetRes()
   в ErrOtp.Program.$Main()
---> (Внутреннее исключение #0) System.Exception: >>> текст исключения <<<
   в ErrOtp.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC.<>local_variables_class_9`2.<>lambda11()<---


