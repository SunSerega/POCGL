


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: 1, TestOK
   в AddQueue.<>local_variables_class_0.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_13`2.<>lambda22()
   в OpenCLABC_implementation______.<>local_variables_class_5.<>lambda14()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в OpenCLABC.CLTask`1.WaitRes()
   в AddQueue.Program.$Main()
   в AddQueue.Program.Main()
---> (Внутреннее исключение #0) System.Exception: 1, TestOK
   в AddQueue.<>local_variables_class_0.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_13`2.<>lambda22()
   в OpenCLABC_implementation______.<>local_variables_class_5.<>lambda14()<---


