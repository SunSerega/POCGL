


#ReqModules
OpenCLABC

#ExpExecErr
System.ArgumentException: Wait очереди должны ожидать хотя бы одну очередь
   в OpenCLABC_implementation______.WCQWaiter..ctor(WaitMarkerBase[] markers)
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(WaitMarkerBase[] markers)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 markers)
   в OpenCLABC.OpenCLABC.WaitForAll(WaitMarkerBase[] markers)
   в 1.Program.Main()


