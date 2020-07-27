


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: >>> текст ошибки <<<
   в 0.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABCBase.<>local_variables_class_12`2.<>lambda21()
   в OpenCLABCBase.<>local_variables_class_3.<>lambda10()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABCBase.CLTaskBase.Wait()
   в OpenCLABCBase_implementation______.CLTaskResLess.WaitResBase()
   в 0.Program.$Main()
   в 0.Program.Main()
---> (Внутреннее исключение #0) System.Exception: >>> текст ошибки <<<
   в 0.Program.<>lambda1()
   в OpenCLABC_implementation______.CommandQueueHostProc.ExecFunc(Object o, Context c)
   в OpenCLABCBase.<>local_variables_class_12`2.<>lambda21()
   в OpenCLABCBase.<>local_variables_class_3.<>lambda10()<---


