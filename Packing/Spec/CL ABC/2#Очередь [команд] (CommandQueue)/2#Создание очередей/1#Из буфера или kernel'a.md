


Самый просто способ создать очередь — выбрать объект типа `Buffer` или `Kernel` и вызвать для него метод `.NewQueue`.

Полученная очередь будет иметь особый тип `BufferCommandQueue``KernelCommandQueue` для буфераkernel'а соответственно.
К такой очереди можно добавлять команды, вызывая её методы, имена которых начинаются с `.Add...`.

К примеру
```
uses OpenCLABC;

begin
   Буфер достаточного размера чтоб содержать 3 значения типа integer
  var b = new Buffer( 3sizeof(integer) );
  
   Создаём очередь
  var q = b.NewQueue;
  
   Добавлять команды в полученную очередь можно вызывая соответствующие методы
  q.AddWriteValue(1, 0sizeof(integer) );
  
   Методы, добавляющие команду в очередь - возвращают очередь, для которой их вызвали (не копию а ссылку на оригинал)
   Поэтому можно добавлять по несколько команд в 1 строчке
  q.AddWriteValue(5, 1sizeof(integer) ).AddWriteValue(7, 2sizeof(integer) );
   Все команды в q будут выполнятся последовательно, что не всегда хорошо
   Если надо выполнять параллельно - создавайте несколько b.NewQueue и умножайте друг на друга
  
   В данной версии надо писать as CommandQueue... при использовании [BufferKernel]CommandQueue там,
   где принимает CommandQueue..., из за бага компилятора #1981
  Context.Default.SyncInvoke(q as CommandQueueBuffer);
  
   Вообще чтение тоже надо делать через очереди, но для простого примера - и неявные очереди подходят
  b.GetArray1&integer(3).Println;
  
end.
```

Также, очереди `BufferCommandQueue``KernelCommandQueue` можно создавать из очередей, возвращающих `Buffer``Kernel` соответственно. Для этого используется конструктор
```
var q0 CommandQueueBuffer;
...
var q = new BufferCommandQueue(q0);
```


