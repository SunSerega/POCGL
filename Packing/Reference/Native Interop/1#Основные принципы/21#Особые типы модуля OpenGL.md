﻿


Библиотека `OpenGL.dll` имеет несколько функций, принимающих
вектора и матрицы (в основном для передачи значений в шейдеры).

В модуле `OpenGL` для каждого типа вектора и матрицы описана отдельная запись.
Они особенны тем, что поддерживают некоторые математические операции, которые можно считать
высокоуровневыми, а значит противоречущими основным принципам н.у. модулей.

Но реализовывать их все в качестве `extensionmethod`'ов было бы сложно, не красиво,
а в случае статических методов и свойств - ещё и невозможно.

---

`ToDo` сейчас все индексные свойства кроме `.ColPtr` (`.val`, `.Row` и `.Col`) убраны из релиза,
потому что я не знаю как безопасно и эффективно их реализовывать. Постараюсь в ближайшее
время придумать, что можно сделать.

---

# Векторы

Все типы векторов можно описать разом как `Vec[1,2,3,4][ b,ub, s,us, i,ui, i64,ui64, f,d ]`.

:::spoiler { summary="Как это читать?" hidden=true }

Каждый тип вектора берёт по 1 из значений, перечисленных в `[]`, через запятую.

К примеру, есть типы `Vec2d` и `Vec4ui64`.

Число в первых скобках - значит кол-во измерений вектора.

Буква (буквы) в следующих скобках - значат тип координат вектора:

- `b=shortint`, `s=smallint`, `i=integer`, `i64=int64`: Все 4 типа - целые числа, имеющие бит знака (±) и занимающие 1, 2, 4 и 8 байт соответственно;

- Они же но с приставкой `u` - целые числа без знака. К примеру `ui` значит целое на 4 байта без знака, то есть `longword` (он же `cardinal`);

- f=`single` и d=`real` - числа с плавающей запятой, на 4 и 8 байт соответственно.

Таким образом `Vec2d` хранит 2 числа типа `real`, а `Vec4ui64` хранит 4 числа типа `uint64`.

:::

### Свойства

У векторов есть только индексное свойство `val`. Оно принимает индекс, считаемый от 0,
и возвращает или задаёт значение вектора для соответствующего измерения.

К примеру:

```
var v: Vec4d;
v[0] := 123.456; // Записываем 123.456 по индексу 0
v[1].Println; // Читаем и выводим значение по индексу 1
v.val[2] := 1; // Можно так же писать и имя свойства
```
Но использование этого свойства не рекомендуется. Прямое обращение
к полю всегда будет быстрее. То есть аналогично предыдущему коду:
```
var v: Vec4d;
v.val0 := 123.456;
v.val1.Println;
v.val2 := 1;
```

Используйте свойство `val` только тогда, когда индекс это НЕ константа.

### Унарные операторы

```
var v0: Vec3d;
...
// v1 будет иметь ту же длину, но
// противоположное v0 направление
var v1 := -v0;
// А унарный + не делает ничего, он только
// для красоты. То есть v2=v0 тут
var v2 := +v0;
```

### Умножение/деление на скаляр

```
var v1: Vec3d;
var v2: Vec3i;
...
// Выведет вектор, имеющий то же
// направление что v1, но в 2 раза длиннее
(v1*2).Println;

// Выведет вектор, имеющий то же
// направление что v1, но в 2 раза короче
(v1/2).Println;

// К целочисленным векторам вместо
// обычного деления надо применять div
(v2 div 2).Println;
```

### Операции с 2 векторами

```
var v1, v2: Vec3d;
...
// Скалярное произведение векторов
(v1*v2).Println;

// Сумма векторов, складывает
// отдельно каждый элемент вектора
(v1+v2).Println;

// Разность векторов, тоже работает
// отдельно на каждый элемент вектора
(v1-v2).Println;
```

Чтобы применить 1 из этих операций к 2 векторам - их типы должны быть одинаковые.\
Если это не так - 1 из них (или оба) надо явно преобразовать, так чтобы типы были одинаковые:
```
var v1: Vec3d;
var v2: Vec2i;
...
( v1 + Vec3d(v2) ).Println;
```

### SqrLength

Метод `.SqrLength` возвращает квадрат длины (то есть модуля) вектора.\
Возвращаемый тип `.SqrLength` совпадает с типом элементов вектора.\
Каким образом находить корень полученного значения - дело программиста.

```
var v1: Vec3d;
...
v1.SqrLength.Println; // Квадрат длины
v1.SqrLength.Sqrt.Println; // Сама длина
```

### Normalized

Метод `.Normalized` возвращает нормализированную (с длиной =1) версию вектора.\
Так как эта операция требует деления (на длину вектора), она применима только
к векторам с элементами типов `single` или `real` (`f` или `d`).

```
var v1 := new Vec3d(1,1,1);
v1.Println;
v1.SqrLength.Sqrt.Println;
var v2 := v1.Normalized;
v2.Println;
v2.SqrLength.Sqrt.Println; // Обязательно будет 1
```

### Cross

Статичные методы `.Cross[CW,CCW]` возвращают векторное произведение двух
3-х мерных векторов ("Cross product", не путать со скалярным произведением).\
Векторное произведение - это вектор, перпендикулярный обоим входным векторам и имеющий длину,
равную площади параллелограмма, образованного входными векторами.

Не работает для векторов с элементами-беззнаковыми_целыми, потому что даёт переполнение
на практически любых входных значениях. Если найдёте нормальное применение - напишите в issue.

В математике произведение векторов может вернуть один из двух противоположных друг-другу векторов,
в зависимости от ориентации системы координат. В модуле `OpenGL` это решено следующим образом:

- CW (Clockwise - по часовой стрелке):
   `Vec3d.CrossCW(new Vec3d(1,0,0), new Vec3d(0,1,0)) = new Vec3d(0,0,1)`.

- CСW (Counter-Clockwise - против часовой стрелки):
   `Vec3d.CrossCCW(a,b) = -Vec3d.CrossCW(a,b) = Vec3d.CrossCW(b,a)`;

Кроме этого, статические методы `.Cross[CW,CCW]` так же объявленны для 2D векторов.\
Для них результат является z-компонентом соответствующего метода для 3D векторов:
```
Vec2d.CrossCW(a,b) = new Vec3d(0,0,1) * Vec3d.CrossCW(Vec3d(a),Vec3d(b))
```
С другом стороны, 2D векторное произведение это определитель матрицы (не важно, по строкам или столбцам):
```
Vec2d.CrossCW(a,b) = Mtr2d.FromCols(a,b).Determinant
```

### Генерация случайных значений

Статичный метод `.Random` создаёт новый вектор из случайных значений в заданном диапазоне:
```
// Вектор будет иметь значения из [0;1)
Vec2d.Random(0,1).Println;
```

### Ввод с клавиатуры

Статичные методы `Read` и `Readln` создают новый вектор из элементов, прочитанных из стандартного ввода:
```
// Прочитать 2 числа из ввода
Vec2d.Read('Введите 2 координаты:').Println;

// Прочитать 2 числа из ввода
// и затем пропустить всё до конца строки
Vec2d.Readln.Println;
```

### Превращение в строку

```
var v1: Vec4d;
...
v1.Println; // Вывод вектора
// s присвоит ту же строку, что выводит .Println
var s := v1.ToString;
```
Методы `.ToString` и `.Println` должны быть использованы
только для чего то вроде дебага или красивого вывода,
потому что операции со строками это в целом медленно.

---

# Матрицы

Все типы матриц можно описать разом как `Mtr[2,3,4]x[2,3,4][f,d]`.

У каждой квадратной матрицы есть короткий синоним.\
К примеру вместо `Mtr3x3d` можно писать `Mtr3d`.

Так же стоит заметить - конструктор матрицы принимает элементы по строкам,
но в самой матрице элементы хранятся в транспонированном виде.

Это потому, что в `OpenGL.dll` в шейдерах матрицы хранятся по столбцам.\
Но если создавать матрицу конструктором - элементы удобнее передавать по строкам, вот так:
```
var m := new Mtr3d(
  1,2,3, // (1;2;3) станет нулевой строкой матрицы
  4,5,6,
  7,8,9
);
```

### Свойства

Как и у векторов, у матриц есть свойство `val`:
```
var m: Mtr4d;
m[0,0] := 123.456;
m[1,2].Println;
m.val[3,1] := 1;
```
И как и у векторов - `val` всегда медленнее прямого обращения к полям:
```
var m: Mtr4d;
m.val00 := 123.456;
m.val12.Println;
m.val31 := 1;
```

Но у матриц так же есть свойства для столбцов и строк:
```
var m: Mtr3d;
...
m.Row0.Println; // Вывод нулевой строчки в виде вектора
m.Row1 := new Vec3d(1,2,3);
m.Col2.Println;
```
И в качестве аналога `val` - строку и стобец тоже можно
получать по динамическому индексу (но, опять же, это медленнее):
```
var m: Mtr3d;
...
m.Row[0].Println;
m.Row[1] := new Vec3d(1,2,3);
m.Col[2].Println;
```

Для столбцов так же есть особые свойства, возвращающие не столбец, а его адрес в памяти:
```
var m: Mtr3d;
...
var ptr1 := m.ColPtr0;
var ptr2 := m.ColPtr[3];
```
Использовать это свойство
<a path="../Маршлинг управляемых типов/Тесты эффектов сборщика мусора">
не всегда безопасно</a>.

Оно должно быть использовано только для записей,
хранящихся на стеке или в неуправляемой памяти.

Для более безопасной альтернативы - можно использовать методы `.UseColPtr*`.

### Identity

Это тоже свойство, но статическое и применение совершенно другое:

`Identity` возвращает новую единичную матрицу. То есть матрицу, у
которой главная диагональ заполнена 1, а всё останое заполнено 0.
```
Mtr3d.Identity.Println;
// Работает и для не_квадратных матриц
Mtr2x3d.Identity.Println;
```

### UseColPtr*

Методы `.UseColPtr*` принимают подпрограмму, принимающую
адрес определённого столбца в виде `var`-параметра.

В отличии от свойств `.ColPtr*`, методы `.UseColPtr*` безопасны для
матриц, хранящихся в экземплярах классов и статических полях:
```
uses OpenGL;

procedure p1(var v: Vec3d);
begin
  Writeln(v);
end;

function f1(var v: Vec3d): string :=
v.ToString;

begin
  var o := new class(
    m := Mtr3d.Identity
  );
  o.m.UseColPtr0(p1);
  o.m.UseColPtr1(f1).Println;
end.
```

### Scale

Статичный метод `.Scale` возвращает матрицу, при
умножении на которую вектор маштабируется в k раз.
```
var m := Mtr3d.Scale(2);
var v := new Vec3d(1,2,3);
(m*v).Println; // (2;4;6)
```

### Translate

Статичный метод `.Translate` возвращает матрицу, при
умножении на которую к вектору добавляется заданное значение.
```
var m := Mtr4d.Translate(1,2,3);

// Последний элемент должен быть 1,
// чтобы матрица из .Translate правильно работала
var v := new Vec4d(0,0,0,1);

(m*v).Println; // (1;2;3)
```

Так же есть статический метод `.TraslateTransposed`. Он возвращает
ту же матрицу что `.Translate`, но в транспонированном виде.

### 2D вращение

Группа статических методов `.Rotate[XY,YZ,ZX][cw,ccw]` возвращает матрицу вращения в определённой плоскости.

Первые скобки определяют плоскость.\
(Но у 2x2 матриц есть только XY вариант)

Вторые скобки определяют направление вращения:
- cw (clock wise): по часовой стрелке
- ccw (counter clock wise): против часовой стрелки

### 3D вращение

Группа статических методов `.Rotate3D[cw,ccw]` возвращает матрицу
вращения вокруг нормализованного 3-х мерного вектора.\
(разумеется, не существует для матриц 2x2,2x3 и 3x2)

### Det

Метод `.Det` возвращает определитель матрицы. Существует только для квадратных матриц.

### Transpose

Метод `.Transpose` возвращает транспонированную версию матрицы:
```
var m := new Mtr2x3d(
  1,2,3,
  4,5,6
);
m.Transpose.Println; // Выводит:
// 1 4
// 2 5
// 3 6
```

### Умножение матрицы и вектора

`m*v` - это обычное математическое умножение матрицы `m` и вектора `v`,
возвращающее результат после применения преобразования из `m` к `v`.

Но так же как в шейдерах - поддерживается и обратная запись:\
`v*m` это то же самое что `m.Transpose*v`.

### Умножение 2 матриц

`m1*m2` - это математическое умножение матриц `m1` и `m2`.

### Генерация случайных значений

Статичный метод `.Random` создаёт новую матрицу из случайных значений в заданном диапазоне:
```
// Матрица будет иметь значения из [0;1)
Mtr3d.Random(0,1).Println;
```

### Ввод с клавиатуры

Статичные методы `Read[,ln][Rows,Cols]` создают новую матрицу из элементов, прочитанных из стандартного ввода:
```
// Прочитать 3*4=12 элементов из ввода
// и сохранить в новую матрицу по строкам
Mtr3x4d.ReadRows('Введите 12 элементов матрицы:').Println;

// Прочитать 4 элемета из ввода, переходя на
// следущую строку ввода после чтения каждого столбца
Mtr2d.ReadlnCols(
  'Введите столбцы матрицы...',
  col -> $'Столбец #{col}:'
).Println;
```

### Превращение в строку

Как и у векторов - матрицы можно выводить и превращать в строку
```
var m: Mtr4d;
...
m.Println; // Вывод матрицы
// s присвоит ту же строку, что выводит .Println
var s := m.ToString;
```
Для того чтобы матрица выведенная 1 из этих методов выглядела красиво надо
использовать моноширный шрифт и поддерживать юникод (потому что для матриц
используются символы псевдографики).

Обычно это не проблема для `.Println`, потому что и консоль, и окно вывода в IDE имеют моноширный шрифт и поддерживают юникод.

Но если выводить на форму, то придётся специально поставить моноширный шрифт.\
А если выводить в файл, надо выбрать кодировку файла - юникод (UTF).


