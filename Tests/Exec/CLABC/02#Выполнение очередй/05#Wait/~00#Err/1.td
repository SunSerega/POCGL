


#ReqModules
OpenCLABC

#ExpExecErr
System.ArgumentException: Wait очереди должны ожидать хотя бы одну очередь
   в OpenCLABC_implementation______.WCQWaiter..ctor(MarkerQueue[] waitables)
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(MarkerQueue[] waitables)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 qs)
   в OpenCLABC.OpenCLABC.WaitForAll(MarkerQueue[] qs)
   в 1.Program.Main()


