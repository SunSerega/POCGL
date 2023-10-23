


Но кроме выделения памяти на GPU - OpenCL так же позволяет выделять память внутри другой области памяти.\
Для этого используется тип `MemorySubSegment`:
```
## uses OpenCLABC;

var c := Context.Default;

// Не обязательно MainDevice, можно взять любое устройство из контекста
var align := c.MainDevice.Properties.MemBaseAddrAlign;

var s := new MemorySegment(align*2, c);
// size может быть любым, но origin
// должно быть align*N, где N - целое
var s1 := new MemorySubSegment(s, 0, Min(123,align));
var s2 := new MemorySubSegment(s, align, align);

Writeln(s1);
Writeln(s2);
```


