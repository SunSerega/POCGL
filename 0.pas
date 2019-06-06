uses OpenCLABC;
//ToDo строка 892 - не захватывает локальную переменную, а тупо создаёт новую
// - сделать issue

const
  MatrW = 4; // можно поменять на любое положительное значение
  
  VecByteSize = MatrW*8;
  MatrL = MatrW*MatrW;
  MatrByteSize = MatrL*8;
  
//ToDo issue компилятора:
// - #1533

begin
  Randomize(0);
  
  {$resource MatrMlt.cl}
  var code := new ProgramCode(Context.Default,
    System.IO.StreamReader.Create(GetResourceStream('MatrMlt.cl')).ReadToEnd
  );
  
  var A := new KernelArg(MatrByteSize);
  var B := new KernelArg(MatrByteSize);
  var C := new KernelArg(MatrByteSize);
  
  var V1 := new KernelArg(VecByteSize);
  var V2 := new KernelArg(VecByteSize);
  
  
  
  var Calc_C_Q :=
    code['MatrMltMatr'].NewQueue.Exec(MatrW, MatrW,
      
      A.NewQueue.WriteData(HFQ&<System.Array>(
        ()->
//        lock output do //ToDo #1533
        begin
          System.Threading.Monitor.Enter(output); //ToDo #1533 // то же самое что lock, только ручками
          'Матрица A:'.Println;
          Result := MatrRandomReal(MatrW,MatrW,0,1).Println;
          System.Threading.Monitor.Exit(output); //ToDo #1533
        end
      )) as CommandQueue<KernelArg>,
      
      B.NewQueue.WriteData(HFQ&<System.Array>(
        ()->
//        lock output do //ToDo #1533
        begin
          System.Threading.Monitor.Enter(output); //ToDo #1533
          'Матрица B:'.Println;
          Result := MatrRandomReal(MatrW,MatrW,0,1).Println;
          System.Threading.Monitor.Exit(output); //ToDo #1533
        end
      )) as CommandQueue<KernelArg>,
      
      C,
      
      KernelArg.ValueQueue(MatrW) as CommandQueue<KernelArg>
    ) as CommandQueue<Kernel>;
  
  var Otp_C_Q :=
    HFQ(
      ()->
//      lock output do //ToDo #1533
      begin
        System.Threading.Monitor.Enter(output); //ToDo #1533
        'Матрица С = A*B:'.Println;
        Result := C.GetArray&<array[,] of real>(MatrW,MatrW).Println;
        System.Threading.Monitor.Exit(output); //ToDo #1533
      end
    ) as CommandQueue<array[,] of real>;
  
  var Calc_V2_Q :=
    code['MatrMltVec'].NewQueue.Exec(MatrW,
      
      C,
      
      V1.NewQueue.WriteData(HFQ&<System.Array>(
        ()->
//        lock output do //ToDo #1533
        begin
          System.Threading.Monitor.Enter(output); //ToDo #1533
          'Вектор V1:'.Println;
          var res := ArrRandomReal(MatrW);
          res.Println;
          Result := res;
          System.Threading.Monitor.Exit(output); //ToDo #1533
        end
      )) as CommandQueue<KernelArg>,
      
      V2,
      
      KernelArg.ValueQueue(MatrW) as CommandQueue<KernelArg>
    ) as CommandQueue<Kernel>;
  
  var Otp_V2_Q :=
    HFQ(
      ()->
      begin
        System.Threading.Monitor.Enter(output); //ToDo #1533
        'Вектор V2:'.Println;
        Result := V2.GetArray&<array of real>(MatrW).Println;
        System.Threading.Monitor.Exit(output); //ToDo #1533
      end
    ) as CommandQueue<sequence of real>;
  
  Context.Default.SyncInvoke(
    
    Calc_C_Q +
    (
      Otp_C_Q *
      (
        Calc_V2_Q +
        Otp_V2_Q
      )
    )
    
  );
  
end.