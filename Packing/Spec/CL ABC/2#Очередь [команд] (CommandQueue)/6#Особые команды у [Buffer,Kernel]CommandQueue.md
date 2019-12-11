


Между командами для GPU (хранимыми в очередях типов `BufferCommandQueue` и `KernelCommandQueue`)
бывает надо вставить выполнение другой очереди или кода для CPU.

Это можно сделать, используя несколько `.NewQueue`:
```
var b: Buffer;
var q0: CommandQueueBase;
...
var q :=
  b.NewQueue.AddWriteValue(...) +
  q0 +
  HPQ(...) +
  b.NewQueue.AddWriteValue(...)
;
```
Однако можно сделать и красивее:
```
var b: Buffer;
var q0: CommandQueueBase;
...
var q := b.NewQueue
  .AddWriteValue(...)
  .AddQueue(q0)
  .AddProc(...)
  .AddWriteValue(...)
;
```
Эти методы не имеют незаменимых применений, но позволяют сделать код значительно читабельнее


