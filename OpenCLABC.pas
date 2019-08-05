
//*****************************************************************************************************\\
// Copyright (©) Cergey Latchenko ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\
// Copyright (©) Сергей Латченко ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Этот код распространяется под Unlicense
// Для деталей смотрите в файл LICENSE или это:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\

///
/// Выскокоуровневая оболочка для модуля OpenCL
/// OpenCL и OpenCLABC можно использовать одновременно
/// Но контактировать они в основном не будут
///
/// Если чего то не хватает - писать как и для модуля OpenCL, сюда:
/// https://github.com/SunSerega/POCGL/issues
///
/// Справка данного модуля находится в начале его исходника
/// Исходники можно открывать Ctrl+кликая на любое имя из модуля (включая название модуля в "uses")
///
unit OpenCLABC;

{$region Подробное описание OpenCLABC (аля справка)}

{$region 0. Что такое OpenCLABC?}

// 
// Выскокоуровневая оболочка для модуля OpenCL
// То есть, с OpenCLABC надо на много меньше кода для больших и сложных программ
// Но такой же уровень микроконтроля как с OpenCL - недоступен
// Напримеру, на прямую управлять эвентами невозможно
// Вместо этого надо использовать операции с очередями (сложение и умножение очередей)
// 

// 
// В следующих секциях есть ссылки на примеры
// Эти примеры можно найти в папке "C:\PABCWork.NET\Samples\OpenCL\OpenCLABC\Из справки"
// А так же в соответствующей папке репозитория на гитхабе: "https://github.com/SunSerega/POCGL/tree/master/Samples/OpenCL/OpenCLABC/Из справки"
// 

{$endregion 0. Что такое OpenCLABC?}

{$region 1. Основные принципы}

// 1.0 - Термины, которые часто путают новички
// 
// Команда - запрос на выполнение чего то
//   Как запрос на запуск программы на GPU
//   Или запрос на начало чтения данных из буфера на GPU в оперативную память
//   Называть процедуры и функции командами - ошибочно
// 
// Подпрограмма - процедура или функция
// 
// Метод - особая подпрограмма, вызываемая по точке для переменной
//   К примеру, метод Context.SyncInvoke выглядит в коде как "cont.SyncInvoke(...)", где cont - переменная типа Context
// 
// Статичный метод - особый метод, который вызывается по точке для типа вместо переменной
// К примеру, статичный метод Buffer.ValueQueue выглядит в коде как "Buffer.ValueQueue(...)"
// 


// 1.1 - Контекст (Context)
// 
// Для выполнения кода необходим контекст (объект типа Context)
// Он содержит информацию о том, какое железо будет использоваться для выполнения программ и хранения содержимого буферов
// 
// Создать контекст можно конструктором ("new Context")
// Можно так же не создавать контекст, а использовать всюду Context.Default
// Изначально, этому свойству присваивается контекст, использующий 1 любой GPU (если такой есть)
// или 1 любой другой девайс, поддерживающий OpenCL (если GPU нету)
// Кроме того, Context.Default можно перезаписывать
// Это удобно, если во всей программе вы будете использовать общий контекст
// Операции, у которых не указывается контекст - всегда используют Context.Default
// 
// Для вызова команд в определённом контексте - используется метод Context.BeginInvoke
// Он возвращает объект типа Task, через который можно наблюдать за выполнением и ожидать его окончания
// Так же есть метод Context.SyncInvoke, вызывающий .BeginInvoke и затем метод Task.Wait, на полученом объекте
// 


// 1.2 - Очередь [команд] (CommandQueue)
// 
// Передавать команды в OpenCL по 1 - не эффективно
// Правильно передавать сразу по несколько команд за раз
// Для этого и существуют очереди (типы, наследующие от "CommandQueue<T>")
// Они хранят любое кол-во команд для OpenCL
// И при необходимости - части кода на паскале (HFQ, HPQ), выполняемые на хосте (на CPU)
// 
// Чтоб создать очередь - надо выбрать объект (как, Kernel или Buffer)
// У которого есть что то, что можно выполнять на GPU (как выполнение карнела или запись/чтение содержимого буфера)
// И вызвать для него метод .NewQueue
// Подробнее в примере "1.2 - Очереди\Создание очереди из буфера.pas"
// К такой очереди можно добавлять команды, вызывая её методы
// 
// Так же, создать очередь можно из функции или процедуры
// Используя глобальные подпрограммы HFQ и HPQ соответственно
// 
// Готовую очередь можно вызвать с помощью методов Context.SyncInvoke или Context.BeginInvoke
// 
// 
// 
// У очередей есть 2 оператора, сложение и умножение:
// Сложение очередей даёт последовательное выполнение
// Умножение очередей даёт параллельное выполнение
// Как и в математике, умножение имеет больший приоритет
// 
// 
// 
// При необходимости - можно посылать и по 1 команде, создавая очередь для каждой неявно
// Подробнее в примере "1.2 - Очереди\Код с очередью и без.pas"
// На это надо меньше кода, но и выполнятся это будет медленнее
// 
// 
// 
// Все методы создающие очередь (не важно явно или не явно)
// Могут принимать очередь вместо любого из параметров
// Но эта очередь должна возвращать объект того же типа, что и параметр
// Подробнее в примере "1.2 - Очереди\Использование очереди как парамметра.pas"
// 
// Если очереди A и B были переданы параметром при создании очереди C
// Очереди A и B будут выполнены паралельно друг с другом
// И прямо перед выполнением очереди C
// 
// 
// 
// Одна и та же очередь не может выполнятся в 2 местах одновременно
// Если в 2 параллельно выполняющихся местах нужна одинаковая очередь - можно клонировать её методом CommandQueue.Clone
// 


// 1.3 - Буфер (Buffer)
// 
// Программы на GPU не могут пользоваться оперативной памятью (без определённых расширений)
// Поэтому для передачи данных в такую программу и чтения результата - надо выделять память на самом GPU
// 
// Буфер создаётся через конструктор ("new Buffer(...)")
// Однако память на GPU выделяется только тогда, когда он будет первый раз изпользован для чтения/записи данных в памяти GPU
// Но если у вас первая операция это чтение - это плохо. Вы получите мусор, потому что буфер не отчищается нулями при инициализации
// 
// Буфер можно так же удалить, вызвав метод Buffer.Dispose
// Однако этот метод только освобождает память на GPU
// Если после .Dispose использовать буфер снова - память будет заново выделена
// .Dispose вызывается автоматически, если в программе не остаётся ссылок на буфер
// 


// 1.4 - Карнел (Kernel)
// (вообще, по английски правильно - кёрнел, но карн́ел легче произнести)
// 
// Обычные программы невозможно запустить на GPU
// Специальные программы для GPU запускаемые через OpenCL - пишутся на особом языке "OpenCL C" (который основан на языке "C")
// Его описание не является частью данной справки
// Максимум что вы можете найти тут - ссылку на 1 из последних версий его спецификации:
// https://www.khronos.org/registry/OpenCL/specs/2.2/pdf/OpenCL_C.pdf
// 
// Для создания объекта типа Kernel - надо сначала иметь объект типа ProgramCode
// Он содержит откомпилированные исходники программы
// Делается это обычным конструктором ("new ProgramCode(...)")
// Далее - можно воспользоваться индексным свойство:
// "code['TestKernel1']", где code имеет тип ProgramCode - вернёт объект типа Kernel
// 'TestKernel1' это имя подпрограммы, содержащейся в code и объявленной там карнелом (регистр важен!)
// См. пример "1.4 - Карнел\Вызов карнела.pas"
// 

{$endregion 1. Основные принципы}

{$region 2. Структура модуля}

// 

{$endregion 2. Структура модуля}

{$endregion Подробное описание OpenCLABC (аля справка)}

interface

uses OpenCL;
uses System;
uses System.Threading.Tasks;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

//ToDo клонирование очередей
// - для паралельного выполнения из разных потоков

//ToDo Buffer.WriteValue принимающее очередь
// - иначе не работает пример "1.2 : Использование очереди как параметра"

//ToDo написать в справке про CommandQueue.ThenConvert

//ToDo объяснить в справке как выполняется очередь с параметрами-очередями
// - параметр всегда выполняются перед своей командой
// - параметры 1 команды выполняются паралельно с параметрами другой команды

//===================================

//ToDo перенести CommandQueueHostFunc в implementation

//ToDo BufferCommandQueue.AddQueue

//ToDo агресивный инлайнинг функций, принимающий произвольную запись
// - иначе для больших записей - будет бить по производительности

//ToDo CommandQueue.Cycle(integer)
//ToDo CommandQueue.Cycle // бесконечность циклов
//ToDo CommandQueue.CycleWhile(***->boolean)

//ToDo CommandQueueBase.is_busy
// - И protected процедура "MakeBusy", проводящая проверку

//ToDo Типы Device и Platform
//ToDo А связь с OpenCL.pas сделать всему (и буферам и карнелам), но более человеческую

//ToDo Read/Write для массивов - надо иметь возможность указывать отступ в массиве

//ToDo Buffer.GetArray(params szs: array of CommandQueue<integer>)
// - и тогда можно будет разрешить очередь в .GetArray[1,2,3]

//ToDo У всего, у чего есть Finalize - проверить чтоб было и .Dispose, если надо
// - и добавить в справку, про то что этот объект можно удалять

//ToDo issue компилятора:
// - #1952
// - #1981
// - #2067, #2068

type
  
  {$region misc class def}
  
  Context = class;
  Buffer = class;
  Kernel = class;
  ProgramCode = class;
  DeviceTypeFlags = OpenCL.DeviceTypeFlags;
  
  {$endregion misc class def}
  
  {$region CommandQueue}
  
  ///--
  CommandQueueBase = abstract class
    protected ev: cl_event;
    
    protected procedure ClearEvent :=
    if self.ev<>cl_event.Zero then cl.ReleaseEvent(self.ev).RaiseIfError;
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; abstract;
    
    protected function GetRes: object; abstract;
    
  end;
  /// Базовый тип всех очередей команд в OpenCLABC
  CommandQueue<T> = abstract class(CommandQueueBase)
    protected res: T;
    
    protected function GetRes: object; override := self.res;
    
    ///Создаёт очередь, которая выполнит данную
    ///А затем выполнит на CPU функцию f
    public function ThenConvert<T2>(f: T->T2): CommandQueue<T2>;
    
    public static function operator+<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
    public static procedure operator+=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1+q2;
    
    public static function operator*<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
    public static procedure operator*=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1*q2;
    
    public static function operator implicit(o: T): CommandQueue<T>;
    
  end;
  
  ///Обёртка для выполнения кода на хосте, то есть на CPU
  ///Которая так же является очередью, а значит совместима и со всеми остальными очередями
  CommandQueueHostFunc<T> = sealed class(CommandQueue<T>)
    private f: ()->T;
    
    ///Самый прямой и простой способ создания объекта типа CommandQueueHostFunc
    ///Но лучше используйте HFQ и HPQ, они записываются короче
    public constructor(f: ()->T) :=
    self.f := f;
    
    ///Создаёт объект CommandQueueHostFunc, который как будто уже завершил выполнятся и вернул o
    ///Вообще, это больше для внутренних вещей в OpenCLABC
    ///Любой тип T и так можно использовать там где принимает CommandQueue<T>
    ///Эта возможность как раз и реализовано через данный конструктор
    public constructor(o: T);
    begin
      self.res := o;
      self.f := nil;
    end;
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    
    ///--
    public procedure Finalize; override :=
    ClearEvent;
    
  end;
  
  {$endregion CommandQueue}
  
  {$region Buffer}
  
  ///--
  BufferCommand = abstract class
    protected ev: cl_event;
    
    protected procedure ClearEvent :=
    if self.ev<>cl_event.Zero then cl.ReleaseEvent(self.ev).RaiseIfError;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; abstract;
    
  end;
  
  ///--
  BufferCommandQueue = sealed class(CommandQueue<Buffer>)
    protected commands := new List<BufferCommand>;
    
    {$region constructor's}
    
    protected constructor(org: Buffer) :=
    self.res := org;
    
    protected function AddCommand(comm: BufferCommand): BufferCommandQueue;
    begin
      self.commands += comm;
      Result := self;
    end;
    
    {$endregion constructor's}
    
    {$region Write}
    
    ///- function WriteData(ptr: IntPtr): BufferCommandQueue;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteData(ptr: CommandQueue<IntPtr>): BufferCommandQueue;
    ///- function WriteData(ptr: IntPtr; offset, len: integer): BufferCommandQueue;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function WriteData(ptr: pointer): BufferCommandQueue;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteData(ptr: pointer) := WriteData(IntPtr(ptr));
    ///- function WriteData(ptr: pointer; offset, len: integer): BufferCommandQueue;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteData(ptr: pointer; offset, len: CommandQueue<integer>) := WriteData(IntPtr(ptr), offset, len);
    
    
    ///- function WriteArray(a: Array): BufferCommandQueue;
    ///Копирует содержимое массива в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteArray(a: CommandQueue<&Array>): BufferCommandQueue;
    ///- function WriteArray(a: Array; offset, len: integer): BufferCommandQueue;
    ///Копирует содержимое массива в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function WriteArray(a: Array): BufferCommandQueue;
    ///Копирует содержимое массива в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteArray(a: &Array) := WriteArray(new CommandQueueHostFunc<&Array>(a));
    ///- function WriteArray(a: Array; offset, len: integer): BufferCommandQueue;
    ///Копирует содержимое массива в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteArray(a: &Array; offset, len: CommandQueue<integer>) := WriteArray(new CommandQueueHostFunc&<&Array>(a), offset, len);
    
    
    ///- function WriteValue<TRecord>(val: TRecord; offset: integer := 0): BufferCommandQueue; where TRecord: record;
    ///Записывает значение любого размерного типа в данный буфер
    ///С отступом в offset байт в буфере
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    
    ///- function WriteValue<TRecord>(val: TRecord; offset: integer := 0): BufferCommandQueue; where TRecord: record;
    ///Записывает значение любого размерного типа в данный буфер
    ///С отступом в offset байт в буфере
    public function WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    
    {$endregion Write}
    
    {$region Read}
    
    ///- function ReadData(ptr: IntPtr): BufferCommandQueue;
    ///Копирует всё содержимое буффера в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: CommandQueue<IntPtr>): BufferCommandQueue;
    ///- function ReadData(ptr: IntPtr; offset, len: integer): BufferCommandQueue;
    ///Копирует len байт, начиная с байта №offset в буфере, в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function ReadData(ptr: pointer): BufferCommandQueue;
    ///Копирует всё содержимое буффера в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: pointer) := ReadData(IntPtr(ptr));
    ///- function ReadData(ptr: pointer; offset, len: integer): BufferCommandQueue;
    ///Копирует len байт, начиная с байта №offset в буфере, в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: pointer; offset, len: CommandQueue<integer>) := ReadData(IntPtr(ptr), offset, len);
    
    ///- function ReadArray(a: Array): BufferCommandQueue;
    ///Копирует всё содержимое буффера в содержимое массива
    public function ReadArray(a: CommandQueue<&Array>): BufferCommandQueue;
    ///- function ReadArray(a: Array; offset, len: integer): BufferCommandQueue;
    ///Копирует len байт, начиная с байта №offset в буфере, в содержимое массива
    public function ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function ReadArray(a: Array): BufferCommandQueue;
    ///Копирует всё содержимое буффера в содержимое массива
    public function ReadArray(a: &Array) := ReadArray(new CommandQueueHostFunc<&Array>(a));
    ///- function ReadArray(a: Array; offset, len: integer): BufferCommandQueue;
    ///Копирует len байт, начиная с байта №offset в буфере, в содержимое массива
    public function ReadArray(a: &Array; offset, len: CommandQueue<integer>) := ReadArray(new CommandQueueHostFunc&<&Array>(a), offset, len);
    
    ///- function ReadValue<TRecord>(var val: TRecord; offset: integer := 0): BufferCommandQueue; where TRecord: record;
    ///Читает значение любого размерного типа из данного буфера
    ///С отступом в offset байт в буфере
    public function ReadValue<TRecord>(var val: TRecord; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    begin
      Result := ReadData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Read}
    
    {$region Fill}
    
    ///- function PatternFill(ptr: IntPtr): BufferCommandQueue;
    ///Заполняет весь буфер копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>): BufferCommandQueue;
    ///- function PatternFill(ptr: IntPtr; offset, len: integer): BufferCommandQueue;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function PatternFill(ptr: pointer): BufferCommandQueue;
    ///Заполняет весь буфер копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: pointer; pattern_len: CommandQueue<integer>) := PatternFill(IntPtr(ptr), pattern_len);
    ///- function PatternFill(ptr: pointer; offset, len: integer): BufferCommandQueue;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: pointer; pattern_len, offset, len: CommandQueue<integer>) := PatternFill(IntPtr(ptr), pattern_len, offset, len);
    
    ///- function PatternFill(a: Array): BufferCommandQueue;
    ///Заполняет весь буфер копиями содержимого массива
    public function PatternFill(a: CommandQueue<&Array>): BufferCommandQueue;
    ///- function PatternFill(a: Array; offset, len: integer): BufferCommandQueue;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями содержимого массива
    public function PatternFill(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function PatternFill(a: Array): BufferCommandQueue;
    ///Заполняет весь буфер копиями содержимого массива
    public function PatternFill(a: &Array) := PatternFill(new CommandQueueHostFunc<&Array>(a));
    ///- function PatternFill(a: Array; offset, len: integer): BufferCommandQueue;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями содержимого массива
    public function PatternFill(a: &Array; offset, len: CommandQueue<integer>) := PatternFill(new CommandQueueHostFunc&<&Array>(a), offset, len);
    
    ///- function PatternFill<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    ///Заполняет весь буфер копиями значения любого размерного типа
    public function PatternFill<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    ///- function PatternFill<TRecord>(val: TRecord; offset, len: integer): BufferCommandQueue; where TRecord: record;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями значения любого размерного типа
    public function PatternFill<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): BufferCommandQueue; where TRecord: record;
    
    ///- function PatternFill<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    ///Заполняет весь буфер копиями значения любого размерного типа
    public function PatternFill<TRecord>(val: CommandQueue<TRecord>): BufferCommandQueue; where TRecord: record;
    ///- function PatternFill<TRecord>(val: TRecord; offset, len: integer): BufferCommandQueue; where TRecord: record;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями значения любого размерного типа
    public function PatternFill<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>): BufferCommandQueue; where TRecord: record;
    
    {$endregion Fill}
    
    {$region Copy}
    
    ///- function CopyFrom(b: Buffer; from, &to, len: integer): BufferCommandQueue;
    ///Копирует содержимое буфера b в данный буфер
    ///from - отступ в буффере b
    ///to   - отступ в данном буффере
    ///len  - кол-во копируемых байт
    public function CopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): BufferCommandQueue;
    ///- function CopyTo(b: Buffer; from, &to, len: integer): BufferCommandQueue;
    ///Копирует содержимое данного буфера в буфер b
    ///from - отступ в данном буффере
    ///to   - отступ в буффере b
    ///len  - кол-во копируемых байт
    public function CopyTo  (b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): BufferCommandQueue;
    
    ///- function CopyFrom(b: Buffer): BufferCommandQueue;
    ///Копирует всё содержимое буфера b в данный буфер
    public function CopyFrom(b: CommandQueue<Buffer>): BufferCommandQueue;
    ///- function CopyTo(b: Buffer): BufferCommandQueue;
    ///Копирует всё содержимое данного буфера в буфер b
    public function CopyTo  (b: CommandQueue<Buffer>): BufferCommandQueue;
    
    {$endregion Copy}
    
    {$region reintroduce методы}
    
    private function Equals(obj: object): boolean; reintroduce := false;
    
    private function ToString: string; reintroduce := nil;
    
    private function GetType: System.Type; reintroduce := nil;
    
    private function GetHashCode: integer; reintroduce := 0;
    
    {$endregion reintroduce методы}
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      
      foreach var comm in commands do
      begin
        yield sequence comm.Invoke(res, c, cq, prev_ev);
        prev_ev := comm.ev;
      end;
      
      self.ev := prev_ev;
    end;
    
  end;
  
  ///Буфер, хранящий своё содержимое в памяти GPU (обычно)
  ///Используется для передачи данных в Kernel-ы перед их выполнением
  Buffer = sealed class(IDisposable)
    private memobj: cl_mem;
    private sz: UIntPtr;
    private _parent: Buffer;
    
    {$region constructor's}
    
    private constructor := raise new System.NotSupportedException;
    
    ///Создаён не_инициализированный буфер с размером size байт
    public constructor(size: UIntPtr) := self.sz := size;
    ///Создаён не_инициализированный буфер с размером size байт
    public constructor(size: integer) := Create(new UIntPtr(size));
    ///Создаён не_инициализированный буфер с размером size байт
    public constructor(size: int64)   := Create(new UIntPtr(size));
    
    ///Создаёт под-буфер размера size и с отступом в данном буфере offset
    ///Под буфер имеет общую память с оригинальным, но иммеет доступ только к её части
    public function SubBuff(offset, size: integer): Buffer; 
    
    ///Инициализирует буфер, выделяя память на девайсе - который связан с данным контекстом
    public procedure Init(c: Context);
    
    {$endregion constructor's}
    
    {$region property's}
    
    ///Возвращает размер буфера в байтах
    public property Size: UIntPtr read sz;
    ///Возвращает размер буфера в байтах
    public property Size32: UInt32 read sz.ToUInt32;
    ///Возвращает размер буфера в байтах
    public property Size64: UInt64 read sz.ToUInt64;
    
    ///Если данный буфер был создан функцией SubBuff - возвращает родительский буфер
    ///Иначе возвращает nil
    public property Parent: Buffer read _parent;
    
    {$endregion property's}
    
    {$region Queue's}
    
    ///Создаёт новую очередь-обёртку данного буфера
    ///Которая может хранить множество операций чтения/записи одновременно
    public function NewQueue :=
    new BufferCommandQueue(self);
    
    /// - static function ValueQueue<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    ///Создаёт новый буфер того же размера что и val, оборачивает в очередь
    ///И вызывает у полученной очереди .WriteValue(val)
    public static function ValueQueue<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    begin
      Result := 
        Buffer.Create(Marshal.SizeOf&<TRecord>)
        .NewQueue.WriteValue(val);
    end;
    
    {$endregion Queue's}
    
    {$region Write}
    
    ///- function WriteData(ptr: IntPtr): Buffer;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteData(ptr: CommandQueue<IntPtr>): Buffer;
    ///- function WriteData(ptr: IntPtr; offset, len: integer): Buffer;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function WriteData(ptr: pointer): Buffer;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteData(ptr: pointer) := WriteData(IntPtr(ptr));
    ///- function WriteData(ptr: pointer; offset, len: integer): Buffer;
    ///Копирует область оперативной памяти, на которую ссылается ptr, в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteData(ptr: pointer; offset, len: CommandQueue<integer>) := WriteData(IntPtr(ptr), offset, len);
    
    ///- function WriteArray(a: Array): Buffer;
    ///Копирует содержимое массива в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteArray(a: CommandQueue<&Array>): Buffer;
    ///- function WriteArray(a: Array; offset, len: integer): Buffer;
    ///Копирует содержимое массива в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function WriteArray(a: Array): Buffer;
    ///Копирует содержимое массива в данный буфер
    ///Копируется нужное кол-во байт чтоб заполнить весь буфер
    public function WriteArray(a: &Array) := WriteArray(new CommandQueueHostFunc<&Array>(a));
    ///- function WriteArray(a: Array; offset, len: integer): Buffer;
    ///Копирует содержимое массива в данный буфер
    ///offset это отступ в буфере, а len - кол-во копируемых байтов
    public function WriteArray(a: &Array; offset, len: CommandQueue<integer>) := WriteArray(new CommandQueueHostFunc<&Array>(a), offset,len);
    
    ///- function WriteValue<TRecord>(val: TRecord; offset: integer := 0): Buffer; where TRecord: record;
    ///Записывает значение любого размерного типа в данный буфер
    ///С отступом в offset байт в буфере
    public function WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    begin
      Result := WriteData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Write}
    
    {$region Read}
    
    ///- function ReadData(ptr: IntPtr): Buffer;
    ///Копирует всё содержимое буффера в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: CommandQueue<IntPtr>): Buffer;
    ///- function ReadData(ptr: IntPtr; offset, len: integer): Buffer;
    ///Копирует len байт, начиная с байта №offset в буфере, в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function ReadData(ptr: pointer): Buffer;
    ///Копирует всё содержимое буффера в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: pointer) := ReadData(IntPtr(ptr));
    ///- function ReadData(ptr: pointer; offset, len: integer): Buffer;
    ///Копирует len байт, начиная с байта №offset в буфере, в область оперативной памяти, на которую указывает ptr
    public function ReadData(ptr: pointer; offset, len: CommandQueue<integer>) := ReadData(IntPtr(ptr), offset, len);
    
    ///- function ReadArray(a: Array): Buffer;
    ///Копирует всё содержимое буффера в содержимое массива
    public function ReadArray(a: CommandQueue<&Array>): Buffer;
    ///- function ReadArray(a: Array; offset, len: integer): Buffer;
    ///Копирует len байт, начиная с байта №offset в буфере, в содержимое массива
    public function ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    ///- function ReadArray(a: Array): Buffer;
    ///Копирует всё содержимое буффера в содержимое массива
    public function ReadArray(a: &Array) := ReadArray(new CommandQueueHostFunc<&Array>(a));
    ///- function ReadArray(a: Array; offset, len: integer): Buffer;
    ///Копирует len байт, начиная с байта №offset в буфере, в содержимое массива
    public function ReadArray(a: &Array; offset, len: CommandQueue<integer>) := ReadArray(new CommandQueueHostFunc<&Array>(a), offset,len);
    
    ///- function ReadValue<TRecord>(var val: TRecord; offset: integer := 0): Buffer; where TRecord: record;
    ///Читает значение любого размерного типа из данного буфера
    ///С отступом в offset байт в буфере
    public function ReadValue<TRecord>(var val: TRecord; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    begin
      Result := ReadData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Read}
    
    {$region Get}
    
    ///- function GetData(offset, len: integer): IntPtr;
    ///Выделяет неуправляемую область в памяти
    ///И копирует в неё len байт из данного буфера, начиная с байта №offset
    ///Обязательно вызовите Marshal.FreeHGlobal на полученном дескрипторе, после использования
    public function GetData(offset, len: CommandQueue<integer>): IntPtr;
    ///- function GetData: IntPtr;
    ///Выделяет неуправляемую область в памяти, одинакового размера с данным буфером
    ///И копирует в неё всё содержимое данного буфера
    ///Обязательно вызовите Marshal.FreeHGlobal на полученном дескрипторе, после использования
    public function GetData := GetData(0,integer(self.Size32));
    
    ///- function GetArrayAt<TArray>(offset: integer; params szs: array of integer): TArray; where TArray: &Array;
    ///Создаёт новый массив с размерностями szs
    ///И копирует в него, начиная с байта offset, достаточно байт чтоб заполнить весь массив
    public function GetArrayAt<TArray>(offset: CommandQueue<integer>; szs: CommandQueue<array of integer>): TArray; where TArray: &Array;
    ///- function GetArray<TArray>(params szs: array of integer): TArray; where TArray: &Array;
    ///Создаёт новый массив с размерностями szs
    ///И копирует в него достаточно байт чтоб заполнить весь массив
    public function GetArray<TArray>(szs: CommandQueue<array of integer>): TArray; where TArray: &Array; begin Result := GetArrayAt&<TArray>(0, szs); end;
    
    ///- function GetArrayAt<TArray>(offset: integer; params szs: array of integer): TArray; where TArray: &Array;
    ///Создаёт новый массив с размерностями szs
    ///И копирует в него, начиная с байта offset, достаточно байт чтоб заполнить весь массив
    public function GetArrayAt<TArray>(offset: CommandQueue<integer>; params szs: array of integer): TArray; where TArray: &Array;
    begin Result := GetArrayAt&<TArray>(offset, new CommandQueueHostFunc<array of integer>(szs)); end;
    ///- function GetArray<TArray>(params szs: array of integer): TArray; where TArray: &Array;
    ///Создаёт новый массив с размерностями szs
    ///И копирует в него достаточно байт чтоб заполнить весь массив
    public function GetArray<TArray>(params szs: array of integer): TArray; where TArray: &Array;
    begin Result := GetArrayAt&<TArray>(0, new CommandQueueHostFunc<array of integer>(szs)); end;
    
    ///- function GetArray1At<TRecord>(offset: integer; length: integer): array of TRecord; where TRecord: record;
    ///Создаёт новый 1-мерный массив, с length элементами типа TRecord
    ///И копирует в него, начиная с байта offset, достаточно байт чтоб заполнить весь массив
    public function GetArray1At<TRecord>(offset: CommandQueue<integer>; length: integer): array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(offset, length); end;
    ///- function GetArray1<TRecord>(length: integer): array of TRecord; where TRecord: record;
    ///Создаёт новый 1-мерный массив, с length элементами типа TRecord
    ///И копирует в него достаточно байт чтоб заполнить весь массив
    public function GetArray1<TRecord>(length: integer): array of TRecord; where TRecord: record;
    begin Result := GetArray&<array of TRecord>(length); end;
    
    ///- function GetArray2At<TRecord>(offset: integer; length: integer): array[,] of TRecord; where TRecord: record;
    ///Создаёт новый 2-мерный массив, с length элементами типа TRecord
    ///И копирует в него, начиная с байта offset, достаточно байт чтоб заполнить весь массив
    public function GetArray2At<TRecord>(offset: CommandQueue<integer>; length1, length2: integer): array[,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,] of TRecord>(offset, length1, length2); end;
    ///- function GetArray2<TRecord>(length: integer): array of TRecord; where TRecord: record;
    ///Создаёт новый 2-мерный массив, с length элементами типа TRecord
    ///И копирует в него достаточно байт чтоб заполнить весь массив
    public function GetArray2<TRecord>(length1, length2: integer): array[,] of TRecord; where TRecord: record;
    begin Result := GetArray&<array[,] of TRecord>(length1, length2); end;
    
    ///- function GetArray3At<TRecord>(offset: integer; length: integer): array[,,] of TRecord; where TRecord: record;
    ///Создаёт новый 3-мерный массив, с length элементами типа TRecord
    ///И копирует в него, начиная с байта offset, достаточно байт чтоб заполнить весь массив
    public function GetArray3At<TRecord>(offset: CommandQueue<integer>; length1, length2, length3: integer): array[,,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,,] of TRecord>(offset, length1, length2, length3); end;
    ///- function GetArray3<TRecord>(length: integer): array[,,] of TRecord; where TRecord: record;
    ///Создаёт новый 3-мерный массив, с length элементами типа TRecord
    ///И копирует в него достаточно байт чтоб заполнить весь массив
    public function GetArray3<TRecord>(length1, length2, length3: integer): array[,,] of TRecord; where TRecord: record;
    begin Result := GetArray&<array[,,] of TRecord>(length1, length2, length3); end;
    
    ///- function GetValueAt<TRecord>(offset: integer): TRecord; where TRecord: record;
    ///Читает значение любого размерного типа из данного буфера
    ///С отступом в offset байт в буфере
    public function GetValueAt<TRecord>(offset: CommandQueue<integer>): TRecord; where TRecord: record;
    ///- function GetValue<TRecord>: TRecord; where TRecord: record;
    ///Читает значение любого размерного типа из начала данного буфера
    public function GetValue<TRecord>: TRecord; where TRecord: record; begin Result := GetValueAt&<TRecord>(0); end;
    
    {$endregion Get}
    
    {$region Fill}
    
    ///Заполняет весь буфер копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>): Buffer;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>): Buffer;
    
    ///Заполняет весь буфер копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: pointer; pattern_len: CommandQueue<integer>) := PatternFill(IntPtr(ptr), pattern_len);
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями массива байт, длинной pattern_len,
    ///прочитанным из области оперативной памяти, на которую указывает ptr
    public function PatternFill(ptr: pointer; pattern_len, offset, len: CommandQueue<integer>) := PatternFill(IntPtr(ptr), pattern_len, offset, len);
    
    ///Заполняет весь буфер копиями содержимого массива
    public function PatternFill(a: CommandQueue<&Array>): Buffer;
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями содержимого массива
    public function PatternFill(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    ///Заполняет весь буфер копиями содержимого массива
    public function PatternFill(a: &Array) := PatternFill(new CommandQueueHostFunc<&Array>(a));
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями содержимого массива
    public function PatternFill(a: &Array; offset, len: CommandQueue<integer>) := PatternFill(new CommandQueueHostFunc<&Array>(a), offset,len);
    
    ///Заполняет весь буфер копиями значения любого размерного типа
    public function PatternFill<TRecord>(val: TRecord): Buffer; where TRecord: record;
    begin
      Result := PatternFill(@val, Marshal.SizeOf&<TRecord>);
    end;
    
    ///Заполняет часть буфера (начиная с байта №offset и длинной len) копиями значения любого размерного типа
    public function PatternFill<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): Buffer; where TRecord: record;
    begin
      Result := PatternFill(@val, Marshal.SizeOf&<TRecord>, offset,len);
    end;
    
    {$endregion Fill}
    
    {$region Copy}
    
    ///Копирует содержимое буфера arg в данный буфер
    ///from - отступ в буффере arg
    ///to   - отступ в данном буффере
    ///len  - кол-во копируемых байт
    public function CopyFrom(arg: Buffer; from, &to, len: CommandQueue<integer>): Buffer;
    ///Копирует содержимое данного буфера в буфер arg
    ///from - отступ в данном буффере
    ///to   - отступ в буффере arg
    ///len  - кол-во копируемых байт
    public function CopyTo  (arg: Buffer; from, &to, len: CommandQueue<integer>): Buffer;
    
    ///Копирует всё содержимое буфера arg в данный буфер
    public function CopyFrom(arg: Buffer): Buffer;
    ///Копирует всё содержимое данного буфера в буфер arg
    public function CopyTo  (arg: Buffer): Buffer;
    
    {$endregion Copy}
    
    ///Высвобождает выделенную на GPU память
    ///Если такой нету - не делает ничего
    ///Память будет заново выделена, если снова использовать данный буфер для чтения/записи
    public procedure Dispose :=
    if self.memobj<>cl_mem.Zero then
    begin
      cl.ReleaseMemObject(memobj);
      memobj := cl_mem.Zero;
    end;
    
    ///--
    public procedure Finalize; override :=
    if self.memobj<>cl_mem.Zero then cl.ReleaseMemObject(self.memobj);
    
  end;
  
  {$endregion Buffer}
  
  {$region Kernel}
  
  ///--
  KernelCommand = class
    protected ev: cl_event;
    
    protected procedure ClearEvent :=
    if self.ev<>cl_event.Zero then cl.ReleaseEvent(self.ev).RaiseIfError;
    
    protected function Invoke(k: Kernel; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; abstract;
    
  end;
  
  ///--
  KernelCommandQueue = class(CommandQueue<Kernel>)
    protected commands := new List<KernelCommand>;
    
    {$region constructor's}
    
    protected constructor(org: Kernel) :=
    self.res := org;
    
    protected function AddCommand(comm: KernelCommand): KernelCommandQueue;
    begin
      self.commands += comm;
      Result := self;
    end;
    
    {$endregion constructor's}
    
    {$region AddQueue}
    
    public function AddQueue<T>(q: CommandQueue<T>): KernelCommandQueue;
    
    {$endregion AddQueue}
    
    {$region Exec}
    
    public function Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function Exec(work_szs: array of integer; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function Exec1(work_sz1: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1), args);
    public function Exec1(work_sz1: integer; params args: array of CommandQueue<Buffer>) := Exec1(new UIntPtr(work_sz1), args);
    
    public function Exec2(work_sz1, work_sz2: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1, work_sz2), args);
    public function Exec2(work_sz1, work_sz2: integer; params args: array of CommandQueue<Buffer>) := Exec2(new UIntPtr(work_sz1), new UIntPtr(work_sz2), args);
    
    public function Exec3(work_sz1, work_sz2, work_sz3: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1, work_sz2, work_sz3), args);
    public function Exec3(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<Buffer>) := Exec3(new UIntPtr(work_sz1), new UIntPtr(work_sz2), new UIntPtr(work_sz3), args);
    
    
    public function Exec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function Exec(work_szs: array of CommandQueue<integer>; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz_q->sz_q.ThenConvert(sz->new UIntPtr(sz))), args);
    
    public function Exec1(work_sz1: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1), args);
    public function Exec1(work_sz1: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec1(work_sz1.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function Exec2(work_sz1, work_sz2: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2), args);
    public function Exec2(work_sz1, work_sz2: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec2(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function Exec3(work_sz1, work_sz2, work_sz3: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2, work_sz3), args);
    public function Exec3(work_sz1, work_sz2, work_sz3: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec3(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), work_sz3.ThenConvert(sz->new UIntPtr(sz)), args);
    
    
    //ToDo наверное, надо сделать дополнительный тип команд - типа HFQ
    // - состоящий из очереди, выполняющейся независимо от объекта Kernel
    
    public function Exec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue := nil;
    public function Exec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>): KernelCommandQueue := nil;
    
    public function Exec(work_szs: CommandQueue<array of CommandQueue<UIntPtr>>; params args: array of CommandQueue<Buffer>): KernelCommandQueue := nil;
    public function Exec(work_szs: CommandQueue<array of CommandQueue<integer>>; params args: array of CommandQueue<Buffer>): KernelCommandQueue := nil;
    
    {$endregion Exec}
    
    {$region reintroduce методы}
    
    private function Equals(obj: object): boolean; reintroduce := false;
    
    private function ToString: string; reintroduce := nil;
    
    private function GetType: System.Type; reintroduce := nil;
    
    private function GetHashCode: integer; reintroduce := 0;
    
    {$endregion reintroduce методы}
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      
      foreach var comm in commands do
      begin
        yield sequence comm.Invoke(res, c, cq, prev_ev);
        prev_ev := comm.ev;
      end;
      
      self.ev := prev_ev;
    end;
    
  end;
  
  Kernel = sealed class
    private _kernel: cl_kernel;
    
    {$region constructor's}
    
    private constructor := raise new System.NotSupportedException;
    
    public constructor(prog: ProgramCode; name: string);
    
    {$endregion constructor's}
    
    {$region Queue's}
    
    public function NewQueue :=
    new KernelCommandQueue(self);
    
    public function Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>): Kernel;
    
    public function Exec(work_szs: array of integer; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function Exec(work_sz1: integer; params args: array of CommandQueue<Buffer>) := Exec(new integer[](work_sz1), args);
    public function Exec(work_sz1, work_sz2: integer; params args: array of CommandQueue<Buffer>) := Exec(new integer[](work_sz1, work_sz2), args);
    public function Exec(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<Buffer>) := Exec(new integer[](work_sz1, work_sz2, work_sz3), args);
    
    {$endregion Queue's}
    
    public procedure Finalize; override :=
    cl.ReleaseKernel(self._kernel).RaiseIfError;
    
  end;
  
  {$endregion Kernel}
  
  {$region Context}
  
  Context = sealed class
    private static _platform: cl_platform_id;
    private static _def_cont: Context;
    
    private _device: cl_device_id;
    private _context: cl_context;
    private need_finnalize := false;
    
    public static property &Default: Context read _def_cont write _def_cont;
    
    static constructor :=
    try
      
      var ec := cl.GetPlatformIDs(1,@_platform,nil);
      ec.RaiseIfError;
      
      try
        _def_cont := new Context;
      except
        _def_cont := new Context(DeviceTypeFlags.All); // если нету GPU - попытаться хотя бы для чего то его инициализировать
      end;
      
    except
      on e: Exception do
      begin
        {$reference PresentationFramework.dll}
        System.Windows.MessageBox.Show(e.ToString, 'Не удалось инициализировать OpenCL');
        Halt;
      end;
    end;
    
    /// Инициализирует новый контекст c 1 девайсом типа GPU
    public constructor := Create(DeviceTypeFlags.GPU);
    
    /// Инициализирует новый контекст c 1 девайсом типа dt
    public constructor(dt: DeviceTypeFlags);
    begin
      var ec: ErrorCode;
      
      cl.GetDeviceIDs(_platform, dt, 1, @_device, nil).RaiseIfError;
      
      _context := cl.CreateContext(nil, 1, @_device, nil, nil, @ec);
      ec.RaiseIfError;
      
      need_finnalize := true;
    end;
    
    /// Создаёт обёртку для дескриптора контекста, полученного модулем OpenCL
    /// Девайс выбирается первый попавшейся из списка связанных
    /// Автоматическое удаление контекста не произойдёт при удалении всех ссылок на полученную обёртку
    /// В отличии от создания нового контекста - контекстом управляет модуль OpenCL а не OpenCLABC
    public constructor(context: cl_context);
    begin
      
      cl.GetContextInfo(context, ContextInfoType.CL_CONTEXT_DEVICES, new UIntPtr(IntPtr.Size), @_device, nil).RaiseIfError;
      
      _context := context;
    end;
    
    /// Создаёт обёртку для дескриптора контекста, полученного модулем OpenCL
    /// Девайс выбирается с указанным дескриптором, так же полученный из модуля OpenCL
    /// Автоматическое удаление контекста не произойдёт при удалении всех ссылок на полученную обёртку
    /// В отличии от создания нового контекста - контекстом управляет модуль OpenCL а не OpenCLABC
    public constructor(context: cl_context; device: cl_device_id);
    begin
      _device := device;
      _context := context;
    end;
    
    /// Инициализирует все команды в очереди и запускает первые
    /// Возвращает объект задачи, по которому можно следить за состоянием выполнения очереди
    public function BeginInvoke<T>(q: CommandQueue<T>): Task<T>;
    begin
      var ec: ErrorCode;
      var cq := cl.CreateCommandQueue(_context, _device, CommandQueuePropertyFlags.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, ec);
      ec.RaiseIfError;
      
      var tasks := q.Invoke(self, cq, cl_event.Zero).ToArray;
      
      var костыль_для_Result: ()->T := ()-> //ToDo #1952
      begin
        Task.WaitAll(tasks);
        if q.ev<>cl_event.Zero then cl.WaitForEvents(1, @q.ev).RaiseIfError;
        
        cl.ReleaseCommandQueue(cq).RaiseIfError;
        Result := q.res;
      end;
      
      Result := Task.Run(костыль_для_Result);
    end;
    
    /// Выполняет BeginInvoke и ожидает окончания выполнения возвращённой задачи
    /// Возвращает результат задачи, который, обычно, ничего не означает
    public function SyncInvoke<T>(q: CommandQueue<T>): T;
    begin
      var tsk := BeginInvoke(q);
      tsk.Wait;
      Result := tsk.Result;
    end;
    
    ///--
    public procedure Finalize; override :=
    if need_finnalize then // если было исключение при инициализации или инициализация произошла из дескриптора
      cl.ReleaseContext(_context).RaiseIfError;
    
  end;
  
  {$endregion Context}
  
  {$region ProgramCode}
  
  ProgramCode = sealed class
    private _program: cl_program;
    private cntxt: Context;
    
    private constructor := exit;
    
    public constructor(c: Context; params files_texts: array of string);
    begin
      var ec: ErrorCode;
      self.cntxt := c;
      
      self._program := cl.CreateProgramWithSource(c._context, files_texts.Length, files_texts, files_texts.ConvertAll(s->new UIntPtr(s.Length)), ec);
      ec.RaiseIfError;
      
      cl.BuildProgram(self._program, 1, @c._device, nil,nil,nil).RaiseIfError;
      
    end;
    
    public constructor(params files_texts: array of string) :=
    Create(Context.Default, files_texts);
    
    public property KernelByName[kname: string]: Kernel read new Kernel(self, kname); default;
    
    public function GetAllKernels: Dictionary<string, Kernel>;
    begin
      
      var names_char_len: UIntPtr;
      cl.GetProgramInfo(_program, ProgramInfoType.NUM_KERNELS, new UIntPtr(UIntPtr.Size), @names_char_len, nil).RaiseIfError;
      
      var names_ptr := Marshal.AllocHGlobal(IntPtr(pointer(names_char_len))+1);
      cl.GetProgramInfo(_program, ProgramInfoType.KERNEL_NAMES, names_char_len, pointer(names_ptr), nil).RaiseIfError;
      
      var names := Marshal.PtrToStringAnsi(names_ptr).Split(';');
      Marshal.FreeHGlobal(names_ptr);
      
      Result := new Dictionary<string, Kernel>(names.Length);
      foreach var kname in names do
        Result[kname] := self[kname];
      
    end;
    
    public function Serialize: array of byte;
    begin
      var bytes_count: UIntPtr;
      cl.GetProgramInfo(_program, ProgramInfoType.BINARY_SIZES, new UIntPtr(UIntPtr.Size), @bytes_count, nil).RaiseIfError;
      
      var bytes_mem := Marshal.AllocHGlobal(IntPtr(pointer(bytes_count)));
      cl.GetProgramInfo(_program, ProgramInfoType.BINARIES, bytes_count, @bytes_mem, nil).RaiseIfError;
      
      Result := new byte[bytes_count.ToUInt64()];
      Marshal.Copy(bytes_mem,Result, 0,Result.Length);
      Marshal.FreeHGlobal(bytes_mem);
      
    end;
    
    public procedure SerializeTo(bw: System.IO.BinaryWriter);
    begin
      var bts := Serialize;
      bw.Write(bts.Length);
      bw.Write(bts);
    end;
    
    public procedure SerializeTo(str: System.IO.Stream) := SerializeTo(new System.IO.BinaryWriter(str));
    
    public static function Deserialize(c: Context; bin: array of byte): ProgramCode;
    begin
      var ec: ErrorCode;
      
      Result := new ProgramCode;
      Result.cntxt := c;
      
      var gchnd := GCHandle.Alloc(bin, GCHandleType.Pinned);
      var bin_mem: ^byte := pointer(gchnd.AddrOfPinnedObject);
      var bin_len := new UIntPtr(bin.Length);
      
      Result._program := cl.CreateProgramWithBinary(c._context,1,@c._device, @bin_len, @bin_mem, nil, @ec);
      ec.RaiseIfError;
      gchnd.Free;
      
    end;
    
    public static function DeserializeFrom(c: Context; br: System.IO.BinaryReader): ProgramCode;
    begin
      var bin_len := br.ReadInt32;
      var bin_arr := br.ReadBytes(bin_len);
      if bin_arr.Length<bin_len then raise new System.IO.EndOfStreamException;
      Result := Deserialize(c, bin_arr);
    end;
    
    public static function DeserializeFrom(c: Context; str: System.IO.Stream) :=
    DeserializeFrom(c, new System.IO.BinaryReader(str));
    
  end;
  
  {$endregion ProgramCode}
  
{$region Сахарные подпрограммы}

///Host Funcion Queue
///Создаёт новую очередь, выполняющую функцию на CPU
function HFQ<T>(f: ()->T): CommandQueue<T>;

///Host Procecure Queue
///Создаёт новую очередь, выполняющую процедуру на CPU
function HPQ(p: ()->()): CommandQueue<object>;

///Складывает все очереди qs
///Возвращает очередь, по очереди выполняющую все очереди из qs
function CombineSyncQueue<T>(qs: List<CommandQueueBase>): CommandQueue<T>;
///Складывает все очереди qs
///Возвращает очередь, по очереди выполняющую все очереди из qs
function CombineSyncQueue<T>(qs: List<CommandQueue<T>>): CommandQueue<T>;
///Складывает все очереди qs
///Возвращает очередь, по очереди выполняющую все очереди из qs
function CombineSyncQueue<T>(params qs: array of CommandQueueBase): CommandQueue<T>;
///Складывает все очереди qs
///Возвращает очередь, по очереди выполняющую все очереди из qs
function CombineSyncQueue<T>(params qs: array of CommandQueue<T>): CommandQueue<T>;

///Умножает все очереди qs
///Возвращает очередь, параллельно выполняющую все очереди из qs
function CombineAsyncQueue<T>(qs: List<CommandQueueBase>): CommandQueue<T>;
///Умножает все очереди qs
///Возвращает очередь, параллельно выполняющую все очереди из qs
function CombineAsyncQueue<T>(qs: List<CommandQueue<T>>): CommandQueue<T>;
///Умножает все очереди qs
///Возвращает очередь, параллельно выполняющую все очереди из qs
function CombineAsyncQueue<T>(params qs: array of CommandQueueBase): CommandQueue<T>;
///Умножает все очереди qs
///Возвращает очередь, параллельно выполняющую все очереди из qs
function CombineAsyncQueue<T>(params qs: array of CommandQueue<T>): CommandQueue<T>;

{$endregion Сахарные подпрограммы}

implementation

{$region CommandQueue}

{$region HostFunc}

function CommandQueueHostFunc<T>.Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task;
begin
  var ec: ErrorCode;
  
  if (prev_ev<>cl_event.Zero) or (self.f <> nil) then
  begin
    
    ClearEvent;
    self.ev := cl.CreateUserEvent(c._context, ec);
    ec.RaiseIfError;
    
    yield Task.Run(()->
    begin
      if prev_ev<>cl_event.Zero then cl.WaitForEvents(1,@prev_ev).RaiseIfError;
      if self.f<>nil then self.res := self.f();
      
      cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
    end);
    
  end else
    self.ev := cl_event.Zero;
  
end;

static function CommandQueue<T>.operator implicit(o: T): CommandQueue<T> :=
new CommandQueueHostFunc<T>(o);

{$endregion HostFunc}

{$region ThenConvert}

type
  CommandQueueResConvertor<T1,T2> = sealed class(CommandQueue<T2>)
    q: CommandQueue<T1>;
    f: T1->T2;
    
    constructor(q: CommandQueue<T1>; f: T1->T2);
    begin
      self.q := q;
      self.f := f;
    end;
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      yield sequence q.Invoke(c, cq, prev_ev);
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if q.ev<>cl_event.Zero then cl.WaitForEvents(1,@q.ev).RaiseIfError;
        self.res := self.f(q.res);
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override :=
    ClearEvent;
    
  end;

function CommandQueue<T>.ThenConvert<T2>(f: T->T2) :=
new CommandQueueResConvertor<T,T2>(self, f);

{$endregion ThenConvert}

{$region SyncList}

type
  CommandQueueSyncList<T> = sealed class(CommandQueue<T>)
    public lst: List<CommandQueueBase>;
    
    public constructor :=
    lst := new List<CommandQueueBase>;
    
    public constructor(qs: List<CommandQueueBase>) :=
    lst := qs;
    
    public constructor(qs: List<CommandQueue<T>>) :=
    lst := qs.ConvertAll(q->q as CommandQueueBase);
    
    public constructor(qs: array of CommandQueueBase) :=
    lst := qs.ToList;
    
    public constructor(qs: array of CommandQueue<T>);
    begin
      lst := new List<CommandQueueBase>(qs.Length);
      foreach var q in qs do
        lst += q as CommandQueueBase;
    end;
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      foreach var sq in lst do
      begin
        yield sequence sq.Invoke(c, cq, prev_ev);
        prev_ev := sq.ev;
      end;
      
      if prev_ev<>cl_event.Zero then
      begin
        ClearEvent;
        self.ev := cl.CreateUserEvent(c._context, ec);
        ec.RaiseIfError;
        
        yield Task.Run(()->
        begin
          cl.WaitForEvents(1,@prev_ev).RaiseIfError;
          self.res := T(lst[lst.Count-1].GetRes);
          cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        end);
      end else
      begin
        self.ev := cl_event.Zero;
        self.res := T(lst[lst.Count-1].GetRes);
      end;
      
    end;
    
    public procedure Finalize; override :=
    ClearEvent;
    
  end;

static function CommandQueue<T>.operator+<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
begin
  var res: CommandQueueSyncList<T2>;
  if q2 is CommandQueueSyncList<T2>(var psl) then
    res := psl else
  begin
    res := new CommandQueueSyncList<T2>;
    res.lst += q2 as CommandQueueBase;
  end;
  
  if q1 is CommandQueueSyncList<T>(var psl) then
    res.lst.InsertRange(0, psl.lst) else
    res.lst.Insert(0, q1);
  
  Result := res;
end;

{$endregion SyncList}

{$region AsyncList}

type
  CommandQueueAsyncList<T> = sealed class(CommandQueue<T>)
    public lst: List<CommandQueueBase>;
    
    public constructor :=
    lst := new List<CommandQueueBase>;
    
    public constructor(qs: List<CommandQueueBase>) :=
    lst := qs;
    
    public constructor(qs: List<CommandQueue<T>>) :=
    lst := qs.ConvertAll(q->q as CommandQueueBase);
    
    public constructor(qs: array of CommandQueueBase) :=
    lst := qs.ToList;
    
    public constructor(qs: array of CommandQueue<T>);
    begin
      lst := new List<CommandQueueBase>(qs.Length);
      foreach var q in qs do
        lst += q as CommandQueueBase;
    end;
    
    protected function Invoke(c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      foreach var sq in lst do yield sequence sq.Invoke(c, cq, prev_ev);
      
      yield Task.Run(()->
      begin
        var evs := lst.Select(q->q.ev).Where(ev->ev<>cl_event.Zero).ToArray;
        if evs.Length<>0 then cl.WaitForEvents(evs.Length,evs).RaiseIfError;
        self.res := T(lst[lst.Count-1].GetRes);
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override :=
    ClearEvent;
    
  end;

static function CommandQueue<T>.operator*<T2>(q1: CommandQueue<T>; q2: CommandQueue<T2>): CommandQueue<T2>;
begin
  var res: CommandQueueAsyncList<T2>;
  if q2 is CommandQueueAsyncList<T2>(var pasl) then
    res := pasl else
  begin
    res := new CommandQueueAsyncList<T2>;
    res.lst += q2 as CommandQueueBase;
  end;
  
  if q1 is CommandQueueAsyncList<T>(var pasl) then
    res.lst.InsertRange(0, pasl.lst) else
    res.lst.Insert(0, q1);
  
  Result := res;
end;

{$endregion AsyncList}

{$region Buffer}

{$region WriteData}

type
  BufferCommandWriteData = sealed class(BufferCommand)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      var ev_lst := new List<cl_event>;
      yield sequence ptr   .Invoke(c, cq, cl_event.Zero); if ptr   .ev<>cl_event.Zero then ev_lst += ptr.ev;
      yield sequence offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueWriteBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueWriteBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  BufferCommandWriteArray = sealed class(BufferCommand)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      yield sequence a     .Invoke(c, cq, cl_event.Zero);
      yield sequence offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if a.ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev).RaiseIfError;
        var gchnd := GCHandle.Alloc(a.res, GCHandleType.Pinned);
        
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueWriteBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueWriteBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1,@buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  BufferCommandWriteValue = sealed class(BufferCommand)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      var ev_lst := new List<cl_event>;
      yield sequence ptr   .Invoke(c, cq, cl_event.Zero); if ptr   .ev<>cl_event.Zero then ev_lst += ptr.ev;
      yield sequence offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueWriteBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueWriteBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        Marshal.FreeHGlobal(ptr.res);
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  
  
function BufferCommandQueue.WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteData(ptr, offset, len));
function BufferCommandQueue.WriteData(ptr: CommandQueue<IntPtr>) := WriteData(ptr, 0,integer(res.sz.ToUInt32));

function BufferCommandQueue.WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteArray(a, offset, len));
function BufferCommandQueue.WriteArray(a: CommandQueue<&Array>) := WriteArray(a, 0,integer(res.sz.ToUInt32));


function BufferCommandQueue.WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>): BufferCommandQueue;
begin
  var sz := Marshal.SizeOf&<TRecord>;
  var ptr := Marshal.AllocHGlobal(sz);
  var typed_ptr: ^TRecord := pointer(ptr);
  typed_ptr^ := val;
  Result := AddCommand(new BufferCommandWriteValue(ptr,Marshal.SizeOf&<TRecord>, offset));
end;

function BufferCommandQueue.WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValue(
  val.ThenConvert&<IntPtr>(vval-> //ToDo #2067
  begin
    var sz := Marshal.SizeOf&<TRecord>;
    var ptr := Marshal.AllocHGlobal(sz);
    var typed_ptr: ^TRecord := pointer(ptr);
    typed_ptr^ := TRecord(object(vval)); //ToDo #2068
    Result := ptr;
  end),
  Marshal.SizeOf&<TRecord>,
  offset
));

{$endregion WriteData}

{$region ReadData}

type
  BufferCommandReadData = sealed class(BufferCommand)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      var ev_lst := new List<cl_event>;
      yield sequence ptr   .Invoke(c, cq, cl_event.Zero); if ptr   .ev<>cl_event.Zero then ev_lst += ptr.ev;
      yield sequence offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueReadBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueReadBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), ptr.res, 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  BufferCommandReadArray = sealed class(BufferCommand)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      yield sequence a     .Invoke(c, cq, cl_event.Zero);
      yield sequence offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if a.ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev).RaiseIfError;
        var gchnd := GCHandle.Alloc(a.res, GCHandleType.Pinned);
        
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueReadBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueReadBuffer(cq, b.memobj, 0, new UIntPtr(offset.res), new UIntPtr(len.res), gchnd.AddrOfPinnedObject, 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1,@buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  
  
function BufferCommandQueue.ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadData(ptr, offset, len));
function BufferCommandQueue.ReadData(ptr: CommandQueue<IntPtr>) := ReadData(ptr, 0,integer(res.sz.ToUInt32));

function BufferCommandQueue.ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadArray(a, offset, len));
function BufferCommandQueue.ReadArray(a: CommandQueue<&Array>) := ReadArray(a, 0,integer(res.sz.ToUInt32));

{$endregion ReadData}

{$region PatternFill}

type
  BufferCommandDataFill = sealed class(BufferCommand)
    public ptr: CommandQueue<IntPtr>;
    public pattern_len, offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>);
    begin
      self.ptr := ptr;
      self.pattern_len := pattern_len;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      var ev_lst := new List<cl_event>;
      yield sequence ptr         .Invoke(c, cq, cl_event.Zero); if ptr         .ev<>cl_event.Zero then ev_lst += ptr.ev;
      yield sequence pattern_len .Invoke(c, cq, cl_event.Zero); if pattern_len .ev<>cl_event.Zero then ev_lst += pattern_len.ev;
      yield sequence offset      .Invoke(c, cq, cl_event.Zero); if offset      .ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len         .Invoke(c, cq, cl_event.Zero); if len         .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueFillBuffer(cq, b.memobj, ptr.res,new UIntPtr(pattern_len.res), new UIntPtr(offset.res),new UIntPtr(len.res), 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueFillBuffer(cq, b.memobj, ptr.res,new UIntPtr(pattern_len.res), new UIntPtr(offset.res),new UIntPtr(len.res), 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  BufferCommandArrayFill = sealed class(BufferCommand)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      yield sequence a     .Invoke(c, cq, cl_event.Zero);
      yield sequence offset.Invoke(c, cq, cl_event.Zero); if offset.ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len   .Invoke(c, cq, cl_event.Zero); if len   .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if a.ev<>cl_event.Zero then cl.WaitForEvents(1,@a.ev).RaiseIfError;
        var gchnd := GCHandle.Alloc(a.res, GCHandleType.Pinned);
        var pattern_sz := Marshal.SizeOf(a.res.GetType.GetElementType) * a.res.Length;
        
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueFillBuffer(cq, b.memobj, gchnd.AddrOfPinnedObject,new UIntPtr(pattern_sz), new UIntPtr(offset.res),new UIntPtr(len.res), 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueFillBuffer(cq, b.memobj, gchnd.AddrOfPinnedObject,new UIntPtr(pattern_sz), new UIntPtr(offset.res),new UIntPtr(len.res), 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1,@buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        gchnd.Free;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  BufferCommandValueFill = sealed class(BufferCommand)
    public ptr: CommandQueue<IntPtr>;
    public pattern_len, offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>);
    begin
      self.ptr := ptr;
      self.pattern_len := pattern_len;
      self.offset := offset;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      var ev_lst := new List<cl_event>;
      yield sequence ptr         .Invoke(c, cq, cl_event.Zero); if ptr         .ev<>cl_event.Zero then ev_lst += ptr.ev;
      yield sequence pattern_len .Invoke(c, cq, cl_event.Zero); if pattern_len .ev<>cl_event.Zero then ev_lst += pattern_len.ev;
      yield sequence offset      .Invoke(c, cq, cl_event.Zero); if offset      .ev<>cl_event.Zero then ev_lst += offset.ev;
      yield sequence len         .Invoke(c, cq, cl_event.Zero); if len         .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueFillBuffer(cq, b.memobj, ptr.res,new UIntPtr(pattern_len.res), new UIntPtr(offset.res),new UIntPtr(len.res), 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueFillBuffer(cq, b.memobj, ptr.res,new UIntPtr(pattern_len.res), new UIntPtr(offset.res),new UIntPtr(len.res), 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        Marshal.FreeHGlobal(ptr.res);
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;
  
  
function BufferCommandQueue.PatternFill(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandDataFill(ptr,pattern_len, offset,len));
function BufferCommandQueue.PatternFill(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>) := PatternFill(ptr,pattern_len, 0,integer(res.sz.ToUInt32));

function BufferCommandQueue.PatternFill(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandArrayFill(a, offset,len));
function BufferCommandQueue.PatternFill(a: CommandQueue<&Array>) := PatternFill(a, 0,integer(res.sz.ToUInt32));


function BufferCommandQueue.PatternFill<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): BufferCommandQueue;
begin
  var sz := Marshal.SizeOf&<TRecord>;
  var ptr := Marshal.AllocHGlobal(sz);
  var typed_ptr: ^TRecord := pointer(ptr);
  typed_ptr^ := val;
  Result := AddCommand(new BufferCommandValueFill(ptr,Marshal.SizeOf&<TRecord>, offset,len));
end;

function BufferCommandQueue.PatternFill<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFill(
  val.ThenConvert&<IntPtr>(vval-> //ToDo #2067
  begin
    var sz := Marshal.SizeOf&<TRecord>;
    var ptr := Marshal.AllocHGlobal(sz);
    var typed_ptr: ^TRecord := pointer(ptr);
    typed_ptr^ := TRecord(object(vval)); //ToDo #2068
    Result := ptr;
  end),
  Marshal.SizeOf&<TRecord>,
  offset, len
));

function BufferCommandQueue.PatternFill<TRecord>(val: TRecord) :=
PatternFill(val, 0,integer(res.sz.ToUInt32));

function BufferCommandQueue.PatternFill<TRecord>(val: CommandQueue<TRecord>) :=
PatternFill(val, 0,integer(res.sz.ToUInt32));

{$endregion PatternFill}

{$region Copy}

type
  BufferCommandCopy = sealed class(BufferCommand)
    public f_buf, t_buf: CommandQueue<Buffer>;
    public f_pos, t_pos, len: CommandQueue<integer>;
    
    public constructor(f_buf, t_buf: CommandQueue<Buffer>; f_pos, t_pos, len: CommandQueue<integer>);
    begin
      self.f_buf := f_buf;
      self.t_buf := t_buf;
      self.f_pos := f_pos;
      self.t_pos := t_pos;
      self.len := len;
    end;
    
    protected function Invoke(b: Buffer; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ec: ErrorCode;
      
      var ev_lst := new List<cl_event>;
      yield sequence f_buf.Invoke(c, cq, cl_event.Zero); if f_buf.ev<>cl_event.Zero then ev_lst += f_buf.ev;
      yield sequence t_buf.Invoke(c, cq, cl_event.Zero); if t_buf.ev<>cl_event.Zero then ev_lst += t_buf.ev;
      yield sequence f_pos.Invoke(c, cq, cl_event.Zero); if f_pos.ev<>cl_event.Zero then ev_lst += f_pos.ev;
      yield sequence t_pos.Invoke(c, cq, cl_event.Zero); if t_pos.ev<>cl_event.Zero then ev_lst += t_pos.ev;
      yield sequence len  .Invoke(c, cq, cl_event.Zero); if len  .ev<>cl_event.Zero then ev_lst += len.ev;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count, ev_lst.ToArray).RaiseIfError;
        
        var buff_ev: cl_event;
        if prev_ev=cl_event.Zero then
          cl.EnqueueCopyBuffer(cq, f_buf.res.memobj,t_buf.res.memobj, new UIntPtr(f_pos.res),new UIntPtr(t_pos.res), new UIntPtr(len.res), 0,nil,@buff_ev).RaiseIfError else
          cl.EnqueueCopyBuffer(cq, f_buf.res.memobj,t_buf.res.memobj, new UIntPtr(f_pos.res),new UIntPtr(t_pos.res), new UIntPtr(len.res), 1,@prev_ev,@buff_ev).RaiseIfError;
        cl.WaitForEvents(1, @buff_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override;
    begin
      inherited Finalize;
      ClearEvent;
    end;
    
  end;

function BufferCommandQueue.CopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopy(b,res, from,&to, len));
function BufferCommandQueue.CopyFrom(b: CommandQueue<Buffer>) := CopyFrom(b, 0,0, integer(res.sz.ToUInt32));

function BufferCommandQueue.CopyTo(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopy(res,b, &to,from, len));
function BufferCommandQueue.CopyTo(b: CommandQueue<Buffer>) := CopyTo(b, 0,0, integer(res.sz.ToUInt32));

{$endregion Copy}

{$endregion Buffer}

{$region Kernel}

{$region AddQueue}

type
  KernelQueueCommand<T> = sealed class(KernelCommand)
    public q: CommandQueue<T>;
    
    public constructor(q: CommandQueue<T>) :=
    self.q := q;
    
    protected function Invoke(k: Kernel; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      yield sequence q.Invoke(c,cq,prev_ev);
      self.ev := q.ev;
    end;
    
  end;
  
function KernelCommandQueue.AddQueue<T>(q: CommandQueue<T>) :=
AddCommand(new KernelQueueCommand<T>(q));

{$endregion AddQueue}

{$region Exec}

type
  KernelCommandExec = sealed class(KernelCommand)
    public work_szs: array of UIntPtr;
    public args_q: array of CommandQueue<Buffer>;
    
    public constructor(work_szs: array of UIntPtr; args: array of CommandQueue<Buffer>);
    begin
      self.work_szs := work_szs;
      self.args_q := args;
    end;
    
    protected function Invoke(k: Kernel; c: Context; cq: cl_command_queue; prev_ev: cl_event): sequence of Task; override;
    begin
      var ev_lst := new List<cl_event>;
      var ec: ErrorCode;
      
      foreach var arg_q in args_q do
      begin
        yield sequence arg_q.Invoke(c, cq, cl_event.Zero);
        if arg_q.ev<>cl_event.Zero then
          ev_lst += arg_q.ev;
      end;
      
      ClearEvent;
      self.ev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      yield Task.Run(()->
      begin
        if ev_lst.Count<>0 then cl.WaitForEvents(ev_lst.Count,ev_lst.ToArray);
        
        for var i := 0 to args_q.Length-1 do
        begin
          if args_q[i].res.memobj=cl_mem.Zero then args_q[i].res.Init(c);
          cl.SetKernelArg(k._kernel, i, new UIntPtr(UIntPtr.Size), args_q[i].res.memobj).RaiseIfError;
        end;
        
        var kernel_ev: cl_event;
        cl.EnqueueNDRangeKernel(cq, k._kernel, work_szs.Length, nil,work_szs,nil, 0,nil,@kernel_ev).RaiseIfError; // prev.ev уже в ev_lst, тут проверять не надо
        cl.WaitForEvents(1,@kernel_ev).RaiseIfError;
        
        cl.SetUserEventStatus(self.ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      end);
      
    end;
    
    public procedure Finalize; override :=
    ClearEvent;
    
  end;
  
function KernelCommandQueue.Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>) :=
AddCommand(new KernelCommandExec(work_szs, args));

function KernelCommandQueue.Exec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
begin
  AddQueue(CombineAsyncQueue(work_szs));
  AddCommand(new KernelCommandExec(work_szs.ConvertAll(sz_q->sz_q.res), args));
  Result := self;
end;


{$endregion Exec}

{$endregion Kernel}

{$endregion CommandQueue}

{$region Buffer}

{$region constructor's}

procedure Buffer.Init(c: Context);
begin
  var ec: ErrorCode;
  if self.memobj<>cl_mem.Zero then cl.ReleaseMemObject(self.memobj);
  self.memobj := cl.CreateBuffer(c._context, MemoryFlags.READ_WRITE, self.sz, IntPtr.Zero, ec);
  ec.RaiseIfError;
end;

function Buffer.SubBuff(offset, size: integer): Buffer;
begin
  if self.memobj=cl_mem.Zero then Init(Context.Default);
  
  Result := new Buffer(size);
  Result._parent := self;
  
  var ec: ErrorCode;
  var reg := new cl_buffer_region(
    new UIntPtr( offset ),
    new UIntPtr( size )
  );
  Result.memobj := cl.CreateSubBuffer(self.memobj, MemoryFlags.READ_WRITE, BufferCreateType.REGION, pointer(@reg), ec);
  ec.RaiseIfError;
  
end;

{$endregion constructor's}

{$region Write}

function Buffer.WriteData(ptr: CommandQueue<IntPtr>) :=
Context.Default.SyncInvoke(self.NewQueue.WriteData(ptr) as CommandQueue<Buffer>);

function Buffer.WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.WriteData(ptr, offset,len) as CommandQueue<Buffer>);

function Buffer.WriteArray(a: CommandQueue<&Array>) :=
Context.Default.SyncInvoke(self.NewQueue.WriteArray(a) as CommandQueue<Buffer>);

function Buffer.WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.WriteArray(a, offset,len) as CommandQueue<Buffer>);

{$endregion Write}

{$region Read}

function Buffer.ReadData(ptr: CommandQueue<IntPtr>) :=
Context.Default.SyncInvoke(self.NewQueue.ReadData(ptr) as CommandQueue<Buffer>);

function Buffer.ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.ReadData(ptr, offset,len) as CommandQueue<Buffer>);

function Buffer.ReadArray(a: CommandQueue<&Array>) :=
Context.Default.SyncInvoke(self.NewQueue.ReadArray(a) as CommandQueue<Buffer>);

function Buffer.ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.ReadArray(a, offset,len) as CommandQueue<Buffer>);

{$endregion Read}

{$region Get}

function Buffer.GetData(offset, len: CommandQueue<integer>): IntPtr;
begin
  var len_val := Context.Default.SyncInvoke(len);
  Result := Marshal.AllocHGlobal(len_val);
  Context.Default.SyncInvoke(
    self.NewQueue.ReadData(Result, offset,len_val) as CommandQueue<Buffer>
  );
end;

function Buffer.GetArrayAt<TArray>(offset: CommandQueue<integer>; szs: CommandQueue<array of integer>): TArray;
begin
  var el_t := typeof(TArray).GetElementType;
  
  var szs_val: array of integer := Context.Default.SyncInvoke(szs);
  Result := TArray(System.Array.CreateInstance(
    el_t,
    szs_val
  ));
  
  var res_len := Result.Length;
  
  Context.Default.SyncInvoke(
    self.NewQueue
    .ReadArray(Result, offset, Marshal.SizeOf(el_t) * res_len) as CommandQueue<Buffer> //ToDo #1981
  );
  
end;

function Buffer.GetValueAt<TRecord>(offset: CommandQueue<integer>): TRecord;
begin
  Context.Default.SyncInvoke(
    self.NewQueue
    .ReadValue(Result, offset) as CommandQueue<Buffer> //ToDo #1981
  );
end;

{$endregion Get}

{$region Fill}

function Buffer.PatternFill(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.PatternFill(ptr,pattern_len) as CommandQueue<Buffer>);

function Buffer.PatternFill(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.PatternFill(ptr,pattern_len, offset,len) as CommandQueue<Buffer>);

function Buffer.PatternFill(a: CommandQueue<&Array>) :=
Context.Default.SyncInvoke(self.NewQueue.PatternFill(a) as CommandQueue<Buffer>);

function Buffer.PatternFill(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(self.NewQueue.PatternFill(a, offset,len) as CommandQueue<Buffer>);

{$endregion Fill}

{$region Copy}

function Buffer.CopyFrom(arg: Buffer; from, &to, len: CommandQueue<integer>) := Context.Default.SyncInvoke(self.NewQueue.CopyFrom(arg, from,&to, len) as CommandQueue<Buffer>);
function Buffer.CopyTo  (arg: Buffer; from, &to, len: CommandQueue<integer>) := Context.Default.SyncInvoke(self.NewQueue.CopyTo  (arg, from,&to, len) as CommandQueue<Buffer>);

function Buffer.CopyFrom(arg: Buffer) := Context.Default.SyncInvoke(self.NewQueue.CopyFrom(arg) as CommandQueue<Buffer>);
function Buffer.CopyTo  (arg: Buffer) := Context.Default.SyncInvoke(self.NewQueue.CopyTo  (arg) as CommandQueue<Buffer>);

{$endregion Copy}

{$endregion Buffer}

{$region Kernel}

constructor Kernel.Create(prog: ProgramCode; name: string);
begin
  var ec: ErrorCode;
  
  self._kernel := cl.CreateKernel(prog._program, name, ec);
  ec.RaiseIfError;
  
end;

function Kernel.Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(self.NewQueue.Exec(work_szs, args) as CommandQueue<Kernel>);

{$endregion Kernel}

{$region Сахарные подпрограммы}

function HFQ<T>(f: ()->T) :=
new CommandQueueHostFunc<T>(f);

function HPQ(p: ()->()) :=
HFQ&<object>(
  ()->
  begin
    p();
    Result := nil;
  end
);

function CombineSyncQueue<T>(qs: List<CommandQueueBase>) :=
new CommandQueueSyncList<T>(qs);
function CombineSyncQueue<T>(qs: List<CommandQueue<T>>) :=
new CommandQueueSyncList<T>(qs);
function CombineSyncQueue<T>(params qs: array of CommandQueueBase) :=
new CommandQueueSyncList<T>(qs);
function CombineSyncQueue<T>(params qs: array of CommandQueue<T>) :=
new CommandQueueSyncList<T>(qs);

function CombineAsyncQueue<T>(qs: List<CommandQueueBase>): CommandQueue<T> :=
new CommandQueueSyncList<T>(qs);
function CombineAsyncQueue<T>(qs: List<CommandQueue<T>>): CommandQueue<T> :=
new CommandQueueSyncList<T>(qs);
function CombineAsyncQueue<T>(params qs: array of CommandQueueBase): CommandQueue<T> :=
new CommandQueueSyncList<T>(qs);
function CombineAsyncQueue<T>(params qs: array of CommandQueue<T>) :=
new CommandQueueAsyncList<T>(qs);

{$endregion Сахарные подпрограммы}

end.