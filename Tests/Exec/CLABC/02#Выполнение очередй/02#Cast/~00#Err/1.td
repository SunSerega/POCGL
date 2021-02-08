


#ReqModules
OpenCLABC

#ExpExecErr
System.AggregateException: При выполнении очереди было вызвано 1 исключений. Используйте try чтоб получить больше информации ---> System.InvalidCastException: Specified cast is not valid.
   в OpenCLABC_implementation______.<>local_variables_class_31`1.<>lambda42(Object <>o)
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLTaskBase.Wait()
   в OpenCLABC.CLTask`1.WaitRes()
   в 1.Program.$Main()
   в 1.Program.Main()
---> (Внутреннее исключение #0) System.InvalidCastException: Specified cast is not valid.
   в OpenCLABC_implementation______.<>local_variables_class_31`1.<>lambda42(Object <>o)<---


