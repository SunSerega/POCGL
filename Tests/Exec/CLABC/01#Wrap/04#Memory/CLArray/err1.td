


#ReqModules
OpenCLABC

#ExpExecErr
System.TypeInitializationException: Инициализатор типа "OpenCLABC.CLArray`1" выдал исключение. ---> OpenCLABC_implementation______.BlittableException: Значения типа System.Boolean нельзя использовать как элементы CLArray<>
   в OpenCLABC_implementation______.BlittableHelper.RaiseIfBad(Type t, String source_name)
   в OpenCLABC.CLArray`1..cctor()
   --- Конец трассировки внутреннего стека исключений ---
   в OpenCLABC.CLArray`1..ctor(Int32 len)
   в err1.Program.Main()


