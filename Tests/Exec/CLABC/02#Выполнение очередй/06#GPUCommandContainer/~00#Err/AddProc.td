


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: 1, TestOK
   в AddProc.Program.<>lambda1(Buffer <>b)
   в OpenCLABCBase.<>local_variables_class_3.<>lambda11()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABCBase.CLTaskBase.Wait()
   в OpenCLABCBase.CLTask`1.WaitRes()
   в AddProc.Program.$Main()
   в AddProc.Program.Main()
---> (Внутреннее исключение #0) System.Exception: 1, TestOK
   в AddProc.Program.<>lambda1(Buffer <>b)
   в OpenCLABCBase.<>local_variables_class_3.<>lambda11()<---


