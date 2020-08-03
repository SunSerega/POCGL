


Иногда между командами для GPU надо вставить выполнение обычного кода на CPU.
А разрывать для этого очередь на две части - плохо, потому что
одна целая очередь всегда выполнится быстрее двух её частей.

Для таких случае существуют глобальные подпрограммы `HFQ` и `HPQ`:

HFQ — Host Function Queue\
HPQ — Host Procedure Queue\
(Хост в контексте OpenCL - это CPU, потому что с него посылаются команды для GPU)

Они возвращают очередь, выполняющую код (функцию/процедуру соотвественно) на CPU.\
Пример применения приведён
<a path="../Возвращаемое значение очередей/">
на странице выше
</a>
.

---

Если во время выполнения очереди возникает какая-либо ошибка - весь пользовательский код,
выполняемый на CPU в этой очереди получает `ThreadAbortException`:
```
uses OpenCLABC;

begin
  var t := Context.Default.BeginInvoke(
    HPQ(()->
    begin
      try
        Sleep(1000);
      except
        on e: Exception do lock output do
        begin
          Writeln('Ошибка во время выполнения первого HPQ:');
          Writeln(e);
          Writeln;
        end;
      end;
      // Это никогда не выполнится, потому что
      // ThreadAbortException кидает себя ещё раз в конце try
      Writeln(1);
    end)
  *
    HPQ(()->
    begin
      Sleep(500);
      raise new Exception('abc');
    end)
  );
  
  try
    t.Wait;
  except
    on e: Exception do lock output do
    begin
      Writeln('Ошибка во время выполнения очереди:');
      Writeln(e);
    end;
  end;
  
end.
```
Исключение `ThreadAbortException` во многом опасно.\
Подробнее можно прочитать в [справке от microsoft](https://docs.microsoft.com/en-us/dotnet/api/system.threading.thread.abort?view=netframework-4.8).

А в кратце, если в вашем коде была кинута `ThreadAbortException` - становится очень сложно сказать что-либо о его состоянии.\
Даже потокобезопастный код, как вызов `Buffer.Dispose`, может привести к утечкам памяти, если посреди него кинут `ThreadAbortException`.

Считайте получение `ThreadAbortException` критической ошибкой, после которой очень желателен перезапуск всего .exe файла.


