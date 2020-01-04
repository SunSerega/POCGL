uses OpenCLABC;

begin
  
  // проще всего напрямую читать текст исходника из файла:
//  var code_text := ReadAllText('0.cl');
  
  // но лучше добавить .cl файл внутрь .exe и загружать оттуда:
  {$resource '0.cl'}
  var code_text := System.IO.StreamReader.Create( GetResourceStream('0.cl') ).ReadToEnd;
  // так не нужно таскать .cl файл вместе с .exe
  
  var code := new ProgramCode(code_text);
  
  var A := new Buffer( 10 * sizeof(integer) ); // буфер на 10 чисел типа "integer"
  
  // 'TEST' - имя подпрограммы-кёрнела из .cl файла. Регистр важен!
  var kernel := code['TEST'];
  
  kernel.Exec1(10, // используем 10 потоков
    
    A.NewQueue.AddFillValue(1) // заполняем весь буфер единичками, прямо перед выполнением
    as CommandQueue<Buffer> //ToDo нужно только из за issue компилятора #1981, иначе получаем странную ошибку. Когда исправят - можно будет убрать
    
  );
  
  A.GetArray1&<integer>.Println; // читаем весь буфер как одномерный массив с элементами типа "integer" и сразу выводим
  
end.