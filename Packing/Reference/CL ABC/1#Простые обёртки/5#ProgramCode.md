﻿


Обычные программы невозможно запустить на GPU. Для этого надо писать особые программы.\
В контексте OpenCL - эти программы обычно пишутся на языке "OpenCL C" (основанном на языке "C").

Язык OpenCL-C это часть библиотеки OpenCL, поэтому его справку можно найти [там же](https://www.khronos.org/registry/OpenCL/), где и справку OpenCL.

В `OpenCLABC` OpenCL-C код хранится в объектах типа `ProgramCode`.\
Объекты этого типа используются только как контейнеры.
Один объект ProgramCode может содержать любое количествово подпрограмм-kernel'ов.

---

Самый простой способ создать `ProgramCode` - конструктором:
```
var code := new ProgramCode(
	ReadAllText('file with code 1.cl'),
	ReadAllText('file with code 2.cl')
);
```
**Внимание**! Этот конструктор принимает именно тексты исходников, не имена файлов.\
Если надо передать текст из файла - его надо сначала явно прочитать.

---

Так же как исходники паскаля хранят в .pas файлах, исходники OpenCL-C кода хранят в .cl файлах.

На самом деле это не обязательно, потому что код даже не обязан быть в файле:
```
var code_text := '__kernel void k() {}';
var code := new ProgramCode(code_text);
```
Так как конструктор `ProgramCode` принимает текст - исходники программы
на языке OpenCL-C можно хранить даже в строке в .pas программе.

Тем не менее, хранить исходники OpenCL-C кода в .cl файлах обычно удобнее всего.

---

После создания объекта типа `ProgramCode` из исходников можно вызвать
метод `ProgramCode.SerializeTo`, чтобы сохранить код в бинарном и прекомпилированном виде.

Затем, объект `ProgramCode` можно пере-создать статический метод `ProgramCode.DeserializeFrom`.

Пример можно найти в папке примеров `Прекомпиляция ProgramCode` или [тут](https://github.com/SunSerega/POCGL/tree/master/Samples/OpenCLABC/Прекомпиляция%20ProgramCode).


