uses OpenCL;
uses System;
uses System.Runtime.InteropServices;

const
  buf_size = 10;
  buf_byte_size = buf_size * 4;
  
begin
  var ec: ErrorCode;
  
  // Инициализация
  
  var platform: cl_platform_id;
  cl.GetPlatformIDs(1, platform, IntPtr.Zero).RaiseIfError;
  
  var device: cl_device_id;
  cl.GetDeviceIDs(platform, DeviceType.DEVICE_TYPE_ALL, 1,device,IntPtr.Zero).RaiseIfError;
  // Если пишет что устройств нет - обновите драйверы
  
  var context := cl.CreateContext(IntPtr.Zero, 1,device, nil,IntPtr.Zero, ec);
  ec.RaiseIfError;
  
  var command_queue := cl.CreateCommandQueue(context, device, CommandQueueProperties.NONE, ec);
  ec.RaiseIfError;
  
  // Чтение и компиляция .cl файла
  
  var prog: cl_program;
  begin
    {$resource SimpleAddition.cl} // эта строчка засовывает SimpleAddition.cl внутрь .exe, чтоб не надо было таскать его вместе с .exe
    var prog_str := System.IO.StreamReader.Create(
      System.Reflection.Assembly.GetCallingAssembly.GetManifestResourceStream('SimpleAddition.cl')
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
  
  var kernel := cl.CreateKernel(prog, 'TEST', ec); // То же имя что у kernel'а из .cl файла. Регистр важен!
  ec.RaiseIfError;
  
  // Подготовка и запуск программы на GPU
  
  var buf := cl.CreateBuffer(context, MemFlags.MEM_READ_WRITE, new UIntPtr(buf_byte_size),nil, ec);
  ec.RaiseIfError;
  
  begin
    var buf_fill_pattern := 1;
    cl.EnqueueFillBuffer(command_queue, buf, buf_fill_pattern,new UIntPtr(sizeof(integer)), UIntPtr.Zero,new UIntPtr(buf_byte_size), 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  end;
  
  cl.SetKernelArg(kernel, 0, new UIntPtr(cl_mem.Size), buf).RaiseIfError;
  
  begin
    var exec_size := new UIntPtr(buf_size);
    cl.EnqueueNDRangeKernel(command_queue, kernel, 1, IntPtr.Zero,exec_size,IntPtr.Zero, 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
  end;
  
  // Чтение и вывод результата
  
  begin
    var res := new integer[buf_size];
    cl.EnqueueReadBuffer(command_queue, buf, Bool.NON_BLOCKING, UIntPtr.Zero, new UIntPtr(buf_byte_size), res[0], 0,IntPtr.Zero,IntPtr.Zero).RaiseIfError;
    cl.Finish(command_queue).RaiseIfError;
    res.Println;
  end;
  
end.