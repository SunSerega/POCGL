uses OpenCL;
uses System;
uses System.Runtime.InteropServices;

const
  MatrW = 4; // можно поменять на любое положительное значение
  
  VecByteSize = MatrW*8;
  MatrL = MatrW*MatrW;
  MatrByteSize = MatrL*8;
  
begin
  Randomize(0); // чтоб при каждом выполнении были одинаковые результаты
  var ec: ErrorCode;
  
  // Инициализация
  
  var platform: cl_platform_id;
  cl.GetPlatformIDs(1, platform, IntPtr.Zero).RaiseIfError;
  
  var device: cl_device_id;
  cl.GetDeviceIDs(platform, DeviceType.DEVICE_TYPE_ALL, 1,device,IntPtr.Zero).RaiseIfError;
  
  var context := cl.CreateContext(IntPtr.Zero, 1,device, nil,IntPtr.Zero, ec);
  ec.RaiseIfError;
  
  var command_queue := cl.CreateCommandQueueWithProperties(context, device, nil, ec);
  ec.RaiseIfError;
  
  // Чтение и компиляция .cl файла
  
  var prog: cl_program;
  begin
    {$resource MatrMlt.cl}
    var prog_str := System.IO.StreamReader.Create(
      System.Reflection.Assembly.GetCallingAssembly.GetManifestResourceStream('MatrMlt.cl')
    ).ReadToEnd;
    prog := cl.CreateProgramWithSource(
      context,
      1,
      new string[](prog_str),
      nil,
      ec
    );
    ec.RaiseIfError;
  end;
  
  cl.BuildProgram(prog, 1,device, nil, nil,IntPtr.Zero).RaiseIfError;
  
  var MatrMltMatrKernel := cl.CreateKernel(prog, 'MatrMltMatr', ec);
  ec.RaiseIfError;
  
  var MatrMltVecKernel := cl.CreateKernel(prog, 'MatrMltVec', ec);
  ec.RaiseIfError;
  
  // Подготовка параметров
  
  Writeln('Матрица A:');
  var A := MatrRandomReal(MatrW,MatrW,0,1).Println;
  Writeln;
  var A_buf := cl.CreateBuffer(context, MemFlags.MEM_READ_WRITE, new UIntPtr(MatrByteSize),nil, ec);
  ec.RaiseIfError;
  cl.EnqueueWriteBuffer(command_queue, A_buf, Bool.NON_BLOCKING, UIntPtr.Zero,new UIntPtr(MatrByteSize), A[0,0], 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  
  Writeln('Матрица B:');
  var B := MatrRandomReal(MatrW,MatrW,0,1).Println;
  Writeln;
  var B_buf := cl.CreateBuffer(context, MemFlags.MEM_READ_WRITE, new UIntPtr(MatrByteSize),nil, ec);
  ec.RaiseIfError;
  cl.EnqueueWriteBuffer(command_queue, B_buf, Bool.NON_BLOCKING, UIntPtr.Zero,new UIntPtr(MatrByteSize), B[0,0], 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  
  Writeln('Вектор V1:');
  var V1 := ArrRandomReal(MatrW);
  V1.Println;
  Writeln;
  var V1_buf := cl.CreateBuffer(context, MemFlags.MEM_READ_WRITE, new UIntPtr(VecByteSize),nil, ec);
  ec.RaiseIfError;
  cl.EnqueueWriteBuffer(command_queue, V1_buf, Bool.NON_BLOCKING, UIntPtr.Zero,new UIntPtr(VecByteSize), V1[0], 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  
  var C_buf := cl.CreateBuffer(context, MemFlags.MEM_READ_WRITE, new UIntPtr(MatrByteSize),nil, ec);
  ec.RaiseIfError;
  
  var V2_buf := cl.CreateBuffer(context, MemFlags.MEM_READ_WRITE, new UIntPtr(VecByteSize),nil, ec);
  ec.RaiseIfError;
  
  var MatrWParam := MatrW;
  
  // Выполнение C := A*B
  
  cl.SetKernelArg(MatrMltMatrKernel, 0, new UIntPtr(cl_mem.Size), A_buf).RaiseIfError;
  cl.SetKernelArg(MatrMltMatrKernel, 1, new UIntPtr(cl_mem.Size), B_buf).RaiseIfError;
  cl.SetKernelArg(MatrMltMatrKernel, 2, new UIntPtr(cl_mem.Size), C_buf).RaiseIfError;
  cl.SetKernelArg(MatrMltMatrKernel, 3, new UIntPtr(sizeof(integer)), @MatrWParam).RaiseIfError;
  
  begin
    var exec_size := |new UIntPtr(MatrW),new UIntPtr(MatrW)|;
    cl.EnqueueNDRangeKernel(command_queue, MatrMltMatrKernel, 2, IntPtr.Zero,exec_size[0],IntPtr.Zero, 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  end;
  
  // Выполнение V2 := C*V
  
  cl.SetKernelArg(MatrMltVecKernel, 0, new UIntPtr(cl_mem.Size),  C_buf).RaiseIfError;
  cl.SetKernelArg(MatrMltVecKernel, 1, new UIntPtr(cl_mem.Size), V1_buf).RaiseIfError;
  cl.SetKernelArg(MatrMltVecKernel, 2, new UIntPtr(cl_mem.Size), V2_buf).RaiseIfError;
  cl.SetKernelArg(MatrMltVecKernel, 3, new UIntPtr(sizeof(integer)), @MatrWParam).RaiseIfError;
  
  begin
    var exec_size := new UIntPtr(MatrW);
    cl.EnqueueNDRangeKernel(command_queue, MatrMltVecKernel, 1, IntPtr.Zero,exec_size,IntPtr.Zero, 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  end;
  
  // Чтение и вывод результата
  
  cl.EnqueueReadBuffer(command_queue, C_buf,  Bool.NON_BLOCKING, UIntPtr.Zero, new UIntPtr(MatrByteSize), A[0,0], 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  
  cl.EnqueueReadBuffer(command_queue, V2_buf, Bool.NON_BLOCKING, UIntPtr.Zero, new UIntPtr(VecByteSize), V1[0], 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  
  cl.Finish(command_queue).RaiseIfError;
  
  Writeln('Матрица С = A*B:');
  A.Println;
  Writeln;
  
  Writeln('Вектор V2 = C*V1:');
  V1.Println;
  
end.