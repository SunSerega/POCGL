


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: >>> текст ошибки <<<
   в 0c.Program.<>lambda2(Int32 <>i, Context <>c)
   в OpenCLABCBase_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c)
   в OpenCLABCBase.<>local_variables_class_12`2.<>lambda20()
   в OpenCLABCBase.<>local_variables_class_3.<>lambda9()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABCBase.CLTaskBase.Wait()
   в OpenCLABCBase.CLTask`1.WaitRes()
   в 0c.Program.$Main()
   в 0c.Program.Main()
---> (Внутреннее исключение #0) System.Exception: >>> текст ошибки <<<
   в 0c.Program.<>lambda2(Int32 <>i, Context <>c)
   в OpenCLABCBase_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c)
   в OpenCLABCBase.<>local_variables_class_12`2.<>lambda20()
   в OpenCLABCBase.<>local_variables_class_3.<>lambda9()<---


