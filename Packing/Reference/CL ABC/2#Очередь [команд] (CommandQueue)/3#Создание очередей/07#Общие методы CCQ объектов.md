


Между командами в `CCQ` очередях бывает надо вставить выполнение другой очереди или кода для CPU.

Это можно сделать, используя несколько `.NewQueue`:
```
var s: MemorySegment;
var q0: CommandQueueBase;
...
var q :=
  s.NewQueue.ThenWriteValue(...) +
  
  q0 +
  HPQ(...) +
  HPQQ(...) +
  
  s.NewQueue.ThenWriteValue(...)
;
```
Однако можно сделать и красивее:
```
var s: MemorySegment;
var q0: CommandQueueBase;
...
var q := s.NewQueue
  .ThenWriteValue(...)
  
  .ThenQueue(q0)
  .ThenProc(...)
  .ThenQuickProc(...)
  
  .ThenWriteValue(...)
;
```
(На самом деле процедура передаваемая в `.ThenProc`'а принимает исходную простую обёртку параметром, что делает его более похожим на `.ThenUse`, чем `HPQ`)

Эти методы не имеют незаменимых применений, но позволяют сделать код значительно читабельнее.


