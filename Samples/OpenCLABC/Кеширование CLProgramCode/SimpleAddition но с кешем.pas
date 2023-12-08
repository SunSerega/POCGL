## uses OpenCLABC;

function LoadCodeCached(fname: string): CLProgramCode;
begin
  var cache_fname := fname + '.cache';
  
  // Загружать уже откомпилированное бинарное представление
  // программы обычно будет быстрее, чем компилировать заново
  if FileExists(cache_fname) then
  try
    Writeln('Загрузка из кеша');
    var str := System.IO.File.OpenRead(cache_fname);
    Result := CLProgramCode.DeserializeFrom(str);
    str.Close;
    exit; // Выходим сразу, если проблем нет
  except
    on e: Exception do
    begin
      // Это стоит писать только в логи,
      // пользователю программы о таких ошибках знать не обязательно
      // Как минимум потому, что файл созданный более старой версией
      // графических драйверов - может не загружаться на более новой
      'Ошибка загрузки из кеша:'.Println;
      Println(e);
    end;
  end;
  
  Writeln('Компиляция заново');
  Result := new CLProgramCode(ReadAllText(fname));
  
  var str := System.IO.File.Create(cache_fname);
  Result.SerializeTo(str);
  str.Close;
  
end;

var code := LoadCodeCached('0.cl');

var len := 10;
var A := new CLArray<integer>(10);

code['TEST'].Exec1(len,
  A.MakeCCQ.ThenFillValue(1)
);

A.GetArray.Println;
A.Dispose;