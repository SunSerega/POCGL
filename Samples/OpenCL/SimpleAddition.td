


#Delegates
OpenCL.ProgramCallback = procedure(program: cl_program; user_data: System.IntPtr)
OpenCL.CreateContextCallback = procedure(errinfo: System.IntPtr; private_info: System.IntPtr; cb: longword; user_data: System.IntPtr)

#ExpExecOtp
1 2 3 4 5 6 7 8 9 10

#ReqModules
OpenCL

#TestMode
Comp+Exec


