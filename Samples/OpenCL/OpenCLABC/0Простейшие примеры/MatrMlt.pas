uses OpenCLABC;

const
  MatrW = 4; // можно поменять на любое положительное значение
  
  VecByteSize = MatrW*8;
  MatrByteSize = MatrW*MatrW*8;
  
//ToDo issue компилятора:
// - #1981

begin
  Randomize(0); // нужно чтоб каждое выполнение давало одинаковый результат
  
  // Чтение и компиляция .cl файла
  
  {$resource MatrMlt.cl} // Засовывает файл MatrMlt.cl внуть .exe
  var code := new ProgramCode(
    System.IO.StreamReader.Create(
      GetResourceStream('MatrMlt.cl')
    ).ReadToEnd
  );
  
  // Подготовка параметров
  
  'Матрица A:'.Println;
  var A_Matr := MatrRandomReal(MatrW,MatrW,0,1).Println;
  writeln;
  var A := new Buffer(MatrByteSize);
  
  'Матрица B:'.Println;
  var B_Mart := MatrRandomReal(MatrW,MatrW,0,1).Println;
  writeln;
  var B := new Buffer(MatrByteSize);
  
  var C := new Buffer(MatrByteSize);
  
  'Вектор V1:'.Println;
  var V1_Arr := ArrRandomReal(MatrW);
  V1_Arr.Println;
  writeln;
  var V1 := new Buffer(VecByteSize);
  
  var V2 := new Buffer(VecByteSize);
  
  var N := new Buffer(4);
  
  // (запись значений в параметры - позже, в очередях)
  
  // Подготовка очередей выполнения
  
  var Calc_C_Q :=
    code['MatrMltMatr'].NewQueue.Exec2(MatrW, MatrW,
      A.NewQueue.WriteArray(A_Matr) as CommandQueue<Buffer>,
      B.NewQueue.WriteArray(B_Mart) as CommandQueue<Buffer>,
      C,
      N.NewQueue.WriteValue(MatrW) as CommandQueue<Buffer>
    ) as CommandQueue<Kernel>;
  
  var Otp_C_Q :=
    C.NewQueue.ReadArray(A_Matr) as CommandQueue<Buffer> +
    HPQ(()->
    lock output do
    begin
      'Матрица С = A*B:'.Println;
      A_Matr.Println;
      writeln;
    end);
  
  var Calc_V2_Q :=
    code['MatrMltVec'].NewQueue.Exec1(MatrW,
      C,
      V1.NewQueue.WriteArray(V1_Arr) as CommandQueue<Buffer>,
      V2,
      N
    ) as CommandQueue<Kernel>;
  
  var Otp_V2_Q :=
    V2.NewQueue.ReadArray(V1_Arr) as CommandQueue<Buffer> +
    HPQ(()->
    lock output do
    begin
      'Вектор V2 = C*V1:'.Println;
      V1_Arr.Println;
      writeln;
    end);
  
  // Выполнение всего и сразу асинхронный вывод
  
  Context.Default.SyncInvoke(
    
    Calc_C_Q +
    (
      Otp_C_Q * // выводить C и считать V2 можно одновременно, поэтому тут *, т.е. параллельное выполнение
      (
        Calc_V2_Q +
        Otp_V2_Q
      )
    )
    
  );
  
end.