


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 0.Program.<>lambda2()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_14`2.<>lambda23()
   в OpenCLABC_implementation______.<>local_variables_class_5.<>lambda14()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в 0.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 0.Program.<>lambda2()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_14`2.<>lambda23()
   в OpenCLABC_implementation______.<>local_variables_class_5.<>lambda14()<---


