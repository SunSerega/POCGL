


Иногда между командами для GPU надо вставить выполнение обычного кода на CPU.
А разрывать для этого очередь на две части - плохо, потому что
одна целая очередь всегда выполнится быстрее двух её частей.

Поэтому существует множество типов очередей, хранящих обычный код для CPU.

---

Чтобы создать самую простую такую очередь используются глобальные подпрограммы `HFQ` и `HPQ`:

HFQ — Host Function Queue\
HPQ — Host Procedure Queue\
(Хост в контексте OpenCL - это CPU, потому что с него посылаются команды для GPU)

Они возвращают очередь, выполняющую код (функцию/процедуру соотвественно) на CPU.\
Пример применения приведён <a path="../Возвращаемое значение очередей/"> на странице выше</a>.

---

Так же бывает нужно использовать результат предыдущей очереди в коде на CPU.
Для этого используются методы `.ThenUse` и `.ThenConvert`:
```
## uses OpenCLABC;
var Q := HFQ(()->5);

Context.Default.SyncInvoke(Q
  .ThenUse(x->Println($'x*2 = {x*2}'))
  .ThenConvert(x->$'x^2 = {x**2}')
).Println;
```
`.ThenUse` дублирует возвращаемое значение предыдущей очереди (`Q` в примере).\
А `.ThenConvert` возвращает результат выполнения переданной функции, как и `HFQ`.

---

`OpenCLABC` очереди существуют чтобы можно было удобно описывать параллельные процедуры.
Поэтому, с расчётом на параллельность, обычные очереди с кодом для CPU создают себе по одному потоку выполнения (`Thread`) при запуске.

Этот поток выполнения запускается до выхода из `Context.BeginInvoke` и остаётся в режиме ожидая.\
Но даже если игнорировать затраты на запуск потока, выход из режима ожидания это не моментальня операция.

Если надо выполнить очень простое действие, как в последнем примере выше, эти затраты неоправданны.\
Для таких случаев используется `Quick` версии очередей:
```
## uses OpenCLABC;
var Q := HFQQ(()->5);

Context.Default.SyncInvoke(Q
  .ThenQuickUse(x->Println($'x*2 = {x*2}'))
  .ThenQuickConvert(x->$'x^2 = {x**2}')
).Println;
```
В отличии от предыдущего примера, в данном будет создан только один поток выполнения (его всегда создаёт `Context.BeginInvoke`).

В общем случае `Quick` очереди стараются выполняться на одном из уже существующих потоков выполнения, но так чтобы не нарушать порядок выполнения очередей.

В случае `HFQ` и `HPQ`, их `Quick` варианты это `HFQQ` и `HPQQ` соответственно.

---

Если вам необходимо быстро преобразовать тип возвращаемого значения очереди - можно использовать `.ThenQuickConvert`:
```
## uses OpenCLABC;
var Q := HFQQ(()->1 as object);

Context.Default.SyncInvoke(
  Q.ThenQuickConvert(x->integer(x))
).Println;
```
Но в `OpenCLABC` для случая простого преобразования существует особо-оптимизированный метод `.Cast`.\
Он ограничен примерно так же, как метод последовательностей `.Cast`. То есть:
```
uses OpenCLABC;

type t1 = class end;
type t2 = class(t1) end;

begin
  var Q1: CommandQueue<integer> := 5;
  var Q2: CommandQueueBase := Q1;
  var Q3: CommandQueue<t1> := (new t2) as t1;
  var Q4: CommandQueue<t1> := new t1;
  var Q5: CommandQueue<t2> := new t2;
  
  // Можно, потому что к object можно преобразовать всё
  Context.Default.SyncInvoke( Q1.Cast&<object> );
  
  //Ошибка: .Cast не может преобразовывать integer в byte
  // Преобразование записей меняет представление данных в памяти
  // Можно преобразовывать только object в запись и назад
//  Context.Default.SyncInvoke( Q1.Cast&<byte> );
  
  // Можно, Q2 и так имеет тип CommandQueue<integer>,
  // а значит тут Cast вернёт (Q2 as CommandQueue<integer>)
  Context.Default.SyncInvoke( Q2.Cast&<integer> );
  
  // Можно, потому что Q3 возвращает t2
  Context.Default.SyncInvoke( Q3.Cast&<t2> );
  
  //Ошибка: Не удалось привести тип объекта "t1" к типу "t2".
  // Q4 возвращает не t2 а именно t1
//  Context.Default.SyncInvoke( Q4.Cast&<t2>.HandleDefaultRes(e->e.Message.Println<>nil, new t2) );
  
  // Можно, потому что t2 наследует от t1
  Context.Default.SyncInvoke( Q5.Cast&<t1> );
  
end.
```
Кроме того, `.Cast` можно применять к очередям без типа результата:
```
## uses OpenCLABC;

var Q1 := HPQQ(()->begin end);
var Q2 := HFQQ(()->5) as CommandQueueBase;

// .Cast применимо к CommandQueueNil, но результат будет всегда nil
Writeln( Context.Default.SyncInvoke(Q1.Cast&<object>) );
// .Cast применимо и к CommandQueueBase
Writeln( Context.Default.SyncInvoke(Q2.Cast&<object>) );
```
Ближайшей альтернативой к вызову `CommandQueueBase.Cast` будет вызов `.ConvertTyped` - но для этого надо на много больше кода.

---

Основная оптимизация `.Cast` состоит в том, что преобразование не выполняется, если возможно.
Но будьте осторожны, в некоторых случаях такая оптимизация приглушит ошибку:
```
uses OpenCLABC;

type t1 = class end;
type t2 = class(t1) end;

begin
  Context.Default.SyncInvoke( HFQ(()->new t1).Cast&<t2>.Cast&<t1> );
end.
```
Преобразование в `t2` не выполняется из-за следующего `.Cast`, поэтому
проверяется только преобразование `defalt(t1)` к `t2` (во время создания очереди) - а оно допустимое.


