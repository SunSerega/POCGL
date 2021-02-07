


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.Exception: TestOK
   в 0c.Program.<>lambda2(Int32 <>i, Context <>c)
   в OpenCLABC_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_13`2.<>lambda22()
   в OpenCLABC_implementation______.<>local_variables_class_5.<>lambda14()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в OpenCLABC.CLTask`1.WaitRes()
   в 0c.Program.$Main()
   в 0c.Program.Main()
---> (Внутреннее исключение #0) System.Exception: TestOK
   в 0c.Program.<>lambda2(Int32 <>i, Context <>c)
   в OpenCLABC_implementation______.CommandQueueThenConvert`2.ExecFunc(TInp o, Context c)
   в OpenCLABC_implementation______.<>local_variables_class_13`2.<>lambda22()
   в OpenCLABC_implementation______.<>local_variables_class_5.<>lambda14()<---


