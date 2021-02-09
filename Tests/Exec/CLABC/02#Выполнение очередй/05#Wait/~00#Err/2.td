


#ReqModules
OpenCLABC

#ExpOtp
System.ArgumentException: Wait очереди не поддерживают ожидание [0] очереди из списка ожидаемых, имеющей тип OpenCLABC.ConstQueue`1[System.Object]
   в OpenCLABC_implementation______.WCQWaiter..ctor(CommandQueueBase[] waitables)
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(CommandQueueBase[] waitables)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 qs)
   в OpenCLABC.OpenCLABC.WaitFor(CommandQueueBase q)
   в 2.Program.p1(CommandQueueBase q)
System.ArgumentException: Wait очереди не поддерживают ожидание [0] очереди из списка ожидаемых, имеющей тип OpenCLABC_implementation______.CastQueue`1[System.Object]
   в OpenCLABC_implementation______.WCQWaiter..ctor(CommandQueueBase[] waitables)
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(CommandQueueBase[] waitables)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 qs)
   в OpenCLABC.OpenCLABC.WaitFor(CommandQueueBase q)
   в 2.Program.p1(CommandQueueBase q)
System.ArgumentException: Wait очереди не поддерживают ожидание [0] очереди из списка ожидаемых, имеющей тип OpenCLABC_implementation______.CommandQueueWaitFor
   в OpenCLABC_implementation______.WCQWaiter..ctor(CommandQueueBase[] waitables)
   в OpenCLABC_implementation______.WCQWaiterAll..ctor(CommandQueueBase[] waitables)
   в OpenCLABC.OpenCLABC.WaitForAll(IEnumerable`1 qs)
   в OpenCLABC.OpenCLABC.WaitFor(CommandQueueBase q)
   в 2.Program.p1(CommandQueueBase q)


