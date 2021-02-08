


#ReqModules
OpenCLABC

#ExpExecErr
System.ArgumentException: Wait очереди должны ожидать хотя бы одну очередь
   в OpenCLABC_implementation______.WCQWaiter..ctor(CommandQueueBase[] waitables)
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(CommandQueueBase[] waitables)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 qs)
   в OpenCLABC.OpenCLABC.WaitForAll(CommandQueueBase[] qs)
   в 1.Program.Main()


