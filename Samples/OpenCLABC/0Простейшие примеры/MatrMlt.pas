﻿## uses OpenCLABC;

try
  var W := 4; // Можно поменять на любое положительное значение
  Randomize(0); // Делает так, чтобы каждое выполнение давало одинаковый результат
  
  // Чтение и компиляция .cl файла
  
  {$resource MatrMlt.cl} // Засовывает файл MatrMlt.cl внуть .exe
  // Вообще лучше прекомпилировать .cl файл
  // (загружать в переменную типа ProgramCode)
  // И сохранять с помощью метода ProgramCode.SerializeTo
  // А полученный бинарник уже подключать через $resource
  var code := new CLProgramCode(
    System.IO.StreamReader.Create(
      System.Reflection.Assembly.GetCallingAssembly.GetManifestResourceStream('MatrMlt.cl')
    ).ReadToEnd
  );
  
  // Подготовка параметров
  
  'Матрица A:'.Println;
  var A_Matr := MatrRandomReal(W,W,0,1).Println;
  Println;
  var A := new CLArray<real>(W*W);
  
  'Матрица B:'.Println;
  var B_Mart := MatrRandomReal(W,W,0,1).Println;
  Println;
  var B := new CLArray<real>(W*W);
  
  var C := new CLArray<real>(W*W);
  
  'Вектор V1:'.Println;
  var V1_Arr := ArrRandomReal(W);
  V1_Arr.Println;
  Println;
  var V1 := new CLArray<real>(W);
  
  var V2 := new CLArray<real>(W);
  
  // (запись значений в объекты CLArray - позже, в очередях)
  
  // Подготовка очередей выполнения
  
  var Calc_C_Q :=
    // Можно передавать результаты .ThenWriteArray2
    // вместо "A" и "B" в "MatrMltMatr", но тогда
    // они будут тратить лишние ресурсы на параллельность
    A.MakeCCQ.ThenWriteArray2(A_Matr) +
    B.MakeCCQ.ThenWriteArray2(B_Mart) +
    // Выделяем ядра в форме квадрата, всего W*W ядер
    code['MatrMltMatr'].MakeCCQ.ThenExec2(W, W,
      A, B, C, W
    // .DiscardResult не обязателен, но желателен
    // чтобы не использовать результат случайно
    ).DiscardResult;
  
  var Otp_C_Q :=
    C.MakeCCQ.ThenGetArray2(W, W)
    .ThenUse(C_Matr->
    begin
      'Матрица С = A*B:'.Println;
      C_Matr.Println;
      Println;
    end, false).DiscardResult;
  
  var Calc_V2_Q :=
    V1.MakeCCQ.ThenWriteArray(V1_Arr) +
    code['MatrMltVec'].MakeCCQ.ThenExec1(W,
      C, V1, V2, W
    ).DiscardResult;
  
  var Otp_V2_Q :=
    V2.MakeCCQ.ThenGetArray
    .ThenUse(V2_Arr->
    begin
      'Вектор V2 = C*V1:'.Println;
      V2_Arr.Println;
      Println;
    // Единственный .DiscardResult, меняющий поведение очереди:
    // С ним не выделяются ресурсы на передачу V2_Arr
    // Из результата .ThenGetArray1 в результат SyncInvoke
    end, false).DiscardResult;
  
  // Выполнение всего и сразу асинхронный вывод
  
  CLContext.Default.SyncInvoke(
    
    Calc_C_Q +
    // Считать V2 и выводить C можно одновременно,
    // поэтому тут *, т.е. параллельное выполнение
    Calc_V2_Q * Otp_C_Q +
    Otp_V2_Q
    
  );
  
  // Освобождение памяти
  
  A.Dispose;
  B.Dispose;
  C.Dispose;
  V1.Dispose;
  V2.Dispose;
except
  // except позволяет получать список ошибок,
  // возникших при выполнении SyncInvoke
  on ae: System.AggregateException do
    foreach var e in ae.InnerExceptions do
      Println(e);
end;