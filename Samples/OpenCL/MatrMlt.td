


#Delegates
OpenCL.clCreateContextCallback = procedure(errinfo: string; private_info: IntPtr; cb: UIntPtr; user_data: IntPtr)
OpenCL.clProgramCallback = procedure(program: cl_program; user_data: IntPtr)

#ExpExecOtp
Матрица A:
   0.73   0.82   0.77   0.56
   0.21   0.56   0.91   0.44
   0.98   0.27   0.29   0.47
   0.63   0.47   0.98   0.03

Матрица B:
   0.86   1.00   0.68   0.31
   0.82   0.85   0.99   0.03
   0.70   0.53   0.93   0.69
   0.55   0.08   0.19   0.45

Вектор V1:
2.97 9.89 6.43 7.63

Матрица С = A*B:
   2.15   1.52   1.53   1.63
   1.88   1.20   1.40   1.55
   2.13   1.63   1.29   1.81
   1.03   0.91   0.72   0.90

Вектор V2 = C*V1:
43.642978 38.329481 44.548663 23.561954

#ReqModules
OpenCL

#TestMode
Comp+Exec


