uses OpenCLABC;
{$resource Samples\OpenCL\MatrMlt.cl}

const
  MatrW = 4; // можно поменять на любое положительное значение
  
  VecByteSize = MatrW*8;
  MatrL = MatrW*MatrW;
  MatrByteSize = MatrL*8;
  
//ToDo issue компилятора:
// - #1533

begin
  var cont := new Context;
  
  var code := new ProgramCode(cont,
    System.IO.StreamReader.Create(GetResourceStream('MatrMlt.cl')).ReadToEnd
  );
  
  var A := new KernelArg(MatrByteSize);
  var B := new KernelArg(MatrByteSize);
  var C := new KernelArg(MatrByteSize);
  
  var V1 := new KernelArg(VecByteSize);
  var V2 := new KernelArg(VecByteSize);
  
  cont.SyncInvoke(
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
          System.Threading.Monitor.Enter(output); //ToDo #1533 // то же самое что lock, только ручками
          'Матрица B:'.Println;
          Result := MatrRandomReal(MatrW,MatrW,0,1).Println;
          System.Threading.Monitor.Exit(output); //ToDo #1533
        end
      )) as CommandQueue<KernelArg>,
      
      C,
      
      KernelArg.ValueQueue(MatrW) as CommandQueue<KernelArg>
      
    ) as CommandQueue<Kernel>
  );
  
end.