


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 0.Program.<>lambda2(Int32 <>i)
   в OpenCLABCBase.<>local_variables_class_12`2.<>lambda22(T <>o, Context <>c)
   в OpenCLABCBase_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c)
   в OpenCLABCBase.<>local_variables_class_14`2.<>lambda23()
   в OpenCLABCBase.<>local_variables_class_3.<>lambda11()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABCBase.CLTaskBase.Wait()
   в OpenCLABCBase.CLTask`1.WaitRes()
   в 0.Program.$Main()
   в 0.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 0.Program.<>lambda2(Int32 <>i)
   в OpenCLABCBase.<>local_variables_class_12`2.<>lambda22(T <>o, Context <>c)
   в OpenCLABCBase_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c)
   в OpenCLABCBase.<>local_variables_class_14`2.<>lambda23()
   в OpenCLABCBase.<>local_variables_class_3.<>lambda11()<---


