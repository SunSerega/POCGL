


Объект типа `Kernel` представляет одну подпрограмму в OpenCL-C коде,
объявленную с ключевым словом `__kernel`.

---

Обычно `Kernel` создаётся через индексное свойтсво `ProgramCode`:
```
var code: ProgramCode;
...
var k := code['KernelName'];
```
Тут `'KernelName'` — имя подпрограммы-kernel'а в исходном коде (регистр важен!).

---

Так же можно получить список всех kernel'ов объекта `ProgramCode`, методом `ProgramCode.GetAllKernels`:
```
var code: ProgramCode;
...
var ks := code.GetAllKernels;
ks.PrintLines;
```


