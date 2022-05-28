## uses OpenCLABC;

// Чтение и компиляция .cl файла

var prog := new CLProgramCode(ReadAllText('SimpleAddition.cl'));

// Подготовка параметров

var A := new CLArray<integer>(10);

// Выполнение

prog['TEST'].Exec1(10, // Используем 10 ядер
  
  // Заполняем весь массив значениями (1), прямо перед выполнением
  A.MakeCCQ.ThenFillValue(1)
  
);

// Чтение и вывод результата

A.GetArray.Println; // Читаем всё содержимое как одномерный массив