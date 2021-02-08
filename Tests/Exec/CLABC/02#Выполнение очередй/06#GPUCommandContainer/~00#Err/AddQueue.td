


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: 1, TestOK
   в AddQueue.<>local_variables_class_*.<>lambda*()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*()
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в OpenCLABC.CLTask`1.WaitRes()
   в AddQueue.Program.$Main()
   в AddQueue.Program.Main()
---> (Внутреннее исключение #0) System.Exception: 1, TestOK
   в AddQueue.<>local_variables_class_*.<>lambda*()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_*`2.<>lambda*()
   в OpenCLABC_implementation______.<>local_variables_class_*.<>lambda*()<---


