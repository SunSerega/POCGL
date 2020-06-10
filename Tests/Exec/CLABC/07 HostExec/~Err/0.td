


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано (System.Collections.Generic.List`1[System.Exception]) исключений. Используйте try чтоб получить больше информации ---> System.Exception: >>> текст исключения <<<
   в 0.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC.<>local_variables_class_7`2.<>lambda11()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в 0.Program.$Main()
   в 0.Program.Main()
---> (Внутреннее исключение #0) System.Exception: >>> текст исключения <<<
   в 0.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABC.<>local_variables_class_7`2.<>lambda11()<---


