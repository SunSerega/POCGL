
{%..\LicenseHeader%}

///
///Высокоуровневая оболочка модуля OpenCL
///   OpenCL и OpenCLABC можно использовать одновременно
///   Но контактировать они практически не будут
///
///Если не хватает типа/метода или найдена ошибка - писать сюда:
///   https://github.com/SunSerega/POCGL/issues
///
///Справка данного модуля находится в папке примеров
///   По-умолчанию, её можно найти в "C:\PABCWork.NET\Samples\OpenGL и OpenCL"
///
unit OpenCLABC;

{$region DEBUG}{$ifdef DEBUG}

// Регистрация всех cl.RetainEvent и cl.ReleaseEvent
{ $define EventDebug}

// Регистрация использований cl_command_queue
{ $define QueueDebug}

// Регистрация активаций/деактиваций всех WaitHandler-ов
{ $define WaitDebug}

// Регистрация попыток .Exec команд кешировать свой CLKernel
{ $define ExecDebug}

{ $define ForceMaxDebug}
{$ifdef ForceMaxDebug}
  {$define EventDebug}
  {$define QueueDebug}
  {$define WaitDebug}
  {$define ExecDebug}
{$endif ForceMaxDebug}

{$endif DEBUG}{$endregion DEBUG}

{$region TODO}

//===================================
// Обязательно сделать до следующей стабильной версии:

//TODO Использовать StringPattern в тестере

//TODO Аргументы Kernel'ов вроде как могут удаляться до выполнения Enqueue
// - Проверить, как это у меня обрабатывается

//TODO Улучшить систему описаний:
// - Описание для unit
// - Описания для extensionmethod
// - Читабельность
// - Проверки адекватности шаблонов
//TODO Какой-то графический интерфейс для редактирования описаний?
// - Упрощённое дерево файлов
// - Читать .missing и т.п. файлы при обновлении чтобы показывать маркеры
// - Автоматический запуск упаковки с изменениями
// - Групировка шаблонов с кнопкой [+]
// - Ctrl-тык на ссылки в описаниях
// --- Кнопки назад/вперёд

//TODO k.Exec(a, b, c), где любой из массивов=nil
// - Поидее должна быть перегрузка clEnqueueNDRangeKernel, принимающая массивы

//TODO После cl.Enqueue нужно в любом случае UserEvent
// - Следующие команды игнорирует ошибку в ивенте на 2/3 реализациях, если она не в UserEvent
// - А в колбеке ивента команды надо сначала проверять ошибки prev_ev, потому что их может скопировать в ивент команды
// - Хотя должно быть достаточно .HadError перед проверкой
// - Или нет, если в одном ивенте ошибка, а другой всё ещё ждёт
// - Вообще это более общая проблема... В общем надо колбек делать для (prev_ev+enq_ev), чтобы дальше не продолжать пока всё не сработает

//TODO Вместо g.GetCQ(need_async_inv) лучше хранить ивент, после которого можно будет вызывать cl.Enqueue
// - Но порядок ивент-колбеков неопределён, поэтому надо сделать какую то магию с Interlocked
// - Или ConcurrentQueue?
//TODO А что если ещё один need_async_inv, пока предыдущий список ещё не выполнился
//TODO Сейчас GetCQ вызывается перед проверкой на ошибки от ev_l1
// - В случае need_async_inv - не знаю как это исправить без этой ConcurrentQueue

//TODO Пора бы почистить TODO в кодогенераторах - куча давно закрытых issue

//TODO Получается, HFQ(()->A).MakeCCQ.DiscardResult не выполняет HFQ?
// - (уже исправил)
// - Проверки в CLTask, если очередь инициализировалась но не выполнилась?

//TODO .MU в CCQ это костыль
// - Выполняется куча всего лишнего
// - Результат хранится в CLTask, хотя используется только в 1 выполнении CCQ
// --- То же самое в .MultiuseFor

//TODO Что будет если из g.ParallelInvoke выполнить что то НЕ инвокером
// - В любом случае добавить специальные проверки адекватности на время дебага

//TODO Теория: Все проверки "is ConstQueue<" заведомо костыльны
// - К примеру в try/finally надо проверять на наличие под-очередей, выполяющих код на CPU (НЕ wait)
//TODO С другой стороны в QueueCommand нужна проверка на полную сокращённость?

//TODO Может переименовать в Host[Proc/Func]Queue?

//TODO Каким, всё же, считает generic KernelArg: Global или Constant?

//TODO IEnumerable<T>.Lazy[Sync,Async]ForeachQueue(CQ<T> -> CQBase)
// - Без этого нельзя реализовать вызов очереди для каждого элемента списка с изменяющейся длиной
// - Нет, лучше сделать CombineQueue, но принимающий "sequence of T" и "CQ<T> -> CQBase"
//TODO Может тогда и extensionmethod, которому копируется описание?
//TODO CLList: Как массив, но с изменяемой длиной
//TODO Очень часто в OpenCL нужны двойные буферы: Предыдущее и новое состояние
// - Я сейчас использую HFQ(()->state1) и HFQ(()->state2), но это очень криво
//
//TODO .Cycle(integer)
//TODO .Cycle // бесконечность циклов
//TODO .CycleWhile(***->boolean)
// - Однако всё ещё остаётся вопрос - как сделать ветвление?
//TODO А может Cycle(CycleInfo: record Q_continue, Q_break: CQNil; end -> CQ)
// - Но для них всё равно нужен .ThenIf
// - И адекватную диагностику для недостижимого кода будет сложно вывести
//
//TODO И если уже делать ветвление - то сразу и:
// - .ThenIf(CQ<bool>, TQ, TQ): TQ
// - Проверить чтобы все комбинации Base/Nil/<T> работали
//TODO Или лучше сразу сделать аналог case, для нескольких типов:
// - .ThenCase(val: integer; cases: array of TQ; range_start := 0; default_last := false): TQ
// - .ThenCase(val: boolean; if_true, if_false: TQ): TQ
// - .ThenCase(val: T; choises: IDictionary<T, TQ>): TQ
//
//TODO Кеш не использованных веток, чтобы в .Cycle выполнять меньше .Invoke'ов
// - ConcurrentDictionary<CQBase, UserEvent>
// - Анализ где последнее использование у каждой ветки
//
//TODO .DelayInit, чтобы ветки .ThenIf можно было НЕ инициализировать заранее
// - Тогда .ThenIf на много проще реализовать - через особый err_handler, который говорит что ошибки были, без собственно ошибок
//TODO CCQ.ThenIf(cond, command, nil)
// - Подумать как можно сделать это красивее, чем через MU

//TODO CLContext.BeingInvoke выполняется чаще, чем создание новой очереди
// - Поэтому стоит хранить в очереди кеш некоторых вещей, которые сейчас вычисляются заново в .BeingInvoke
// - Сохранять очереди, требующие инициализации, в виде списка вместо дерева
// - MU очереди:
// --- Количество MU очередей (capacity для inited_mu)
// --- Количество .Invoke каждой MU очереди
// --- Нужен ли их результат (можно ли q.InvokeToNil)
// - Написать в справке что первый проход для разогрева

//TODO Если уже реализовывать поддержку "CQ<T> -> TQ"... Это сразу и альтернатива .MU?
// - Доп переменные не нужны. Т.е. очередь можно в 1 строчку расписать:
// --- "q.ThenMultiuse(q->q+q)"
// - Это будет интуитивнее:
// --- НЕ работать между CLContext.BeginInvoke
// --- Порядок выполнения: q выполняет уже не при запуске очереди
//TODO CLTaskErrHandlerThiefRepeater.FillErrLstWithPrev не берёт ошибки mu, если пришла ошибка с prev_ev
// - По моему это плохо, потому что mu всегда выполняется как в finally
// - Подумать как относится к .ThenMU, сделать тесты
//TODO Защита от дурака, чтобы q-параметр нельзя было использовать вне .ThenMultiuse
// - Поидее это уже примерно то, как работают очереди-параметры
//TODO .Multiuseable всё же оставить, у них применения в разных структурах кода
//TODO Очень важно оптимизировать такие случаи, в зависимости от того, сколько раз используется q-параметр (0, 1, else)
// - Это же должно оптимищироваться для более общего .Multiuseable
// - Тогда единственное различие - защита от дурака для q вне .ThenMultiuse
//TODO A.ThenMultiuse(A->(B+A)*(C+A)): Должно ли ожидать окончания A перед стартом B и C?
// - Нет, так нельзя, потому что тогда нельзя получить тот же порядок что с .MU
// - Но тогда надо назвать как-то по другому, не "Then"
// - .MultiuseAs? In? До "as" проще дотянуться

//TODO NativeMemoryArea в отдельный модуль
// - При этом сделать его кросс-платформенным

//TODO .GetArray(0) даёт ошибку
// - Надо сделать параметр-условие, который кодогенерируется в:
// --- if (len is ConstQueue) and (c_len.Value=0) then
// --- if len=0 then
// - И при этом настроить логику отмены cl.Enqueue, если второе условие не пройдёт

//TODO Использовать cl.EnqueueMapBuffer
// - В виде .ThenMapMemory([AutoSize?], Направление, while_mapped: CQ<Native*Area>->CQBase)
// - Лучше сделать так же как для CLKernelArgGlobal
// - В справку
// --- В том числе то, что Map быстрее Read, который быстрее Get
// --- (собсна протестить)
//TODO operator implicit для NativeValue=>CLKernelArg[Global] не генерируются?
// - Правда теперь не релевантно, потому что:
//TODO CLKernelArgGlobal (и Constant) из адреса RAM не обязан копировать данные с кеша GPU назад в RAM после выполнения kernel'а
// - Для этого случая (+оптимизации чтения/записи) и используется MapBuffer
// - В справку
//TODO При чём это в обе стороны (не-)работает
//  var v1 := new NativeValue<integer>(1);
//  var v2 := new CLValue<integer>(1);
//  var Q_Copy := k.MakeCCQ.ThenExec1(1,CLKernelArg.FromNativeValue(v1),v2)+v2.MakeCCQ.ThenGetValue;
//  
//  v1.Value := 3;
//  CLContext.Default.SyncInvoke(Q_Copy).Println; // тут происходит копирование из v1 в кеш
//  v1.Value := 5;
//  CLContext.Default.SyncInvoke(Q_Copy).Println; // тут всё ещё старое значение
//TODO Нет смысла в Global/Constant KernlArg'е хранящем NativeValue[Area]
// - CLMemory.FromHostMemory(copy: boolean? := nil)
// --- Создаёт или Memory(если copy), или его наследник, хранящий ещё "host_hnd: GCHandle" или "host_obj_ref: object"
// --- Если nil то используется Contex.MainDevice.CLPreferHostCLMemoryCopy := Type=GPU
// - А в обычном конструкторе добавить параметр prealloc_map_mem и убрать передачу существующей памяти
// --- MEM_ALLOC_HOST_PTR
// - В справку:
// --- FromHostMemory(copy=false) полезно для существующих объектов, но использовать вне .MapCLMemory их всё равно нельзя
// --- Кроме того, плотно упаковывать элементы плохо
// --- К примеру принимать float3* нельзя, надо принимать и передавать float4*
// --- Или, можно ещё принимать void*, но тогда на стороне OpenCL-C необходимы vload/vstore функции:
// --- https://www.khronos.org/registry/OpenCL/specs/3.0-unified/html/OpenCL_C.html#alignment-of-types

//TODO Тесты:
//
// - Отмена enq до и после cl.Enqueue
// --- "V.WriteValue(HQFQ(raise))"
// --- "V.WriteValue(HTFQ(raise))"
//
// - Ивент от MU должно добавить только 1 раз
// --- MU + HQPQ + MU + HQPQ + MU
// - Ивент от MU не добавляется второй раз
// --- (HQPQ(raise)+MU).Handle[ + MU]
// --- Поидее его добавляет первый раз, даже если ошибка
//
// - Должно быть HPQ+CQ в обоих случаях
// --- CQ().ThenUse[.Cast]
//
// - Выполнялось как "HTPQ >= CCQ"
// --- "HTPQ(raise) + CCQ"
//
// - need_own_thread и can_pre_calc
// --- (HTPQ+Par).ThenQuickUse.ThenConstConvert

//TODO Справка:
// - "Q1 -= Q2" вместо Q1 := Q2+Q1;
// - "Q1 /= Q2" вместо Q1 := Q2*Q1;
// - Wait[All/Any] => CombineWait[All/Any]
// - CQ<>.MakeCCQ
// - CLKernelArg
// - NativeArray
// - CLValue
// - !CL!Memory[SubSegment]
// - Из заголовка папки простых обёрток сделать прямую ссылку в под-папку папки CLKernelArg для CL- типов
// - CLMemoryUsage
// - CQ<byte>.Cast<byte?>
// - Properties.ToString
// - need_own_thread и can_pre_calc
// --- (HTPQ+Par).ThenQuickUse.ThenConstConvert
// - new CLValue<byte>(new CLMemorySubSegment(cl_a))
// --- CLArray и CLValue неявно конвертируются в CLMemory
// --- И их можно создать назад конструктором
// - Описать и в процессе перепродумать логику, почему CommandQueue<CommandQueue<>> не только не эффективно, но и не может понадобится
//TODO Разделить .html справку и гайд по OpenCLABC
// - Исправить ссылку на справку в описании заголовка модуля
//TODO github.io
// - Разобраться почему .css не работало до 0.css, но только на github.io
// - Добавить index.html в справки, состоящий из всего 1 страницы
// - Гитхаб-экшн, авто-обновляющий ветку справок

//===================================
// Запланированное:

//TODO Папка с расширениями OpenCLABC, что то типа:
// - uses 'OpenCLABC\GL';		  // Связь с OpenGLABC
// - uses 'OpenCLABC\Custom';	// Пользовательские очереди
// - uses 'OpenCLABC\Ext';		// Расширения OpenCL

//TODO Потоко-безопастность CCQ.AddCommand

//TODO Комментарии "Использовано в" энумам н.у. модулей
//TODO OpenCL: Объединить SamplePattern

//TODO WaitNothing - аналог CQNil, в первую очередь для WaitAll([])

//TODO Константные очереди с функцией-инициализатором
// - Как параметры, которым каждый раз дают новое значение
// - Полезно, к примеру, чтобы выделять новый массив-буфер на каждое выполнение
// - Или лучше какую-то кешированную очередь, выделяющий новые объекты только при накладывающихся выполнениях CLTask?
// - Если делать .ThenMap - использования получаются довольно ограничены...

//TODO [In] и [Out] в кодогенераторах
// - [Out] строки без [In] заменять на StringBuilder
// - Полезно, к примеру, в cl.GetProgramBuildInfo
// - А в cl.GetProgramInfo надо принимать [Out] "array of array of Byte" вместо "var IntPtr"

//TODO Деприкация в OpenCL?
// - К примеру clCreateImage2D не должна использоваться после 1.2

//TODO .ToString для простых обёрток лучше пусть возвращает hex представление ntv
// - Реализовано в ветке с новыми TypeName

//TODO Переделать кодогенераторы под что то типа .cshtml

//TODO Пользовательские очереди?
// - Всё же я не всё могу предугадать, поэтому
// - для окончательной версии модуля такая вещь необходима
// - Но чтобы это сделать... придётся типы-утилиты перенести в отдельный модуль,
// - чтобы они были доступны, но не на виду

//TODO Интегрировать профайлинг очередей
// - И в том числе профайлинг отдельных ивентов

//TODO Пройтись по интерфейсу, порасставлять кидание исключений
//TODO Проверки и кидания исключений перед всеми cl.*, чтобы выводить норм сообщения об ошибках
//TODO Попробовать получать информацию о параметрах CLKernel'а и выдавать адекватные ошибки, если передают что-то не то
// - clGetKernelInfo:NUM_ARGS
// - clGetKernelArgInfo
//TODO clGetKernelInfo:ATTRIBUTES?
//
//TODO Возможность выводить где именно в очереди возникла ошибка?

//TODO Порядок Wait очередей в Wait группах
// - Проверить сочетание с каждой другой фичей
// - В комбинации с .Cycle вообще возможно добиться детерминированности?

//TODO .pcu с неправильной позицией зависимости, или не теми настройками - должен игнорироваться
// - Иначе сейчас модули в примерах ссылаются на .pcu, который существует только во время работы Tester, ломая компилятор

//TODO Несколько TODO в:
// - Queue converter's >> Wait

//TODO Исправить перегрузки CLKernel.Exec
// - Но сначала придумать что исправлять
// - Перегрузки с UIntPtr перед перегрузками integer?

//TODO Фичи версий OpenCL:
// - 2.0
// --- SVM
// - 3.0
// --- CL_DEVICE_ILS_WITH_VERSION
// --- CL_DEVICE_BUILT_IN_KERNELS_WITH_VERSION
// --- CL_DEVICE_NUMERIC_VERSION
// --- CL_DEVICE_OPENCL_C_ALL_VERSIONS
// --- CL_DEVICE_OPENCL_C_FEATURES
// --- CL_DEVICE_EXTENSIONS_WITH_VERSION
// --- CL_DEVICE_ATOMIC_MEMORY_CAPABILITIES
// --- CL_DEVICE_ATOMIC_FENCE_CAPABILITIES
// --- CL_DEVICE_NON_UNIFORM_WORK_GROUP_SUPPORT
// --- CL_DEVICE_WORK_GROUP_COLLECTIVE_FUNCTIONS_SUPPORT
// --- CL_DEVICE_GENERIC_ADDRESS_SPACE_SUPPORT
// --- CL_DEVICE_DEVICE_ENQUEUE_CAPABILITIES
// --- CL_DEVICE_PIPE_SUPPORT
// --- CL_DEVICE_PREFERRED_WORK_GROUP_SIZE_MULTIPLE
// --- CL_DEVICE_LATEST_CONFORMANCE_VERSION_PASSED
//
// - ???
// --- clEnqueueMigrateMemObjects

//===================================
// Сделать когда-нибуть:

//TODO Пройтись по всем функциям OpenCL, посмотреть функционал каких не доступен из OpenCLABC
// - clGetCLKernelWorkGroupInfo - свойства кернела на определённом устройстве
// - clCreateContext: CL_CONTEXT_INTEROP_USER_SYNC
// - clCreateProgramWithIL
// - Асинхронные cl_command_queue
// - Другие типы cl_mem (сейчас используется только буфер)
// - clEnqueueNativeKernel
// --- CL_DEVICE_BUILT_IN_KERNELS
// - Расширения
// --- cl_khr_command_buffer
// --- cl_khr_semaphore

//===================================

{$endregion TODO}

{$region Upstream bugs}

//TODO Issue компилятора:
//TODO https://github.com/pascalabcnet/pascalabcnet/issues/{id}
// - #2221
// - #2550
// - #2589
// - #2604
// - #2607
// - #2610

//TODO Issue mono:
//TODO https://github.com/mono/mono/issues/{id}
// - #11034

{$endregion Upstream bugs}

interface

uses System;
uses System.Threading;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;
uses System.Collections.ObjectModel;
uses System.Collections.Concurrent;

uses OpenCL{%!!} in '..\Modules.Packed\OpenCL'{%};

type
  
  {$region TODO MOVE}
  
  {$region NativeArea}
  
  {$region NativeMemoryArea}
  
  NativeMemoryArea = record
    public ptr: IntPtr;
    public sz: UIntPtr;
    
    {$region constructor's}
    
    public constructor(ptr: IntPtr; sz: UIntPtr);
    begin
      self.ptr := ptr;
      self.sz := sz;
    end;
    public constructor(sz: UIntPtr);
    begin
      self.sz := sz;
      Alloc;
    end;
    public constructor;
    begin
      self.ptr := IntPtr.Zero;
      self.sz := UIntPtr.Zero;
    end;
    
    {$endregion constructor's}
    
    {$region Method's}
    
    {$region Fill}
    
    private static procedure RtlZeroMemory(dst: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlFillMemory(dst: IntPtr; length: UIntPtr; fill: byte);
    external 'kernel32.dll';
    
    public procedure FillZero := RtlZeroMemory(ptr, sz);
    public procedure Fill(val: byte) := RtlFillMemory(ptr, sz, val);
    
    {$endregion Fill}
    
    {$region Copy}
    
    private static procedure RtlCopyMemory(dst: IntPtr; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlCopyMemory(var dst: byte; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlCopyMemory(dst: IntPtr; var source: byte; length: UIntPtr);
    external 'kernel32.dll';
    
    public procedure CopyTo(area: NativeMemoryArea) := RtlCopyMemory(area.ptr, self.ptr, self.sz);
    public procedure CopyFrom(area: NativeMemoryArea) := RtlCopyMemory(self.ptr, area.ptr, self.sz);
    public static procedure CopyMinSize(source, dest: NativeMemoryArea);
    begin
      var min_sz := if source.sz.ToUInt64<dest.sz.ToUInt64 then source.sz else dest.sz;
      RtlCopyMemory(dest.ptr, source.ptr, min_sz);
    end;
    
    public procedure CopyTo<T>(var el: T) := RtlCopyMemory(PByte(pointer(@el))^, self.ptr, self.sz);
    public procedure CopyTo<T>(a: array of T) := CopyTo(a[0]);
    
    public procedure CopyFrom<T>(var el: T) := RtlCopyMemory(self.ptr, PByte(pointer(@el))^, self.sz);
    public procedure CopyFrom<T>(a: array of T) := CopyFrom(a[0]);
    
    {$endregion Copy}
    
    {$region CopyOverlapped}
    
    private static procedure RtlMoveMemory(dst: IntPtr; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlMoveMemory(var dst: byte; source: IntPtr; length: UIntPtr);
    external 'kernel32.dll';
    private static procedure RtlMoveMemory(dst: IntPtr; var source: byte; length: UIntPtr);
    external 'kernel32.dll';
    
    public procedure CopyOverlappedTo(area: NativeMemoryArea) := RtlMoveMemory(area.ptr, self.ptr, self.sz);
    public procedure CopyOverlappedFrom(area: NativeMemoryArea) := RtlMoveMemory(self.ptr, area.ptr, self.sz);
    public static procedure CopyOverlappedMinSize(source, dest: NativeMemoryArea);
    begin
      var min_sz := if source.sz.ToUInt64<dest.sz.ToUInt64 then source.sz else dest.sz;
      RtlMoveMemory(dest.ptr, source.ptr, min_sz);
    end;
    
    public procedure CopyOverlappedTo<T>(var el: T) := RtlMoveMemory(PByte(pointer(@el))^, self.ptr, self.sz);
    public procedure CopyOverlappedTo<T>(a: array of T) := CopyTo(a[0]);
    
    public procedure CopyOverlappedFrom<T>(var el: T) := RtlMoveMemory(self.ptr, PByte(pointer(@el))^, self.sz);
    public procedure CopyOverlappedFrom<T>(a: array of T) := CopyTo(a[0]);
    
    {$endregion CopyOverlapped}
    
    {$endregion Method's}
    
    {$region Alloc/Release}
    
    public property IsAllocated: boolean read self.ptr<>IntPtr.Zero;
    
    public procedure Alloc;
    begin
      self.ptr := Marshal.AllocHGlobal(IntPtr(self.sz.ToPointer));
      GC.AddMemoryPressure(self.sz.ToUInt64);
    end;
    public procedure Release;
    begin
      GC.RemoveMemoryPressure(self.sz.ToUInt64);
      Marshal.FreeHGlobal(self.ptr);
      self.ptr := IntPtr.Zero;
    end;
    public function TryRelease: boolean;
    begin
      Result := false;
      var temp := new NativeMemoryArea(
        Interlocked.Exchange(self.ptr, IntPtr.Zero),
        self.sz
      );
      if not temp.IsAllocated then exit;
      temp.Release;
      self.ptr := temp.ptr;
      Result := true;
    end;
    
    {$endregion Alloc/Release}
    
    public function ToString: string; override :=
    $'{TypeName(self)}:${ptr.ToString(''X'')}[{sz}]';
    
  end;
  
  {$endregion NativeMemoryArea}
  
  {$region NativeValueArea}
  
  NativeValueArea<T> = record
  where T: record;
    public ptr: IntPtr;
    
    {$region constructor's}
    
    static constructor;
    
    public constructor(ptr: IntPtr) := self.ptr := ptr;
    public constructor(alloc: boolean := false) :=
    if alloc then self.Alloc else
    self.ptr := IntPtr.Zero;
    
    public static function operator implicit(p: ^T): NativeValueArea<T> := new NativeValueArea<T>(new IntPtr(p));
    public static function operator implicit(area: NativeValueArea<T>): ^T := area.Pointer;
    public static function operator implicit(area: NativeValueArea<T>): NativeMemoryArea := area.UntypedArea;
    
    {$endregion constructor's}
    
    {$region property's}
    
    public static property ValueSize: integer read Marshal.SizeOf(default(T));
    public property ByteSize: UIntPtr read new UIntPtr(ValueSize);
    
    //TODO #????
    private function PointerUntyped := pointer(ptr);
    public property Pointer: ^T read PointerUntyped();
    public property Value: T read Pointer^ write Pointer^ := value;
    
    public property UntypedArea: NativeMemoryArea read new NativeMemoryArea(self.ptr, self.ByteSize);
    
    {$endregion property's}
    
    {$region Alloc/Release}
    
    public property IsAllocated: boolean read self.ptr<>IntPtr.Zero;
    
    public procedure Alloc;
    begin
      var temp := self.UntypedArea;
      temp.Alloc;
      self.ptr := temp.ptr;
    end;
    public procedure Release;
    begin
      var temp := self.UntypedArea;
      temp.Release;
      self.ptr := temp.ptr;
    end;
    public function TryRelease: boolean;
    begin
      Result := false;
      var temp := self.UntypedArea;
      temp.ptr := Interlocked.Exchange(self.ptr, IntPtr.Zero);
      if not temp.IsAllocated then exit;
      temp.Release;
      self.ptr := temp.ptr;
      Result := true;
    end;
    
    {$endregion Alloc/Release}
    
    public function ToString: string; override :=
    $'{TypeName(self)}:${ptr.ToString(''X'')}';
    
  end;
  
  {$endregion NativeValueArea}
  
  {$region NativeArrayArea}
  
  NativeArrayArea<T> = record
  where T: record;
    public first_ptr: IntPtr;
    public item_count: UInt32;
    
    {$region constructor's}
    
    static constructor;
    
    public constructor(first_ptr: IntPtr; item_count: UInt32);
    begin
      self.first_ptr  := first_ptr;
      self.item_count := item_count;
    end;
    public constructor(item_count: UInt32);
    begin
      self.item_count := item_count;
      Alloc;
    end;
    public constructor;
    begin
      self.first_ptr  := IntPtr.Zero;
      self.item_count := 0;
    end;
    
    public static function operator implicit(area: NativeArrayArea<T>): NativeMemoryArea := area.UntypedArea;
    
    {$endregion constructor's}
    
    {$region property's}
    
    public static property ItemSize: integer read Marshal.SizeOf(default(T));
    public property ByteSize: UIntPtr read new UIntPtr( item_count*uint64(ItemSize) );
    
    public property Length: cardinal read self.item_count;
    
    public property ItemAreaUnchecked[i: integer]: NativeValueArea<T> read new NativeValueArea<T>(self.first_ptr + i*ItemSize);
    
    private function GetAndCheckItemArea(i: integer): NativeValueArea<T>;
    begin
      if cardinal(i)>=self.item_count then raise new IndexOutOfRangeException;
      Result := ItemAreaUnchecked[i];
    end;
    public property ItemArea[i: integer]: NativeValueArea<T> read GetAndCheckItemArea;
    public property Item[i: integer]: T read ItemArea[i].Value write ItemArea[i].Value := value; default;
    
    public property SliceUnchecked[r: IntRange]: NativeArrayArea<T> read
    new NativeArrayArea<T>( ItemAreaUnchecked[r.Low].ptr, r.High-r.Low+1 );
    private function GetSliceAndCheck(r: IntRange): NativeArrayArea<T>;
    begin
      if r.Low<0 then raise new IndexOutOfRangeException('r.Low');
      if cardinal(r.High)>=self.item_count then raise new IndexOutOfRangeException('r.High');
      Result := SliceUnchecked[r];
      if integer(Result.item_count)<0 then raise new ArgumentOutOfRangeException('r.Count');
    end;
    public property Slice[r: IntRange]: NativeArrayArea<T> read GetSliceAndCheck;
    
    private function GetManagedCopy: array of T;
    begin
      Result := new T[self.item_count];
      self.UntypedArea.CopyTo(Result);
    end;
    public property ManagedCopy: array of T read GetManagedCopy write
    begin
      if value.Length<>self.item_count then raise new ArgumentException($'%Err:NativeArrayArea:ManagedCopy:WriteSize%');
      self.UntypedArea.CopyFrom(value);
    end;
    
    public property UntypedArea: NativeMemoryArea read new NativeMemoryArea(self.first_ptr, self.ByteSize);
    
    {$endregion property's}
    
    {$region Alloc/Release}
    
    public property IsAllocated: boolean read self.first_ptr<>IntPtr.Zero;
    
    public procedure Alloc;
    begin
      var temp := self.UntypedArea;
      temp.Alloc;
      self.first_ptr := temp.ptr;
    end;
    public procedure Release;
    begin
      var temp := self.UntypedArea;
      temp.Release;
      self.first_ptr := temp.ptr;
    end;
    public function TryRelease: boolean;
    begin
      Result := false;
      var temp := self.UntypedArea;
      temp.ptr := Interlocked.Exchange(self.first_ptr, IntPtr.Zero);
      if not temp.IsAllocated then exit;
      temp.Release;
      self.first_ptr := temp.ptr;
      Result := true;
    end;
    
    {$endregion Alloc/Release}
    
    public function ToString: string; override :=
    $'{TypeName(self)}:${first_ptr.ToString(''X'')}[{item_count}]';
    
  end;
  
  {$endregion NativeArrayArea}
  
  {$endregion NativeArea}
  
  {$region Native}
  
  {$region NativeMemory}
  
  NativeMemory = partial class(IDisposable)
    private _area: NativeMemoryArea;
    
    {$region constructor's}
    
    public constructor(sz: UIntPtr);
    begin
      self._area.sz := sz;
      self._area.Alloc;
    end;
    private constructor := raise new InvalidOperationException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    public property Area: NativeMemoryArea read _area;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose :=
    if Area.TryRelease then GC.SuppressFinalize(self);
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    public function ToString: string; override :=
    $'{TypeName(self)}:${Area.ptr.ToString(''X'')}[{Area.sz}]';
    
  end;
  
  {$endregion NativeMemory}
  
  {$region NativeValue}
  
  NativeValue<T> = partial class(IDisposable)
  where T: record;
    private _area := new NativeValueArea<T>(true);
    
    {$region constructor's}
    
    public constructor := self.AreaUntyped.FillZero;
    public constructor(o: T) := self.Value := o;
    public static function operator implicit(o: T): NativeValue<T> := new NativeValue<T>(o);
    
    {$endregion constructor's}
    
    {$region property's}
    
    public static property ValueSize: integer read NativeValueArea&<T>.ValueSize;
    
    public property Area: NativeValueArea<T> read _area;
    public property AreaUntyped: NativeMemoryArea read Area.UntypedArea;
    
    public property Pointer: ^T read Area.Pointer;
    public property Value: T read Area.Value write Area.Value := value;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose :=
    if Area.TryRelease then GC.SuppressFinalize(self);
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    public function ToString: string; override :=
    $'{TypeName(self)}{{ {_ObjectToString(Value)} }}';
    
  end;
  
  {$endregion NativeValue}
  
  {$region NativeArray}
  
  NativeArray<T> = partial class
  where T: record;
    private _area: NativeArrayArea<T>;
    
    {$region constructor's}
    
    private procedure AllocArea(length: UInt32) :=
    self._area := new NativeArrayArea<T>(length);
    public constructor(length: UInt32);
    begin
      AllocArea(length);
      self.AreaUntyped.FillZero;
    end;
    public constructor(a: array of T);
    begin
      AllocArea(a.Length);
      self.AreaUntyped.CopyFrom(a);
    end;
    
    private constructor := raise new InvalidOperationException;
    
    {$endregion constructor's}
    
    {$region Method's}
    
    public function IndexOf(item: T): integer?;
    begin
      Result := nil;
      for var i := 0 to Length-1 do
        if self.Item[i]=item then
        begin
          Result := i;
          break;
        end;
    end;
    
    {$endregion Method's}
    
    {$region property's}
    
    public static property ItemSize: integer read NativeArrayArea&<T>.ItemSize;
    
    public property Area: NativeArrayArea<T> read self._area;
    public property AreaUntyped: NativeMemoryArea read Area.UntypedArea;
    
    public property Length: cardinal read self.Area.item_count;
    
    public property ItemAreaUnchecked[i: integer]: NativeValueArea<T> read Area.ItemAreaUnchecked[i];
    public property ItemArea[i: integer]: NativeValueArea<T> read Area.ItemArea[i];
    public property Item[i: integer]: T read Area[i] write Area[i] := value; default;
    
    public property SliceAreaUnchecked[r: IntRange]: NativeArrayArea<T> read Area.SliceUnchecked[r];
    public property SliceArea[r: IntRange]: NativeArrayArea<T> read Area.Slice[r];
    
    {$endregion property's}
    
  end;
  
  NativeArrayEnumerator<T> = record(IEnumerator<T>)
  where T: record;
    private a: NativeArray<T>;
    private i: integer;
    
    public constructor(a: NativeArray<T>);
    begin
      self.a := a;
      self.Reset;
    end;
    ///--
    public constructor := exit;
    
    public function MoveNext: boolean;
    begin
      i += 1;
      Result := i < a.Length;
    end;
    public procedure Reset := self.i := -1;
    
    public property Current: T read a[i];
    public property System.Collections.IEnumerator.Current: object read a[i];
    
    public procedure Dispose := a := nil;
    
  end;
  NativeArray<T> = partial class(IList<T>, IDisposable)
    
    {$region IList}
    
    public function System.Collections.Generic.IList<T>.IndexOf(item: T): integer := (self.IndexOf(item) ?? -1).Value;
    
    public procedure System.Collections.Generic.IList<T>.Insert(index: integer; item: T) := raise new NotSupportedException;
    public procedure System.Collections.Generic.IList<T>.RemoveAt(index: integer) := raise new NotSupportedException;
    
    {$endregion IList}
    
    {$region ICollection}
    
    //TODO #????
    ///--
    public property {System.Collections.Generic.ICollection<T>.}Count: integer read self.Length;
    public property System.Collections.Generic.ICollection<T>.IsReadOnly: boolean read boolean(true);
    
    public procedure System.Collections.Generic.ICollection<T>.Add(item: T) := raise new NotSupportedException;
    public function System.Collections.Generic.ICollection<T>.Remove(item: T): boolean;
    begin
      Result := false;
      raise new NotSupportedException;
    end;
    public procedure System.Collections.Generic.ICollection<T>.Clear := raise new NotSupportedException;
    
    public function Contains(item: T) := self.IndexOf(item) <> nil;
    
    public procedure CopyTo(&array: array of T; arrayIndex: integer);
    begin
      if arrayIndex+self.Length > &array.Length then raise new IndexOutOfRangeException;
      self.AreaUntyped.CopyTo(&array[arrayIndex]);
    end;
    
    {$endregion ICollection}
    
    {$region IEnumerable}
    
    public function GetEnumerator: System.Collections.Generic.IEnumerator<T> := new NativeArrayEnumerator<T>(self);
    public function System.Collections.IEnumerable.GetEnumerator: System.Collections.IEnumerator := new NativeArrayEnumerator<T>(self);
    
    {$endregion IEnumerable}
    
    {$region IDisposable}
    
    public procedure Dispose :=
    if Area.TryRelease then GC.SuppressFinalize(self);
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      sb += TypeName(self);
      sb += '{';
      if self.Length<>0 then
      begin
        sb += ' ';
        //TODO #????: as
        foreach var x in self as IList<T> do
        begin
          sb += _ObjectToString(x);
          sb += ', ';
        end;
        sb.Length -= ', '.Length;
        sb += ' ';
      end;
      sb += '}';
      Result := sb.ToString;
    end;
    
  end;
  
  {$endregion NativeArray}
  
  {$endregion Native}
  
  {$endregion TODO MOVE}
  
  {$region Re-definition's}
  
  CLDeviceType              = OpenCL.DeviceType;
  CLDeviceAffinityDomain    = OpenCL.DeviceAffinityDomain;
  
  {$endregion Re-definition's}
  
  {$region OpenCLABCInternalException}
  
  OpenCLABCInternalException = sealed class(Exception)
    
    private constructor(message: string) :=
    inherited Create(message);
//    private constructor(message: string; ec: ErrorCode) :=
//    inherited Create($'{message} with {ec}');
    private constructor(ec: ErrorCode) :=
    inherited Create(OpenCLException.Create(ec).Message);
    private constructor :=
    inherited Create($'%Err:NoParamCtor%');
    
    private const RelayErrorCode = integer.MinValue;
    private static procedure RaiseIfError(ec: ErrorCode) :=
    if ec.IS_ERROR and (ec.val<>RelayErrorCode) then raise new OpenCLABCInternalException(ec);
    
  end;
  
  {$endregion OpenCLABCInternalException}
  
  {$region DEBUG}
  
  {$region EventDebug}{$ifdef EventDebug}
  
  ///
  EventRetainReleaseData = record
    private is_release: boolean;
    private reason: string;
    
    private static debug_time_counter := Stopwatch.StartNew;
    private time := debug_time_counter.Elapsed;
    
    public constructor(is_release: boolean; reason: string);
    begin
      self.is_release := is_release;
      self.reason := reason;
    end;
    //TODO Реализация yield вызывает этот конструктор
//    public constructor := raise new OpenCLABCInternalException;
    
    private function GetActStr := is_release ? 'Released' : 'Retained';
    public function ToString: string; override :=
    $'{time} | {GetActStr} when: {reason}';
    
  end;
  //TODO #2680
  ///
  TimeNString = auto class
    t: TimeSpan;
    s: string;
  end;
  ///
  EventUseLog = sealed class
    private log_lines := new List<EventRetainReleaseData>;
    private ref_c := 0;
    
    private procedure Retain(reason: string) :=
    lock self do
    begin
      log_lines += new EventRetainReleaseData(false, reason);
      ref_c += 1;
    end;
    
    private procedure Release(reason: string) :=
    lock self do
    begin
      log_lines += new EventRetainReleaseData(true, reason);
      ref_c -= 1;
    end;
    
    private function MakeReports: sequence of array of TimeNString;
    begin
      var res := new List<TimeNString>;
      var c := 0;
      foreach var act in log_lines do
      begin
        c += if act.is_release then -1 else +1;
        res += new TimeNString(act.time, $'{c,3} | {act}');
        if c=0 then
        begin
          yield res.ToArray;
          res.Clear;
        end;
      end;
      if res.Count=0 then exit;
      yield res.ToArray;
    end;
    
  end;
  ///
  EventDebug = static class
    
    private static Logs := new ConcurrentDictionary<cl_event, EventUseLog>;
    private static function LogFor(ev: cl_event) := Logs.GetOrAdd(ev, ev->new EventUseLog);
    
    {$region Log lines}
    
    public static procedure RegisterEventRetain(ev: cl_event; reason: string) :=
    if ev=cl_event.Zero then raise new OpenCLABCInternalException($'Zero event retain') else
    LogFor(ev).Retain(reason);
    
    public static procedure RegisterEventRelease(ev: cl_event; reason: string) :=
    begin
      VerifyExists(ev, reason);
      LogFor(ev).Release(reason);
    end;
    
    {$endregion Log lines}
    
    public static procedure ReportEventLogs(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      var newest_report := TimeSpan.Zero;
      foreach var (r,ev) in Logs.SelectMany(kvp->
        kvp.Value.MakeReports.Tabulate(r->kvp.Key)
      ).OrderBy(\(r,ev)->r[0].t) do
      begin
        if r[0].t>newest_report then
          otp.WriteLine;
        otp.WriteLine($'Logging state change of {ev}:');
        foreach var l in r do
          otp.WriteLine(l.s);
        newest_report := |newest_report, r[^1].t|.Max;
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    private static procedure ReportProblem(reason: string) := lock output do
    begin
      ReportEventLogs(Console.Error);
      Sleep(1000);
      raise new OpenCLABCInternalException(reason);
    end;
    
    public static procedure VerifyExists(ev: cl_event; reason: string) :=
    if LogFor(ev).ref_c<=0 then ReportProblem($'Event {ev} was released before last use ({reason})');
    
    public static procedure FinallyReport;
    begin
      if Logs.Count=0 then exit;
      foreach var ev in Logs.Keys do
        if LogFor(ev).ref_c<>0 then ReportProblem($'Event {ev} was not released');
      
      var total_ev_count := Logs.Values.Sum(l->l.log_lines.Select(act->act.is_release ? -1 : +1).PartialSum.CountOf(0));
      $'[EventDebug]: {total_ev_count} event''s created'.Println;
    end;
    
  end;
  
  {$endif EventDebug}{$endregion EventDebug}
  
  {$region QueueDebug}{$ifdef QueueDebug}
  
  ///
  QueueDebug = static class
    
    private static QueueUses := new ConcurrentDictionary<cl_command_queue, ConcurrentQueue<string>>;
    private static function QueueUsesFor(cq: cl_command_queue) := QueueUses.GetOrAdd(cq, cq->new ConcurrentQueue<string>);
    private static procedure Add(cq: cl_command_queue; use: string) := QueueUsesFor(cq).Enqueue(use);
    
    public static procedure ReportQueueUses(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      foreach var kvp in QueueUses do
      begin
        otp.WriteLine($'Logging uses of {kvp.Key}:');
        foreach var use in kvp.Value do
          otp.WriteLine(use);
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static procedure FinallyReport :=
    if QueueUses.Count<>0 then
    begin
      var total_q_count := QueueUses.Keys.Sum(q->
      begin
        Result := 0;
        var last_return := false;
        foreach var use in QueueUses[q] do
        begin
          last_return := ('- return -' in use) or ('- last q -' in use);
          Result += ord(last_return);
        end;
        if last_return then exit;
        ReportQueueUses(Console.Error);
        Sleep(1000);
        raise new OpenCLABCInternalException(q.ToString);
      end);
      $'[QueueDebug]: {total_q_count} queue''s created'.Println;
    end;
    
  end;
  
  {$endif QueueDebug}{$endregion QueueDebug}
  
  {$region WaitDebug}{$ifdef WaitDebug}
  
  ///
  WaitDebug = static class
    
    private static WaitActions := new ConcurrentDictionary<object, ConcurrentQueue<string>>;
    
    private static procedure RegisterAction(handler: object; act: string) :=
    WaitActions.GetOrAdd(handler, hc->new ConcurrentQueue<string>).Enqueue(act);
    
    public static procedure ReportWaitActions(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      foreach var kvp in WaitActions do
      begin
        otp.WriteLine($'Logging actions of handler[{kvp.Key.GetHashCode}]:');
        foreach var act in kvp.Value do
          otp.WriteLine(act);
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static procedure FinallyReport := if WaitActions.Count<>0 then
    $'[WaitDebug]: {WaitActions.Count} wait handler''s created'.Println;
    
  end;
  
  {$endif WaitDebug}{$endregion WaitDebug}
  
  {$region ExecDebug}{$ifdef ExecDebug}
  
  ///
  ExecDebug = static class
    
    private static ExecCacheTries := new ConcurrentDictionary<string, ConcurrentQueue<(boolean,string)>>;
    
    private static count_of_type := new ConcurrentDictionary<System.Type, integer>;
    private static prev_names := new ConcurrentDictionary<(System.Type,integer), string>;
    private static function MakeName(command: object) :=
    prev_names.GetOrAdd((command.GetType,command.GetHashCode), t->
    begin
      var n := count_of_type.AddOrUpdate(t[0], 1, (t,n)->n+1);
      Result := $'{TypeToTypeName(t[0])}#{n}';
    end);
    
    private static procedure RegisterExecCacheTry(command: object; is_new: boolean; descr: string) :=
    ExecCacheTries.GetOrAdd(MakeName(command), name->new ConcurrentQueue<(boolean,string)>).Enqueue((is_new,descr));
    
    public static procedure ReportExecCache(otp: System.IO.TextWriter := Console.Out) :=
    lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      foreach var kvp in ExecCacheTries.OrderBy(kvp->kvp.Key) do
      begin
        otp.WriteLine($'Logging caching tries of {kvp.key}:');
        foreach var (is_new, descr) in kvp.Value do
          otp.WriteLine(descr);
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static procedure FinallyReport := if ExecCacheTries.Count<>0 then
    $'[ExecDebug]: {ExecCacheTries.Values.Sum(q->q.Count(t->t[0]))} cache entries created'.Println;
    
  end;
  
  {$endif ExecDebug}{$endregion ExecDebug}
  
  {$endregion DEBUG}
  
  {$region WrapperProperties}
  
  {%WrapperProperties\Interface!WrapperProperties.pas%}
  
  {$endregion WrapperProperties}
  
  {$region Wrappers}
  // For parameters of CCQ-involved methods
  CommandQueue<T> = abstract partial class end;
  CLKernelArg = abstract partial class end;
  
  {$region CLContext data}
  
  {$region CLPlatform}
  
  CLPlatform = partial class
    private ntv: cl_platform_id;
    
    public constructor(ntv: cl_platform_id) := self.ntv := ntv;
    private constructor := raise new OpenCLABCInternalException;
    
    private static all_need_init := true;
    private static _all: IList<CLPlatform>;
    private static function MakeAll: IList<CLPlatform>;
    begin
      Result := nil;
      
      var c: UInt32;
      begin
        var ec := cl.GetPlatformIDs(0, IntPtr.Zero, c);
        if ec=ErrorCode.PLATFORM_NOT_FOUND then exit;
        OpenCLABCInternalException.RaiseIfError(ec);
      end;
      if c=0 then exit;
      
      var all_arr := new cl_platform_id[c];
      OpenCLABCInternalException.RaiseIfError(
        cl.GetPlatformIDs(c, all_arr[0], IntPtr.Zero)
      );
      
      Result := new ReadOnlyCollection<CLPlatform>(all_arr.ConvertAll(pl->new CLPlatform(pl)));
    end;
    private static function GetAll: IList<CLPlatform>;
    begin
      if all_need_init then
      begin
        _all := MakeAll;
        all_need_init := false;
      end;
      Result := _all;
    end;
    public static property All: IList<CLPlatform> read GetAll;
    
  end;
  
  {$endregion CLPlatform}
  
  {$region CLDevice}
  
  CLDevice = partial class
    private ntv: cl_device_id;
    
    private constructor(ntv: cl_device_id) := self.ntv := ntv;
    public static function FromNative(ntv: cl_device_id): CLDevice;
    
    private constructor := raise new OpenCLABCInternalException;
    
    private function GetBaseCLPlatform: CLPlatform;
    begin
      var pl: cl_platform_id;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetDeviceInfo(self.ntv, DeviceInfo.DEVICE_PLATFORM, new UIntPtr(sizeof(cl_platform_id)), pl, IntPtr.Zero)
      );
      Result := new CLPlatform(pl);
    end;
    public property BaseCLPlatform: CLPlatform read GetBaseCLPlatform;
    
    public static function GetAllFor(pl: CLPlatform; t: CLDeviceType): array of CLDevice;
    begin
      
      var c: UInt32;
      var ec := cl.GetDeviceIDs(pl.ntv, t, 0, IntPtr.Zero, c);
      if ec=ErrorCode.DEVICE_NOT_FOUND then exit;
      OpenCLABCInternalException.RaiseIfError(ec);
      
      var all := new cl_device_id[c];
      OpenCLABCInternalException.RaiseIfError(
        cl.GetDeviceIDs(pl.ntv, t, c, all[0], IntPtr.Zero)
      );
      
      Result := all.ConvertAll(dvc->new CLDevice(dvc));
    end;
    public static function GetAllFor(pl: CLPlatform) := GetAllFor(pl, CLDeviceType.DEVICE_TYPE_GPU);
    
  end;
  
  {$endregion CLDevice}
  
  {$region CLSubDevice}
  
  CLSubDevice = partial class(CLDevice)
    private _parent: cl_device_id;
    public property Parent: CLDevice read CLDevice.FromNative(_parent);
    
    private constructor(parent, ntv: cl_device_id);
    begin
      inherited Create(ntv);
      self._parent := parent;
    end;
    
    private constructor := inherited;
    
    protected procedure Finalize; override :=
    OpenCLABCInternalException.RaiseIfError(cl.ReleaseDevice(ntv));
    
  end;
  
  {$endregion CLSubDevice}
  
  {$region CLContext}
  
  CLContext = partial class
    private ntv: cl_context;
    
    private dvcs: IList<CLDevice>;
    public property AllDevices: IList<CLDevice> read dvcs;
    
    private main_dvc: CLDevice;
    public property MainDevice: CLDevice        read main_dvc;
    
    private function GetAllNtvDevices: array of cl_device_id;
    begin
      Result := new cl_device_id[dvcs.Count];
      for var i := 0 to Result.Length-1 do
        Result[i] := dvcs[i].ntv;
    end;
    
    {$region Default}
    
    private static default_was_inited := 0;
    private static _default: CLContext;
    
    private static function GetDefault: CLContext;
    begin
      if Interlocked.CompareExchange(default_was_inited, 1, 0)=0 then
      begin
        var c :=
          {$ifdef ForceMaxDebug}
          //TODO #????: Лишние ()
          LoadTestContext() ??
          {$endif ForceMaxDebug}
          MakeNewDefaultContext;
        // Another exchange, because Default could be explicitly set
        Interlocked.CompareExchange(_default, c, nil);
      end;
      Result := _default;
    end;
    private static procedure SetDefault(new_default: CLContext);
    begin
      default_was_inited := 1;
      _default := new_default;
    end;
    public static property &Default: CLContext read GetDefault write SetDefault;
    
    protected static function MakeNewDefaultContext: CLContext;
    begin
      Result := nil;
      
      var pls := CLPlatform.All;
      if pls=nil then exit;
      
      foreach var pl in pls do
      begin
        var dvcs := CLDevice.GetAllFor(pl);
        if dvcs=nil then continue;
        Result := new CLContext(dvcs);
        exit;
      end;
      
      foreach var pl in pls do
      begin
        var dvcs := CLDevice.GetAllFor(pl, CLDeviceType.DEVICE_TYPE_ALL);
        if dvcs=nil then continue;
        Result := new CLContext(dvcs);
        exit;
      end;
      
    end;
    
    public static procedure GenerateAndCheckDefault(test_size: integer := 1024*24; test_max_seconds: real := 0.5);
    
    private static function LoadTestContext: CLContext;
    
    {$endregion Default}
    
    {$region constructor's}
    
    private static procedure CheckMainDevice(main_dvc: CLDevice; dvc_lst: IList<CLDevice>) :=
    if not dvc_lst.Contains(main_dvc) then raise new ArgumentException($'%Err:CLContext:WrongMainDvc%');
    
    public constructor(dvcs: IList<CLDevice>; main_dvc: CLDevice);
    begin
      CheckMainDevice(main_dvc, dvcs);
      
      self.dvcs := if dvcs.IsReadOnly then dvcs else new ReadOnlyCollection<CLDevice>(dvcs.ToArray);
      var ntv_dvcs := GetAllNtvDevices;
      
      var ec: ErrorCode;
      self.ntv := cl.CreateContext(nil, ntv_dvcs.Count, ntv_dvcs, nil, IntPtr.Zero, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
      self.main_dvc := main_dvc;
    end;
    public constructor(params dvcs: array of CLDevice) := Create(dvcs, dvcs[0]);
    
    protected static function GetContextDevices(ntv: cl_context): array of CLDevice;
    begin
      
      var sz: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetContextInfo(ntv, ContextInfo.CONTEXT_DEVICES, UIntPtr.Zero, IntPtr.Zero, sz)
      );
      
      var res := new cl_device_id[uint64(sz) div cl_device_id.Size];
      OpenCLABCInternalException.RaiseIfError(
        cl.GetContextInfo(ntv, ContextInfo.CONTEXT_DEVICES, sz, res[0], IntPtr.Zero)
      );
      
      Result := res.ConvertAll(dvc->new CLDevice(dvc));
    end;
    private procedure InitFromNtv(ntv: cl_context; dvcs: IList<CLDevice>; main_dvc: CLDevice);
    begin
      CheckMainDevice(main_dvc, dvcs);
      OpenCLABCInternalException.RaiseIfError( cl.RetainContext(ntv) );
      self.ntv := ntv;
      // Копирование должно происходить в вызывающих методах
      self.dvcs := if dvcs.IsReadOnly then dvcs else new ReadOnlyCollection<CLDevice>(dvcs);
      self.main_dvc := main_dvc;
    end;
    public constructor(ntv: cl_context; main_dvc: CLDevice) :=
    InitFromNtv(ntv, GetContextDevices(ntv), main_dvc);
    
    public constructor(ntv: cl_context);
    begin
      var dvcs := GetContextDevices(ntv);
      InitFromNtv(ntv, dvcs, dvcs[0]);
    end;
    
    private constructor(c: CLContext; main_dvc: CLDevice) :=
    InitFromNtv(c.ntv, c.dvcs, main_dvc);
    public function MakeSibling(new_main_dvc: CLDevice) := new CLContext(self, new_main_dvc);
    
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseContext(new cl_context(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion constructor's}
    
  end;
  
  {$endregion CLContext}
  
  {$endregion CLContext data}
  
  {$region CLKernel data}
  
  {$region CLCodeOptions}
  
  CLCodeOptions = abstract class
    
    public constructor(c: CLContext) := self.BuildContext := c;
    public constructor := Create(CLContext.Default);
    
    public auto property BuildContext: CLContext;
    
    public auto property KeepLog: boolean := true;
    
    protected procedure ToString(res: StringBuilder); abstract;
    public function ToString: string; override;
    begin
      var res := new StringBuilder;
      ToString(res);
      Result := res.ToString;
    end;
    
  end;
  
  CLCodeLibOptions = class(CLCodeOptions)
    
    public static function operator implicit(c: CLContext): CLCodeLibOptions := new CLCodeLibOptions(c);
    
    public auto property ForceAcceptProgramLinkOptions: boolean := false;
    
    protected procedure ToString(res: StringBuilder); override;
    begin
//      inherited; // abstract
      
      res += '-create-library ';
      
      if ForceAcceptProgramLinkOptions then
        res += '-enable-link-options ';
      
    end;
    
  end;
  
  CLProgramOptions = abstract class(CLCodeOptions)
    
    public auto property MathDenormsAreZero: boolean := false;
    
    public auto property OptSignedZero: boolean := false;
    
    public property OptUnsafeMath: boolean
    read MathDenormsAreZero and not OptSignedZero
    write
    begin
      MathDenormsAreZero  := value;
      OptSignedZero       := not value;
    end; virtual;
    
    public auto property OptNoDenorms: boolean := false;
    
    public property OptFastMath: boolean
    read OptUnsafeMath and OptNoDenorms
    write
    begin
      OptUnsafeMath := value;
      OptNoDenorms  := value;
    end;
    
    public auto property OptRequireIFP: boolean := true;
    
    protected procedure ToString(res: StringBuilder); override;
    begin
//      inherited; // abstract
      
      if OptFastMath then
        res += '-cl-fast-relaxed-math ' else
      begin
        
        if OptUnsafeMath then
          res += '-cl-unsafe-math-optimizations ' else
        begin
          
          if MathDenormsAreZero then
            res += '-cl-denorms-are-zero ';
          
          // Only for ProgramComp
//          if OptCanUseMAD then
//            res += '-cl-mad-enable ';
          
          if not OptSignedZero then
            res += '-cl-no-signed-zeros ';
          
        end;
        
        if OptNoDenorms then
          res += '-cl-finite-math-only ';
        
      end;
      
      if not OptRequireIFP then
        res += '-cl-no-subgroup-ifp ';
      
    end;
    
  end;
  
  CLCodeDefines = Dictionary<string, string>;
  CLProgramCompOptions = class(CLProgramOptions)
    
    public static function operator implicit(c: CLContext): CLProgramCompOptions := new CLProgramCompOptions(c);
    
    public auto property Defines: CLCodeDefines := new CLCodeDefines;
    
    public auto property MathSinglePrecisionConstant: boolean := false;
    
    public auto property MathFP32CorrectlyRoundedDivideSqrt: boolean := false;
    
    public auto property Optimize: boolean := true;
    
    public auto property OptOnlyUniformWorkGroups: boolean := false;
    
    public auto property OptCanUseMAD: boolean := false;
    
    public property OptUnsafeMath: boolean
    read MathDenormsAreZero and OptCanUseMAD and not OptSignedZero
    write
    begin
      MathDenormsAreZero  := value;
      OptCanUseMAD        := value;
      OptSignedZero       := not value;
    end; override;
    
    public auto property WarningLevel: (
      WL_Ignore,
      WL_Warn,
      WL_Error
    ) := WL_Warn;
    
    public auto property Version: (integer, integer) := nil;
    public procedure LowerVersionToSupported;
    
    public auto property CLKernelArgInfo: boolean := true;
    
    public auto property LiveEnqueueDebug: boolean := false;
    
    protected procedure ToString(res: StringBuilder); override;
    begin
      inherited;
      
      foreach var kvp in Defines do
      begin
        res += '-D ';
        res += kvp.Key;
        if kvp.Value<>nil then
        begin
          res += '=';
          res += kvp.Value;
        end;
        res += ' ';
      end;
      
      if MathSinglePrecisionConstant then
        res += '-cl-single-precision-constant ';
      
      if MathFP32CorrectlyRoundedDivideSqrt then
        res += '-cl-fp32-correctly-rounded-divide-sqrt ';
      
      if not Optimize then
        res += '-cl-opt-disable ';
      
      if OptOnlyUniformWorkGroups then
        res += '-cl-uniform-work-group-size ';
      
      if not OptUnsafeMath and OptCanUseMAD then
        res += '-cl-mad-enable ';
      
      case WarningLevel of
        WL_Ignore:  res += '-w ';
        WL_Warn:    ;
        WL_Error:   res += '-Werror ';
        else raise new System.ArgumentException($'%Err:ProgramOptions:WarningLevel:Invalid%');
      end;
      
      if Version<>nil then
      begin
        res += '-cl-std=CL';
        res.Append(Version[0]);
        res += '.';
        res.Append(Version[1]);
        res += ' ';
      end;
      
      if CLKernelArgInfo then
        res += '-cl-kernel-arg-info ';
      
      if LiveEnqueueDebug then
        res += '-g ';
      
    end;
    
  end;
  
  CLProgramLinkOptions = class(CLProgramOptions)
    
    public static function operator implicit(c: CLContext): CLProgramLinkOptions := new CLProgramLinkOptions(c);
    
//    protected procedure ToString(res: StringBuilder); override;
//    begin
//      inherited;
//      
//    end;
    
  end;
  
  {$endregion CLCodeOptions}
  
  {$region CLCode}
  
  {$region CLCode}
  
  CLCode = abstract partial class
    private ntv: cl_program;
    
    protected constructor(code_text: string; c: CLContext);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateProgramWithSource(c.ntv, 1,|code_text|,nil, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    
    protected constructor(ntv: cl_program; need_retain: boolean);
    begin
      if need_retain then
        OpenCLABCInternalException.RaiseIfError(
          cl.RetainProgram(ntv)
        );
      self.ntv := ntv;
    end;
    
    private constructor := raise new OpenCLABCInternalException;
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseProgram(new cl_program(prev)) );
    end;
    protected procedure Finalize; override := Dispose;
    
  end;
  
  {$endregion CLCode}
  
  {$region CLHeaderCode}
  
  CLHeaderCode = partial class(CLCode)
    
    public constructor(code_text: string; c: CLContext := nil) := inherited Create(code_text, c??CLContext.Default);
    public constructor(ntv: cl_program; need_retain: boolean := true) := inherited Create(ntv, need_retain);
    
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  {$endregion CLHeaderCode}
  
  {$region BinCLCode}
  
  BinCLCode = abstract partial class(CLCode)
    
    {$region Utils}
    
    protected static function GetLastLog(ntv: cl_program; d: cl_device_id): string;
    begin
      
      var sz: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetProgramBuildInfo(ntv, d, ProgramBuildInfo.PROGRAM_BUILD_LOG, UIntPtr.Zero,IntPtr.Zero,sz)
      );
      
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        OpenCLABCInternalException.RaiseIfError(
          cl.GetProgramBuildInfo(ntv, d, ProgramBuildInfo.PROGRAM_BUILD_LOG, sz,str_ptr,IntPtr.Zero)
        );
        Result := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
    end;
    
    protected static procedure CheckBuildFail(ntv: cl_program; ec, fail_code: ErrorCode; fail_descr: string; dvcs: sequence of CLDevice);
    begin
      
      // It is common OpenCL impl misstake, to return BUILD_PROGRAM_FAILURE wherever
      if (ec=fail_code) or (ec=ErrorCode.BUILD_PROGRAM_FAILURE) then
//      if ec<>ErrorCode.SUCCESS then
      begin
        var sb := new StringBuilder(fail_descr);
        
        foreach var dvc in dvcs do
        begin
          sb += #10#10;
          sb += dvc.ToString;
          sb += ':'#10;
          sb += GetLastLog(ntv, dvc.ntv);
        end;
        
        raise new InvalidOperationException(sb.ToString);
      end else
        OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    
    {$endregion Utils}
    
    {$region Logs}
    
    private logs := new Dictionary<cl_device_id, string>;
    public property BuildLog[d: CLDevice]: string read logs[d.ntv];
    
    protected procedure SaveLogsFor(dvcs: sequence of CLDevice);
    begin
      {$ifdef DEBUG}
      if logs.Count<>0 then raise new OpenCLABCInternalException($'Multiple calls to SaveLogsFor from {TypeName(self)}');
      {$endif DEBUG}
//      logs.Clear;
      foreach var d in dvcs do logs[d.ntv] := GetLastLog(self.ntv, d.ntv);
    end;
    
    {$endregion Logs}
    
    {$region Serialize}
    
    public function Serialize: array of array of byte;
    begin
      var sz: UIntPtr;
      
      OpenCLABCInternalException.RaiseIfError( cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARY_SIZES, UIntPtr.Zero, nil, sz) );
      var szs := new UIntPtr[sz.ToUInt64 div UIntPtr.Size];
      OpenCLABCInternalException.RaiseIfError( cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARY_SIZES, sz, szs[0], IntPtr.Zero) );
      
      var res := szs.ConvertAll(sz_i->new NativeArray<byte>(sz_i.ToUInt32));
      
      OpenCLABCInternalException.RaiseIfError(
        cl.GetProgramInfo(ntv, ProgramInfo.PROGRAM_BINARIES, sz, res.ConvertAll(a->a.Area.first_ptr)[0], IntPtr.Zero)
      );
      
      Result := res.ConvertAll(a->a.Area.ManagedCopy);
      GC.KeepAlive(res);
    end;
    
    public procedure SerializeTo(bw: System.IO.BinaryWriter);
    begin
      var bin := Serialize;
      
      bw.Write(bin.Length);
      foreach var a in bin do
      begin
        bw.Write(a.Length);
        bw.Write(a);
      end;
      
    end;
    public procedure SerializeTo(str: System.IO.Stream) :=
    SerializeTo(new System.IO.BinaryWriter(str));
    
    {$endregion Serialize}
    
    {$region Deserialize}
    
    protected static function DeserializeNative(c: CLContext; bin: array of array of byte): cl_program;
    begin
      var ec: ErrorCode;
      
      var dvcs := c.GetAllNtvDevices;
      //TODO Отдельные эррор коды?
      Result := cl.CreateProgramWithBinary(
        c.ntv, dvcs.Length, dvcs,
        bin.ConvertAll(a->new UIntPtr(a.Length)), bin,
        nil,ec
      );
      
      OpenCLABCInternalException.RaiseIfError(ec);
    end;
    
    protected static function LoadBins(br: System.IO.BinaryReader) :=
    ArrGen(br.ReadInt32, i->
    begin
      var len := br.ReadInt32;
      Result := br.ReadBytes(len);
      if Result.Length<>len then raise new System.IO.EndOfStreamException;
    end);
    
    {$endregion}
    
  end;
  
  {$endregion BinCLCode}
  
  {$region LinkableCLCode}
  
  LinkableCLCode = abstract partial class(BinCLCode)
    
  end;
  
  BinCLCode = abstract partial class(CLCode)
    
    private function link_ntv(bins: IList<LinkableCLCode>; opt: CLCodeOptions): cl_program;
    begin
      var bin_ntvs := new cl_program[bins.Count];
      for var i := 0 to bin_ntvs.Length-1 do
        bin_ntvs[i] := bins[i].ntv;
      
      var ec: ErrorCode;
      Result := cl.LinkProgram(opt.BuildContext.ntv, 0,nil, opt.ToString, bin_ntvs.Length,bin_ntvs, nil,IntPtr.Zero, ec);
      
      if Result=cl_program.Zero then
        //TODO В этом случае нельзя получить лог???
        OpenCLABCInternalException.RaiseIfError(ec) else
        CheckBuildFail(Result,
          ec, ErrorCode.LINK_PROGRAM_FAILURE,
          $'%Err:CLCode:BuildFail:Link%', opt.BuildContext.AllDevices
        );
      
    end;
    public constructor(bins: IList<LinkableCLCode>; opt: CLCodeOptions);
    begin
      inherited Create(link_ntv(bins, opt), false);
      if opt.KeepLog then self.SaveLogsFor(opt.BuildContext.AllDevices);
    end;
    
  end;
  
  {$endregion LinkableCLCode}
  
  {$region CLCompCode}
  
  CLCompCode = partial class(LinkableCLCode)
    
    {$region constructor's}
    
    public constructor(code_text: string; headers: Dictionary<string, CLHeaderCode> := nil; opt: CLProgramCompOptions := nil);
    begin
      inherited Create(code_text, (opt??new CLProgramCompOptions).BuildContext);
      opt := opt??new CLProgramCompOptions;
      
      var ec: ErrorCode;
      if headers=nil then
        ec := cl.CompileProgram(self.ntv, 0,nil, opt.ToString, 0,nil,nil, nil,IntPtr.Zero) else
      begin
        var hs := new cl_program[headers.Count];
        var hns := new string[headers.Count];
        foreach var kvp in headers index i do
        begin
          hs[i] := kvp.Value.ntv;
          hns[i] := kvp.Key;
        end;
        
        ec := cl.CompileProgram(self.ntv, 0,nil, opt.ToString, hs.Length,hs,hns, nil,IntPtr.Zero);
      end;
      
      CheckBuildFail(self.ntv,
        ec, ErrorCode.COMPILE_PROGRAM_FAILURE,
        $'%Err:CLCode:BuildFail:Compile%', opt.BuildContext.AllDevices
      );
      
      if opt.KeepLog then SaveLogsFor(opt.BuildContext.AllDevices);
    end;
    
    public constructor(ntv: cl_program; need_retain: boolean := true) := inherited Create(ntv, need_retain);
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region Deserialize}
    
    public static function Deserialize(bin: array of array of byte; c: CLContext := nil) :=
    new CLCompCode(DeserializeNative(c, bin), false);
    public static function DeserializeFrom(br: System.IO.BinaryReader; c: CLContext := nil) :=
    Deserialize(LoadBins(br), c);
    public static function DeserializeFrom(str: System.IO.Stream; c: CLContext := nil) :=
    DeserializeFrom(new System.IO.BinaryReader(str), c);
    
    {$endregion Deserialize}
    
  end;
  
  {$endregion CLCompCode}
  
  {$region CLCodeLib}
  
  CLCodeLib = partial class(LinkableCLCode)
    
    {$region constructor's}
    
    public constructor(bins: IList<LinkableCLCode>; opt: CLCodeLibOptions := nil) := inherited Create(bins, opt??new CLCodeLibOptions);
    public constructor(params bins: array of LinkableCLCode) := Create(bins as IList<LinkableCLCode>);
    
    public constructor(ntv: cl_program; need_retain: boolean := true) := inherited Create(ntv, need_retain);
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region Deserialize}
    
    public static function Deserialize(bin: array of array of byte; c: CLContext := nil) :=
    new CLCodeLib(DeserializeNative(c, bin), false);
    public static function DeserializeFrom(br: System.IO.BinaryReader; c: CLContext := nil) :=
    Deserialize(LoadBins(br), c);
    public static function DeserializeFrom(str: System.IO.Stream; c: CLContext := nil) :=
    DeserializeFrom(new System.IO.BinaryReader(str), c);
    
    {$endregion Deserialize}
    
  end;
  
  {$endregion CLCodeLib}
  
  {$region CLProgramCode}
  
  CLProgramCode = partial class(BinCLCode)
    
    {$region constructor's}
    
    public constructor(bins: IList<LinkableCLCode>; opt: CLProgramLinkOptions := nil) := inherited Create(bins, opt??new CLProgramLinkOptions);
    public constructor(params bins: array of LinkableCLCode) := Create(bins as IList<LinkableCLCode>);
    
    private procedure Build(opt: CLProgramCompOptions);
    begin
      var ec := cl.BuildProgram(self.ntv, 0,nil, opt.ToString, nil,IntPtr.Zero);
      
      CheckBuildFail(self.ntv,
        ec, ErrorCode.BUILD_PROGRAM_FAILURE,
        $'%Err:CLCode:BuildFail:Compile%', opt.BuildContext.AllDevices
      );
      
      if opt.KeepLog then SaveLogsFor(opt.BuildContext.AllDevices);
    end;
    public constructor(code_text: string; opt: CLProgramCompOptions := nil);
    begin
      inherited Create(code_text, if opt=nil then CLContext.Default else opt.BuildContext);
      self.Build(opt ?? new CLProgramCompOptions);
    end;
    
    public constructor(ntv: cl_program; need_retain: boolean := true) := inherited Create(ntv, need_retain);
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region Deserialize}
    
    public static function Deserialize(bin: array of array of byte; opt: CLProgramCompOptions := nil): CLProgramCode;
    begin
      if opt=nil then opt := new CLProgramCompOptions;
      
      Result := new CLProgramCode(
        DeserializeNative(opt.BuildContext, bin), false
      );
      
      Result.Build(opt);
    end;
    
    public static function DeserializeFrom(br: System.IO.BinaryReader; opt: CLProgramCompOptions := nil) :=
    Deserialize(LoadBins(br), opt);
    public static function DeserializeFrom(str: System.IO.Stream; opt: CLProgramCompOptions := nil) :=
    DeserializeFrom(new System.IO.BinaryReader(str), opt);
    
    {$endregion Deserialize}
    
    //TODO #2668
    public static function operator=(p1,p2: CLProgramCode) := p1.Equals(p2);
    
  end;
  
  {$endregion CLProgramCode}
  
  {$region BinCLCode.Deserialize}
  
  BinCLCode = abstract partial class(CLCode)
    
    public static function Deserialize(bin: array of array of byte; opt: CLProgramCompOptions := nil): BinCLCode;
    begin
      if opt=nil then opt := new CLProgramCompOptions;
      
      var ntv := DeserializeNative(opt.BuildContext, bin);
      
      var general_pt := ProgramBinaryType.PROGRAM_BINARY_TYPE_NONE;
      foreach var d in opt.BuildContext.AllDevices do
      begin
        var pt: ProgramBinaryType;
        OpenCLABCInternalException.RaiseIfError(
          cl.GetProgramBuildInfo(ntv,d.ntv, ProgramBuildInfo.PROGRAM_BINARY_TYPE, new UIntPtr(sizeof(ProgramBinaryType)),pt,IntPtr.Zero)
        );
        
        if general_pt=ProgramBinaryType.PROGRAM_BINARY_TYPE_NONE then
          general_pt := pt else
        if general_pt<>pt then
          raise new NotSupportedException($'%BinCLCode:Deserialize:ProgramBinaryType:Different%');
        
      end;
      
      if general_pt=ProgramBinaryType.PROGRAM_BINARY_TYPE_NONE then
        raise new NotSupportedException($'%BinCLCode:Deserialize:ProgramBinaryType:Missing%') else
      if general_pt=ProgramBinaryType.PROGRAM_BINARY_TYPE_COMPILED_OBJECT then
        Result := new CLCompCode(ntv,false) else
      if general_pt=ProgramBinaryType.PROGRAM_BINARY_TYPE_LIBRARY then
        Result := new CLCodeLib(ntv,false) else
      if general_pt=ProgramBinaryType.PROGRAM_BINARY_TYPE_EXECUTABLE then
      begin
        var res := new CLProgramCode(ntv,false);
        res.Build(opt);
        Result := res;
      end else
        raise new NotImplementedException(general_pt.ToString);
      
    end;
    
    public static function DeserializeFrom(br: System.IO.BinaryReader; opt: CLProgramCompOptions := nil) :=
    Deserialize(LoadBins(br), opt);
    public static function DeserializeFrom(str: System.IO.Stream; opt: CLProgramCompOptions := nil) :=
    DeserializeFrom(new System.IO.BinaryReader(str), opt);
    
  end;
  
  {$endregion BinCLCode.Deserialize}
  
  {$endregion CLCode}
  
  {$region CLKernel}
  
  CLKernel = partial class
    
    private code: CLProgramCode;
    public property CodeContainer: CLProgramCode read code;
    
    private k_name: string;
    public property Name: string read k_name;
    
    public function AllocNative: cl_kernel;
    public procedure ReleaseNative(ntv: cl_kernel);
    protected procedure AddExistingNative(ntv: cl_kernel);
    
    {$region constructor's}
    
    private constructor(code: CLProgramCode; k_name: string);
    begin
      self.code := code;
      self.k_name := k_name;
    end;
    
    public constructor(ntv: cl_kernel);
    begin
      AddExistingNative(ntv);
      
      var code_ntv: cl_program;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_PROGRAM, new UIntPtr(cl_program.Size), code_ntv, IntPtr.Zero)
      );
      self.code := new CLProgramCode(code_ntv, true);
      
      var sz: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, UIntPtr.Zero, IntPtr.Zero, sz)
      );
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        OpenCLABCInternalException.RaiseIfError(
          cl.GetKernelInfo(ntv, KernelInfo.KERNEL_FUNCTION_NAME, sz, str_ptr, IntPtr.Zero)
        );
        self.k_name := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {%ContainerMethods\CLKernel.Exec\Implicit.Interface!ContainerExecMethods.pas%}
    
  end;
  
  CLProgramCode = partial class
    
    public property KernelByName[kname: string]: CLKernel read new CLKernel(self, kname); default;
    
    public function GetAllKernels: array of CLKernel;
    begin
      
      var c: UInt32;
      OpenCLABCInternalException.RaiseIfError( cl.CreateKernelsInProgram(ntv, 0, IntPtr.Zero, c) );
      
      var res := new cl_kernel[c];
      OpenCLABCInternalException.RaiseIfError( cl.CreateKernelsInProgram(ntv, c, res[0], IntPtr.Zero) );
      
      Result := res.ConvertAll(k->new CLKernel(k));
    end;
    
  end;
  
  {$endregion CLKernel}
  
  {$endregion CLKernel data}
  
  {$region CLMemory}
  
  {$region CLMemoryUsage}
  
  CLMemoryUsage = record
    private data: integer;
    
    private const can_read_bit = 1;
    private const can_write_bit = 2
    private const none_bits = 0;
    private const read_write_bits = can_read_bit + can_write_bit;
    
    private constructor(data: integer) := self.data := data;
    public constructor(can_read, can_write: boolean) := Create(
      integer(can_read ) * can_read_bit +
      integer(can_write) * can_write_bit
    );
    private static function operator implicit(data: integer): CLMemoryUsage := new CLMemoryUsage(data);
    
    public static property None:      CLMemoryUsage read new CLMemoryUsage(false, false);
    public static property ReadOnly:  CLMemoryUsage read new CLMemoryUsage(true,  false);
    public static property WriteOnly: CLMemoryUsage read new CLMemoryUsage(false, true);
    public static property ReadWrite: CLMemoryUsage read new CLMemoryUsage(true,  true);
    
    public property CanRead: boolean read data and can_read_bit <> 0;
    public property CanWrite: boolean read data and can_write_bit <> 0;
    
    private static function MakeCLFlags(kernel_use, map_use: CLMemoryUsage): MemFlags;
    begin
      
      case kernel_use.data of
        none_bits:
          raise new ArgumentException($'%Err:CLMemoryUsage:NoCLKernelAccess%');
        can_read_bit:
          Result := MemFlags.MEM_READ_ONLY;
        can_write_bit:
          Result := MemFlags.MEM_WRITE_ONLY;
        read_write_bits:
          Result := MemFlags.MEM_READ_WRITE;
        else
          raise new ArgumentException($'%Err:CLMemoryUsage:Invalid%');
      end;
      
      case map_use.data of
        none_bits:
          Result += MemFlags.MEM_HOST_NO_ACCESS;
        can_read_bit:
          Result += MemFlags.MEM_HOST_READ_ONLY;
        can_write_bit:
          Result += MemFlags.MEM_HOST_WRITE_ONLY;
        read_write_bits:
          ;
        else
          raise new ArgumentException($'%Err:CLMemoryUsage:Invalid%');
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var res := new StringBuilder;
      res += typeof(CLMemoryUsage).Name;
      res += '[';
      if CanRead  then res += 'Read';
      if CanWrite then res += 'Write';
      res += ']';
      Result := res.ToString;
    end;
    
  end;
  
  {$endregion CLMemoryUsage}
  
  {$region CLMemory}
  
  CLMemory = partial class(IDisposable)
    private ntv: cl_mem;
    
    {$region constructor's}
    
    public constructor(size: UIntPtr; c: CLContext; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, CLMemoryUsage.MakeCLFlags(kernel_use,map_use), size, nil, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    public constructor(size: integer; c: CLContext; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(new UIntPtr(size), c, kernel_use, map_use);
    public constructor(size: int64;   c: CLContext; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(new UIntPtr(size), c, kernel_use, map_use);
    
    public constructor(size: UIntPtr; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(size, CLContext.Default, kernel_use, map_use);
    public constructor(size: integer; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(new UIntPtr(size), kernel_use, map_use);
    public constructor(size: int64;   kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(new UIntPtr(size), kernel_use, map_use);
    
    private constructor(ntv: cl_mem);
    begin
      self.ntv := ntv;
      cl.RetainMemObject(ntv);
    end;
    public static function FromNative(ntv: cl_mem): CLMemory;
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static function GetSize(ntv: cl_mem): UIntPtr;
    begin
      OpenCLABCInternalException.RaiseIfError(
        cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(UIntPtr.Size), Result, IntPtr.Zero)
      );
    end;
    public property Size: UIntPtr read GetSize(ntv);
    public property Size32: UInt32 read Size.ToUInt32;
    public property Size64: UInt64 read Size.ToUInt64;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var prev_ntv := new cl_mem( Interlocked.Exchange(self.ntv.val, IntPtr.Zero) );
      if prev_ntv=cl_mem.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseMemObject(prev_ntv) );
      GC.SuppressFinalize(self);
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    {%ContainerMethods\CLMemory\Implicit.Interface!ContainerOtherMethods.pas%}
    
    {%ContainerMethods\CLMemory.Get\Implicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  {$endregion CLMemory}
  
  {$region CLMemorySubSegment}
  
  CLMemorySubSegment = partial class(CLMemory)
    private _parent: cl_mem;
    
    {$region constructor's}
    
    private static function MakeSubNtv(parent: cl_mem; reg: cl_buffer_region; flags: MemFlags): cl_mem;
    begin
      var ec: ErrorCode;
      Result := cl.CreateSubBuffer(parent, flags, BufferCreateType.BUFFER_CREATE_TYPE_REGION, reg, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
    end;
    
    public constructor(parent: CLMemory; origin, size: UIntPtr; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      inherited Create( MakeSubNtv(parent.ntv, new cl_buffer_region(origin, size), CLMemoryUsage.MakeCLFlags(kernel_use, map_use)) );
      self._parent := parent.ntv;
    end;
    public constructor(parent: CLMemory; origin, size: UInt32; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(parent, new UIntPtr(origin), new UIntPtr(size), kernel_use, map_use);
    public constructor(parent: CLMemory; origin, size: UInt64; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(parent, new UIntPtr(origin), new UIntPtr(size), kernel_use, map_use);
    
    // For the CLMemory.FromNative
    private constructor(parent, ntv: cl_mem);
    begin
      inherited Create(ntv);
      self._parent := parent;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    public property Parent: CLMemory read CLMemory.FromNative(_parent);
    
    {$endregion property's}
    
  end;
  
  {$endregion CLMemorySubSegment}
  
  {$region CLValue}
  
  CLValue<T> = partial class(IDisposable)
  where T: record;
    private ntv: cl_mem;
    
    {$region constructor's}
    
    public constructor(c: CLContext; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, CLMemoryUsage.MakeCLFlags(kernel_use,map_use), new UIntPtr(ValueSize), nil, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    public constructor(c: CLContext; val: T; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, CLMemoryUsage.MakeCLFlags(kernel_use,map_use) + MemFlags.MEM_COPY_HOST_PTR, new UIntPtr(ValueSize), val, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    
    public constructor(kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(CLContext.Default, kernel_use, map_use);
    public constructor(val: T; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(CLContext.Default, val, kernel_use, map_use);
    
    public constructor(ntv: cl_mem);
    begin
      self.ntv := ntv;
      OpenCLABCInternalException.RaiseIfError( cl.RetainMemObject(ntv) );
    end;
    
    public static function operator implicit(mem: CLValue<T>): CLMemory := new CLMemory(mem.ntv);
    public constructor(mem: CLMemory) := Create(mem.ntv);
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static value_size := Marshal.SizeOf(default(T));
    public static property ValueSize: integer read value_size;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseMemObject(new cl_mem(prev)) );
      GC.SuppressFinalize(self);
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    {%ContainerMethods\CLValue\Implicit.Interface!ContainerOtherMethods.pas%}
    
    {%ContainerMethods\CLValue.Get\Implicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  {$endregion CLValue}
  
  {$region CLArray}
  
  CLArray<T> = partial class(IDisposable)
  where T: record;
    private ntv: cl_mem;
    
    {$region constructor's}
    
    private procedure InitByLen(c: CLContext; kernel_use, map_use: CLMemoryUsage);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, CLMemoryUsage.MakeCLFlags(kernel_use,map_use), new UIntPtr(ByteSize), nil, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    private procedure InitByVal(c: CLContext; var els: T; kernel_use, map_use: CLMemoryUsage);
    begin
      
      var ec: ErrorCode;
      self.ntv := cl.CreateBuffer(c.ntv, CLMemoryUsage.MakeCLFlags(kernel_use,map_use) + MemFlags.MEM_COPY_HOST_PTR, new UIntPtr(ByteSize), els, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      
    end;
    
    public constructor(c: CLContext; len: integer; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      self.len := len;
      InitByLen(c, kernel_use, map_use);
    end;
    public constructor(len: integer; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(CLContext.Default, len, kernel_use, map_use);
    
    public constructor(c: CLContext; els: array of T; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      self.len := els.Length;
      InitByVal(c, els[0], kernel_use, map_use);
    end;
    public constructor(els: array of T; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(CLContext.Default, els, kernel_use, map_use);
    
    public constructor(c: CLContext; els_from, len: integer; els: array of T; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits);
    begin
      self.len := len;
      InitByVal(c, els[els_from], kernel_use, map_use);
    end;
    public constructor(els_from, len: integer; els: array of T; kernel_use: CLMemoryUsage := CLMemoryUsage.read_write_bits; map_use: CLMemoryUsage := CLMemoryUsage.read_write_bits) :=
    Create(CLContext.Default, els_from, len, els, kernel_use, map_use);
    
    public constructor(ntv: cl_mem);
    begin
      
      var byte_size: UIntPtr;
      OpenCLABCInternalException.RaiseIfError(
        cl.GetMemObjectInfo(ntv, MemInfo.MEM_SIZE, new UIntPtr(UIntPtr.Size), byte_size, IntPtr.Zero)
      );
      
      self.len := byte_size.ToUInt64 div item_size;
      self.ntv := ntv;
      
      OpenCLABCInternalException.RaiseIfError( cl.RetainMemObject(ntv) );
    end;
    
    public static function operator implicit(mem: CLArray<T>): CLMemory := new CLMemory(mem.ntv);
    public constructor(mem: CLMemory) := Create(mem.ntv);
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$endregion constructor's}
    
    {$region property's}
    
    private static item_size := Marshal.SizeOf(default(T));
    public static property ItemSize: integer read item_size;
    
    private len: integer;
    public property Length: integer read len;
    public property ByteSize: int64 read int64(len) * item_size;
    
    private function GetItemProp(ind: integer): T;
    private procedure SetItemProp(ind: integer; value: T);
    public property Item[ind: integer]: T read GetItemProp write SetItemProp; default;
    
    private function GetSliceProp(range: IntRange): array of T;
    private procedure SetSliceProp(range: IntRange; value: array of T);
    public property Slice[range: IntRange]: array of T read GetSliceProp write SetSliceProp;
    
    {$endregion property's}
    
    {$region IDisposable}
    
    public procedure Dispose;
    begin
      var prev := Interlocked.Exchange(self.ntv.val, IntPtr.Zero);
      if prev=IntPtr.Zero then exit;
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseMemObject(new cl_mem(prev)) );
      GC.SuppressFinalize(self);
    end;
    protected procedure Finalize; override := Dispose;
    
    {$endregion IDisposable}
    
    {%ContainerMethods\CLArray\Implicit.Interface!ContainerOtherMethods.pas%}
    
    {%ContainerMethods\CLArray.Get\Implicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  {$endregion CLArray}
  
  {$endregion CLMemory}
  
  {$region Common}
  
  {%Wrappers\Common!Wrappers.pas%}
  
  {$endregion Common}
  
  {$region Misc}
  
  CLDevice = partial class
    
    private supported_split_modes: array of DevicePartitionProperty := nil;
    private function GetSSM: array of DevicePartitionProperty;
    begin
      if supported_split_modes=nil then supported_split_modes := {%>Properties.PartitionProperties!!} nil {%};
      Result := supported_split_modes;
    end;
    
    private function Split(params props: array of DevicePartitionProperty): array of CLSubDevice;
    begin
      if not GetSSM.Contains(props[0]) then
        raise new NotSupportedException($'%Err:CLDevice:SplitNotSupported%');
      
      var c: UInt32;
      OpenCLABCInternalException.RaiseIfError( cl.CreateSubDevices(self.ntv, props, 0, IntPtr.Zero, c) );
      
      var res := new cl_device_id[int64(c)];
      OpenCLABCInternalException.RaiseIfError( cl.CreateSubDevices(self.ntv, props, c, res[0], IntPtr.Zero) );
      
      Result := res.ConvertAll(sdvc->new CLSubDevice(self.ntv, sdvc));
    end;
    
    public property CanSplitEqually: boolean read DevicePartitionProperty.DEVICE_PARTITION_EQUALLY in GetSSM;
    public function SplitEqually(CUCount: integer): array of CLSubDevice;
    begin
      if CUCount <= 0 then raise new ArgumentException($'%Err:CLDevice:SplitCUCount%');
      Result := Split(
        DevicePartitionProperty.DEVICE_PARTITION_EQUALLY,
        DevicePartitionProperty.Create(CUCount),
        DevicePartitionProperty.Create(0)
      );
    end;
    
    public property CanSplitByCounts: boolean read DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS in GetSSM;
    public function SplitByCounts(params CUCounts: array of integer): array of CLSubDevice;
    begin
      foreach var CUCount in CUCounts do
        if CUCount <= 0 then raise new ArgumentException($'%Err:CLDevice:SplitCUCount%');
      
      var props := new DevicePartitionProperty[CUCounts.Length+2];
      props[0] := DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS;
      for var i := 0 to CUCounts.Length-1 do
        props[i+1] := new DevicePartitionProperty(CUCounts[i]);
      props[props.Length-1] := DevicePartitionProperty.DEVICE_PARTITION_BY_COUNTS_LIST_END;
      
      Result := Split(props);
    end;
    
    public property CanSplitByAffinityDomain: boolean read DevicePartitionProperty.DEVICE_PARTITION_BY_AFFINITY_DOMAIN in GetSSM;
    public function SplitByAffinityDomain(affinity_domain: CLDeviceAffinityDomain) :=
    Split(
      DevicePartitionProperty.DEVICE_PARTITION_BY_AFFINITY_DOMAIN,
      DevicePartitionProperty.Create(new IntPtr(affinity_domain.val)),
      DevicePartitionProperty.Create(0)
    );
    
  end;
  
  {$endregion Misc}
  
  {$endregion Wrappers}
  
  {$region CommandQueue}
  
  {$region ToString}
  
  CommandQueueBase = abstract partial class
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private static function GetValueRuntimeType<T>(val: T) :=
    if typeof(T).IsValueType then
      typeof(T) else
    if val = default(T) then
      nil else val.GetType;
    private static procedure ToStringRuntimeValue<T>(sb: StringBuilder; val: T);
    begin
      var rt := GetValueRuntimeType(val);
      if typeof(T) <> rt then
      begin
        if rt<>nil then sb.Append(TypeToTypeName(rt));
        sb += '{ ';
      end;
      sb += _ObjectToString(val);
      if typeof(T) <> rt then
        sb += ' }';
    end;
    
    private function ToStringHeader(sb: StringBuilder; index: Dictionary<object,integer>): boolean;
    begin
      sb += TypeName(self);
      
      var ind: integer;
      Result := not index.TryGetValue(self, ind);
      
      if Result then
      begin
        ind := index.Count;
        index[self] := ind;
      end;
      
      sb += '#';
      sb.Append(ind);
      
    end;
    private static procedure ToStringWriteDelegate(sb: StringBuilder; d: System.Delegate);
    const lambda='lambda';
    const sugar_begin='<>';
    const par_separator='; ';
    begin
      if d.Target<>nil then
      begin
        sb += _ObjectToString(d.Target);
        sb += ' => ';
      end;
      var mi := d.Method;
      var rt := mi.ReturnType;
      if rt=typeof(Void) then rt := nil;
      
      sb += if rt=nil then 'procedure' else 'function';
      sb += ' ';
      begin
        var name := mi.Name;
        if name.StartsWith(sugar_begin) then
          name := if lambda in name then
            lambda else name.Substring(sugar_begin.Length);
        sb += name;
      end;
      
      var pars := mi.GetParameters;
      if pars.Length<>0 then
      begin
        sb += '(';
        foreach var par in pars do
        begin
          var name := par.Name;
          if name.StartsWith(sugar_begin) then
            name := name.Substring(sugar_begin.Length);
          sb += name;
          sb += ': ';
          sb += TypeToTypeName(par.ParameterType);
          sb += par_separator;
        end;
        sb.Length -= par_separator.Length;
        sb += ')';
      end;
      
      if rt<>nil then
      begin
        sb += ': ';
        sb += TypeToTypeName(rt);
      end;
      
    end;
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
    begin
      delayed.Remove(self);
      
      if write_tabs then sb.Append(#9, tabs);
      ToStringHeader(sb, index);
      ToStringImpl(sb, tabs+1, index, delayed);
      
      if tabs=0 then foreach var q in delayed do
      begin
        sb += #10;
        q.ToString(sb, 0, index, new HashSet<CommandQueueBase>);
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      ToString(sb, 0, new Dictionary<object, integer>, new HashSet<CommandQueueBase>);
      Result := sb.ToString;
    end;
    
    public function Print: CommandQueueBase;
    begin
      Write(self.ToString);
      Result := self;
    end;
    public function Println: CommandQueueBase;
    begin
      Writeln(self.ToString);
      Result := self;
    end;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public function Print: CommandQueueNil;
    begin
      inherited Print;
      Result := self;
    end;
    public function Println: CommandQueueNil;
    begin
      inherited Println;
      Result := self;
    end;
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public function Print: CommandQueue<T>;
    begin
      inherited Print;
      Result := self;
    end;
    public function Println: CommandQueue<T>;
    begin
      inherited Println;
      Result := self;
    end;
    
  end;
  
  {$endregion ToString}
  
  {$region Use/Convert Typed}
  
  ITypedCQUser = interface
    
    procedure UseNil(cq: CommandQueueNil);
    procedure Use<T>(cq: CommandQueue<T>);
    
  end;
  ITypedCQConverter<TRes> = interface
    
    function ConvertNil(cq: CommandQueueNil): TRes;
    function Convert<T>(cq: CommandQueue<T>): TRes;
    
  end;
  
  CommandQueueBase = abstract partial class
    
    public procedure UseTyped(user: ITypedCQUser); abstract;
    public function ConvertTyped<TRes>(converter: ITypedCQConverter<TRes>): TRes; abstract;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public procedure UseTyped(user: ITypedCQUser); override := user.UseNil(self);
    public function ConvertTyped<TRes>(converter: ITypedCQConverter<TRes>): TRes; override := converter.ConvertNil(self);
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public procedure UseTyped(user: ITypedCQUser); override := user.Use(self);
    public function ConvertTyped<TRes>(converter: ITypedCQConverter<TRes>): TRes; override := converter.Convert(self);
    
  end;
  
  {$endregion Use/Convert Typed}
  
  {$region Const}
  
  ConstQueueNil = sealed partial class(CommandQueueNil)
    
    private constructor := raise new OpenCLABCInternalException;
    private constructor(b: byte) := exit;
    
    private static _instance := new ConstQueueNil(0);
    public static property Instance: ConstQueueNil read _instance;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := sb += #10;
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    private expected_const_res: T;
    private const_res_dep: array of CommandQueueBase := nil;
    
    private static function empty_dep := System.Array.Empty&<CommandQueueBase>;
    private function IsConstResDepEmpty: boolean;
    begin
      Result := self.const_res_dep = empty_dep;
      {$ifdef DEBUG}
      var robust_res := (const_res_dep<>nil) and (const_res_dep.Length=0);
      if Result <> robust_res then
        raise new OpenCLABCInternalException($'');
      {$endif DEBUG}
    end;
    
    // Empty ctor also allowed
    protected constructor(res: T; dep: array of CommandQueueBase);
    begin
      self.expected_const_res := res;
      self.const_res_dep := dep;
    end;
    
  end;
  ConstQueue<T> = sealed partial class(CommandQueue<T>)
    
    public constructor(o: T) := inherited Create(o, empty_dep);
    private constructor := raise new OpenCLABCInternalException;
    
    public property Value: T read self.expected_const_res;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.expected_const_res);
      sb += #10;
    end;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase) end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public static function operator implicit(o: T): CommandQueue<T> :=
    new ConstQueue<T>(o);
    
  end;
  
  {$endregion Const}
  
  {$region Parameter}
  
  ParameterQueueSetter = sealed partial class
    private val: object;
    
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  ParameterQueue<T> = sealed partial class(CommandQueue<T>)
    private _name: string;
    
    public constructor(name: string);
    begin
      self._name := name;
    end;
    public constructor(name: string; def: T);
    begin
      inherited Create(def, new CommandQueueBase[](self));
      self.name := name;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public property Name: string read _name write _name;
    public property DefaultDefined: boolean read const_res_dep<>nil;
    
    private function GetDefault: T;
    begin
      if not DefaultDefined then
        raise new InvalidOperationException($'%Err:Parameter:UnSet%');
      Result := self.expected_const_res;
    end;
    public property &Default: T read GetDefault;
    
    public function NewSetter(val: T): ParameterQueueSetter;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += '["';
      sb += Name;
      sb += '"]';
      if DefaultDefined then
      begin
        sb += ': Default=';
        ToStringRuntimeValue(sb, self.Default);
      end;
      sb += #10;
    end;
    
  end;
  
  {$endregion Parameter}
  
  {$region Cast}
  
  CommandQueueBase = abstract partial class
    
    public function Cast<T>: CommandQueue<T>;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public function Cast<T>: CommandQueue<T>; where T: class;
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase) end;
  
  {$endregion Cast}
  
  {$region DiscardResult}
  
  CommandQueueBase = abstract partial class
    
    private function DiscardResultBase: CommandQueueNil; abstract;
    public function DiscardResult := DiscardResultBase;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    private function DiscardResultBase: CommandQueueNil; override := DiscardResult;
    public function DiscardResult := self;
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function DiscardResultBase: CommandQueueNil; override := DiscardResult;
    public function DiscardResult: CommandQueueNil;
    
  end;
  
  {$endregion DiscardResult}
  
  {$region Then[Convert,Use]}
  
  CommandQueueBase = abstract partial class end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase) end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    {$region Convert}
    
    public function ThenConvert<TOtp>(f: T->TOtp             ; need_own_thread: boolean := true; can_pre_calc: boolean := false): CommandQueue<TOtp>;
    public function ThenConvert<TOtp>(f: (T, CLContext)->TOtp; need_own_thread: boolean := true; can_pre_calc: boolean := false): CommandQueue<TOtp>;
    
    {$endregion Convert}
    
    {$region Use}
    
    public function ThenUse(p: T->()             ; need_own_thread: boolean := true; can_pre_calc: boolean := false): CommandQueue<T>;
    public function ThenUse(p: (T, CLContext)->(); need_own_thread: boolean := true; can_pre_calc: boolean := false): CommandQueue<T>;
    
    {$endregion Use}
    
  end;
  
  {$endregion Then[Convert,Use]}
  
  {$region Multiusable}
  
  CommandQueueBase = abstract partial class
    
    private function MultiusableBase: CommandQueueBase; abstract;
    public function Multiusable := MultiusableBase;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    private function MultiusableBase: CommandQueueBase; override := Multiusable;
    public function Multiusable: CommandQueueNil;
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    private function MultiusableBase: CommandQueueBase; override := Multiusable;
    public function Multiusable: CommandQueue<T>;
    
  end;
  
  {$endregion Multiusable}
  
  {$region Finally+Handle}
  
  CommandQueueBase = abstract partial class
    
    private function ConvertErrHandler<TException>(handler: TException->boolean): Exception->boolean; where TException: Exception;
    begin Result := e->(e is TException) and handler(TException(e)) end;
    
    public function HandleWithoutRes<TException>(handler: TException->boolean): CommandQueueNil; where TException: Exception;
    begin Result := HandleWithoutRes(ConvertErrHandler(handler)) end;
    public function HandleWithoutRes(handler: Exception->boolean): CommandQueueNil;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public function HandleDefaultRes<TException>(handler: TException->boolean; def: T): CommandQueue<T>; where TException: Exception;
    begin Result := HandleDefaultRes(ConvertErrHandler(handler), def) end;
    public function HandleDefaultRes(handler: Exception->boolean; def: T): CommandQueue<T>;
    
    public function HandleReplaceRes(handler: List<Exception> -> T): CommandQueue<T>;
    
  end;
  
  {$endregion Finally+Handle}
  
  {$region Wait}
  
  WaitMarker = abstract partial class
    
    public static function Create: WaitMarker;
    
    public procedure SendSignal; abstract;
    
    public static function operator and(m1, m2: WaitMarker): WaitMarker;
    public static function operator or(m1, m2: WaitMarker): WaitMarker;
    
    private function ConvertToQBase: CommandQueueBase; abstract;
    public static function operator implicit(m: WaitMarker): CommandQueueBase := m.ConvertToQBase;
    
    {$region ToString}
    
    private function ToStringHeader(sb: StringBuilder; index: Dictionary<object,integer>): boolean;
    begin
      sb += TypeName(self);
      
      var ind: integer;
      Result := not index.TryGetValue(self, ind);
      
      if Result then
      begin
        ind := index.Count;
        index[self] := ind;
      end;
      
      sb += '#';
      sb.Append(ind);
      
    end;
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
    begin
      if write_tabs then sb.Append(#9, tabs);
      ToStringHeader(sb, index);
      ToStringImpl(sb, tabs+1, index, delayed);
      
      if tabs=0 then foreach var q in delayed do
      begin
        sb += #10;
        q.ToString(sb, 0, index, new HashSet<CommandQueueBase>);
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      ToString(sb, 0, new Dictionary<object, integer>, new HashSet<CommandQueueBase>);
      Result := sb.ToString;
    end;
    
    public function Print: WaitMarker;
    begin
      Write(self.ToString);
      Result := self;
    end;
    public function Println: WaitMarker;
    begin
      Writeln(self.ToString);
      Result := self;
    end;
    
    {$endregion ToString}
    
  end;
  
  CommandQueueMarkedCapNil = sealed partial class
    
    private function get_signal_in_finally: boolean;
    public property SignalInFinally: boolean read get_signal_in_finally;
    
    public constructor(q: CommandQueueNil; signal_in_finally: boolean);
    private constructor := raise new OpenCLABCInternalException;
    
    public static function operator implicit(dms: CommandQueueMarkedCapNil): WaitMarker;
    
    public procedure SendSignal := WaitMarker(self).SendSignal;
    public static function operator and(m1, m2: CommandQueueMarkedCapNil) := WaitMarker(m1) and WaitMarker(m2);
    public static function operator or(m1, m2: CommandQueueMarkedCapNil) := WaitMarker(m1) or WaitMarker(m2);
    
  end;
  CommandQueueMarkedCap<T> = sealed partial class
    
    private function get_signal_in_finally: boolean;
    public property SignalInFinally: boolean read get_signal_in_finally;
    
    public constructor(q: CommandQueue<T>; signal_in_finally: boolean);
    private constructor := raise new OpenCLABCInternalException;
    
    public static function operator implicit(dms: CommandQueueMarkedCap<T>): WaitMarker;
    
    public procedure SendSignal := WaitMarker(self).SendSignal;
    public static function operator and(m1, m2: CommandQueueMarkedCap<T>) := WaitMarker(m1) and WaitMarker(m2);
    public static function operator or(m1, m2: CommandQueueMarkedCap<T>) := WaitMarker(m1) or WaitMarker(m2);
    
  end;
  
  CommandQueueBase = abstract partial class end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
    public function ThenMarkerSignal := new CommandQueueMarkedCapNil(self, false);
    public function ThenFinallyMarkerSignal := new CommandQueueMarkedCapNil(self, true);
    
  end;
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    public function ThenMarkerSignal := new CommandQueueMarkedCap<T>(self, false);
    public function ThenFinallyMarkerSignal := new CommandQueueMarkedCap<T>(self, true);
    
    public function ThenWaitFor(marker: WaitMarker): CommandQueue<T>;
    public function ThenFinallyWaitFor(marker: WaitMarker): CommandQueue<T>;
    
  end;
  
  {$endregion Wait}
  
  {$endregion CommandQueue}
  
  {$region CLTask}
  
  CLTaskBase = abstract partial class
    private org_c: CLContext;
    private wh := new ManualResetEventSlim(false);
    private err_lst: List<Exception>;
    
    private function OrgQueueBase: CommandQueueBase; abstract;
    public property OrgQueue: CommandQueueBase read OrgQueueBase;
    
    public property OrgCLContext: CLContext read org_c;
    
    public procedure Wait;
    begin
      wh.Wait;
      if err_lst.Count=0 then exit;
      raise new AggregateException($'%Err:CLTask:%', err_lst.ToArray);
    end;
    
  end;
  
  CLTaskNil = sealed partial class(CLTaskBase)
    private q: CommandQueueNil;
    
    private constructor := raise new OpenCLABCInternalException;
    
    public property OrgQueue: CommandQueueNil read q; reintroduce;
    private function OrgQueueBase: CommandQueueBase; override := self.OrgQueue;
    
  end;
  
  CLTask<T> = sealed partial class(CLTaskBase)
    private q: CommandQueue<T>;
    
    private constructor := raise new OpenCLABCInternalException;
    
    public property OrgQueue: CommandQueue<T> read q; reintroduce;
    private function OrgQueueBase: CommandQueueBase; override := self.OrgQueue;
    
    public function WaitRes: T;
    
  end;
  
  CLContext = partial class
    
    public function BeginInvoke(q: CommandQueueBase; params parameters: array of ParameterQueueSetter): CLTaskBase;
    public function BeginInvoke(q: CommandQueueNil; params parameters: array of ParameterQueueSetter): CLTaskNil;
    public function BeginInvoke<T>(q: CommandQueue<T>; params parameters: array of ParameterQueueSetter): CLTask<T>;
    
    public procedure SyncInvoke(q: CommandQueueBase; params parameters: array of ParameterQueueSetter) := BeginInvoke(q, parameters).Wait;
    public procedure SyncInvoke(q: CommandQueueNil; params parameters: array of ParameterQueueSetter) := BeginInvoke(q, parameters).Wait;
    public function SyncInvoke<T>(q: CommandQueue<T>; params parameters: array of ParameterQueueSetter) := BeginInvoke(q, parameters).WaitRes;
    
  end;
  
  {$endregion CLTask}
  
  {$region CCQ's}
  
  {$region CLKernelCCQ}
  
  CLKernelCCQ = sealed partial class
    
    {%ContainerCommon\CLKernel\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLKernel.Exec\Explicit.Interface!ContainerExecMethods.pas%}
    
  end;
  
  CLKernel = partial class
    public function MakeCCQ := new CLKernelCCQ({%>self%});
  end;
  
  {$endregion CLKernelCCQ}
  
  {$region CLMemorySegmentCCQ}
  
  CLMemoryCCQ = sealed partial class
    
    {%ContainerCommon\CLMemory\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLMemory\Explicit.Interface!ContainerOtherMethods.pas%}
    
    {%ContainerMethods\CLMemory.Get\Explicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  CLMemory = partial class
    public function MakeCCQ := new CLMemoryCCQ({%>self%});
  end;
  
  {$endregion CLMemorySegmentCCQ}
  
  {$region CLValueCCQ}
  
  CLValueCCQ<T> = sealed partial class
  where T: record;
    
    {%ContainerCommon\CLValue\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLValue\Explicit.Interface!ContainerOtherMethods.pas%}
    
    {%ContainerMethods\CLValue.Get\Explicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  CLValue<T> = partial class
    public function MakeCCQ := new CLValueCCQ<T>({%>self%});
  end;
  
  {$endregion CLValueCCQ}
  
  {$region CLArrayCCQ}
  
  CLArrayCCQ<T> = sealed partial class
  where T: record;
    
    {%ContainerCommon\CLArray\Interface!ContainerCommon.pas%}
    
    {%ContainerMethods\CLArray\Explicit.Interface!ContainerOtherMethods.pas%}
    
    {%ContainerMethods\CLArray.Get\Explicit.Interface!ContainerGetMethods.pas%}
    
  end;
  
  CLArray<T> = partial class
    public function MakeCCQ := new CLArrayCCQ<T>({%>self%});
  end;
  
  {$endregion CLArrayCCQ}
  
  {$endregion CCQ's}
  
  {$region CLKernelArg}
  
  {%CLKernelArg\interface!CLKernelArg.pas%}
  
  {$region ToString}
  
  CLKernelArg = abstract partial class
    
    {$region ToString}
    
    private static procedure ToStringRuntimeValue<T>(sb: StringBuilder; val: T) := CommandQueueBase.ToStringRuntimeValue(sb, val);
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>; write_tabs: boolean := true);
    begin
      if write_tabs then sb.Append(#9, tabs);
      sb += TypeName(self);
      
      ToStringImpl(sb, tabs+1, index, delayed);
      
      if tabs=0 then foreach var q in delayed do
      begin
        sb += #10;
        q.ToString(sb, 0, index, new HashSet<CommandQueueBase>);
      end;
      
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      ToString(sb, 0, new Dictionary<object, integer>, new HashSet<CommandQueueBase>);
      Result := sb.ToString;
    end;
    
    public function Print: CLKernelArg;
    begin
      Write(self.ToString);
      Result := self;
    end;
    public function Println: CLKernelArg;
    begin
      Writeln(self.ToString);
      Result := self;
    end;
    
    {$endregion ToString}
    
  end;
  
  {$endregion ToString}
  
  {$endregion CLKernelArg}
  
{$region Global subprograms}

{$region ConstQueue}

function CQNil: CommandQueueNil;
function CQ<T>(o: T): CommandQueue<T>;

{$endregion ConstQueue}

{$region HFQ/HPQ}

function HFQ<T>(f: ()->T; need_own_thread: boolean := true): CommandQueue<T>;
function HFQ<T>(f: CLContext->T; need_own_thread: boolean := true): CommandQueue<T>;

function HPQ(p: ()->(); need_own_thread: boolean := true): CommandQueueNil;
function HPQ(p: CLContext->(); need_own_thread: boolean := true): CommandQueueNil;

{$endregion HFQ/HPQ}

{$region Wait}

function CombineWaitAll(params sub_markers: array of WaitMarker): WaitMarker;
function CombineWaitAll(sub_markers: sequence of WaitMarker): WaitMarker;

function CombineWaitAny(params sub_markers: array of WaitMarker): WaitMarker;
function CombineWaitAny(sub_markers: sequence of WaitMarker): WaitMarker;

function WaitFor(marker: WaitMarker): CommandQueueNil;

{$endregion Wait}

{$region CombineQueue's}

{%CombineQueues\Interface!CombineQueues.pas%}

{$endregion CombineQueue's}

{$endregion Global subprograms}

implementation

{$region Util type's}
// To reorder first change OpenCLABC.Utils.drawio
// Created using https://www.diagrams.net/

{$region Basic}

{$region InterlockedBoolean}

type
  InterlockedBoolean = record
    // Less then 32-bit is not hardware supported
    private val := 0;
    
    public constructor(b: boolean) :=
    self.val := integer(b);
    
    public function TrySet(b: boolean): boolean;
    begin
      var prev := integer(not b);
      var curr := integer(b);
      Result := Interlocked.CompareExchange(val, curr, prev)=prev;
    end;
    
    public static function operator implicit(b: boolean): InterlockedBoolean := new InterlockedBoolean(b);
    public static function operator implicit(b: InterlockedBoolean): boolean := Volatile.Read(b.val)<>0;
    
  end;
  
{$endregion InterlockedBoolean}

{$region Blittable}

type
  BlittableException = sealed class(Exception)
    public constructor(t, blame: System.Type; source_name: string) :=
    inherited Create(t=blame ? $'%Err:Blittable:Main%' : $'%Err:Blittable:Blame%' );
  end;
  BlittableHelper = static class
    
    private static blittable_cache := new Dictionary<System.Type, System.Type>;
    public static function Blame(t: System.Type): System.Type;
    begin
      Result := nil;
      if t.IsPointer then exit;
      if t.IsClass then
      begin
        Result := t;
        exit;
      end;
      if blittable_cache.TryGetValue(t, Result) then exit;
      
      var o := System.Activator.CreateInstance(t);
      try
        GCHandle.Alloc(o, GCHandleType.Pinned).Free;
      except
        on System.ArgumentException do
        begin
          foreach var fld in t.GetFields(System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.Public or System.Reflection.BindingFlags.NonPublic) do
            if fld.FieldType<>t then
            begin
              Result := Blame(fld.FieldType);
              if Result<>nil then break;
            end;
          if Result=nil then Result := t;
        end;
      end;
      
      blittable_cache[t] := Result;
    end;
    
    public static procedure RaiseIfBad(t: System.Type; source_name: string);
    begin
      var blame := BlittableHelper.Blame(t);
      if blame=nil then exit;
      raise new BlittableException(t, blame, source_name);
    end;
    
  end;
  
  CLValue<T> = partial class
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(T), $'%Err:Blittable:Source:CLValue%');
  end;
  CLArray<T> = partial class
    static constructor :=
    BlittableHelper.RaiseIfBad(typeof(T), $'%Err:Blittable:Source:CLArray%');
  end;
  
static constructor NativeValueArea<T>.Create :=
BlittableHelper.RaiseIfBad(typeof(T), $'%Err:Blittable:Source:NativeValue[Area]%');

static constructor NativeArrayArea<T>.Create :=
BlittableHelper.RaiseIfBad(typeof(T), $'%Err:Blittable:Source:NativeArray[Area]%');

{$endregion Blittable}

{$region CLTaskParameterData}

type
  IParameterQueue = interface
    
    property Name: string read;
    
  end;
  ParameterQueueSetter = sealed partial class
    par_q: IParameterQueue;
    
    public constructor(par_q: IParameterQueue; val: object);
    begin
      self.par_q := par_q;
      self.val := val;
    end;
    
    public property Name: string read par_q.Name;
    
  end;
  ParameterQueue<T> = sealed partial class(CommandQueue<T>, IParameterQueue)
    
  end;
  
//TODO #????
function ParameterQueue<T>.NewSetter(val: T) := new ParameterQueueSetter(self as object as IParameterQueue, val);

type
  CLTaskParameterData = record
    val: object;
    state: (TPS_Default, TPS_Empty, TPS_Set);
    
    public constructor :=
    self.state := TPS_Empty;
    public constructor(def: object);
    begin
      self.val := def;
      self.state := TPS_Default;
    end;
    
    public function &Set(name: string; val: object): CLTaskParameterData;
    begin
      if self.state=TPS_Set then
        raise new ArgumentException($'%Err:Parameter:SetAgain%');
      Result.val := val;
      Result.state := TPS_Set;
    end;
    
    public procedure TestSet(name: string) :=
    if self.state=TPS_Empty then
      raise new ArgumentException($'%Err:Parameter:UnSet%');
    
  end;
  
{$endregion CLTaskParameterData}

{$region CLTaskGlobalData[CORE]}

type
  CLTaskGlobalData = sealed partial class
    public c: CLContext;
    public cl_c: cl_context;
    public cl_dvc: cl_device_id;
    
    private constructor := raise new OpenCLABCInternalException;
    
    {$region par}
    
    public parameters := new Dictionary<IParameterQueue, CLTaskParameterData>;
    public procedure ApplyParameters(pars: array of ParameterQueueSetter);
    begin
      foreach var par in pars do
      begin
        if not parameters.ContainsKey(par.par_q) then
          raise new ArgumentException($'%Err:Parameter:NotFound%');
        parameters[par.par_q] := parameters[par.par_q].Set(par.Name, par.val);
      end;
      foreach var kvp in self.parameters do
        kvp.Value.TestSet(kvp.Key.Name);
    end;
    
    public function CheckDeps(deps: array of CommandQueueBase): boolean;
    begin
      Result := false;
      if deps=nil then exit;
      foreach var dep in deps do
        if parameters[IParameterQueue(dep)].state<>CLTaskParameterData.TPS_Default then
          exit;
      Result := true;
    end;
    
    {$endregion par}
    
    {$region cq}
    
    private curr_inv_cq := cl_command_queue.Zero;
    private outer_cq := cl_command_queue.Zero; // In case of A + B*C, this is curr_inv_cq from A
    private free_cqs := new System.Collections.Concurrent.ConcurrentBag<cl_command_queue>;
    
    public function GetCQ(async_enqueue: boolean := false): cl_command_queue;
    begin
      Result := curr_inv_cq;
      
      if Result=cl_command_queue.Zero then
      begin
        if outer_cq<>cl_command_queue.Zero then
        begin
          Result := outer_cq;
          outer_cq := cl_command_queue.Zero;
        end else
        if free_cqs.TryTake(Result) then
          else
        begin
          var ec: ErrorCode;
          Result := cl.CreateCommandQueue(cl_c, cl_dvc, CommandQueueProperties.NONE, ec);
          OpenCLABCInternalException.RaiseIfError(ec);
        end;
      end;
      
      curr_inv_cq := if async_enqueue then cl_command_queue.Zero else Result;
    end;
    
    public procedure ReturnCQ(cq: cl_command_queue);
    begin
      free_cqs.Add(cq);
      {$ifdef QueueDebug}
      QueueDebug.Add(cq, '----- return -----');
      {$endif QueueDebug}
    end;
    
    {$endregion cq}
    
  end;
  
{$endregion CLTaskGlobalData[CORE]}

{$region SimpleDelegateContainer's} type
  
  {$region Common}
  
  ISimpleDelegateContainer = interface
    
    procedure ToStringB(sb: StringBuilder);
    
  end;
  
  {$endregion Common}
  
  {$region Proc}
  
  ISimpleProcContainer<TInp> = interface(ISimpleDelegateContainer)
    
    procedure Invoke(inp: TInp; c: CLContext);
    
  end;
  
  SimpleProcContainer<TInp> = record(ISimpleProcContainer<TInp>)
    private d: TInp->();
    
    public static function operator implicit(d: TInp->()): SimpleProcContainer<TInp>;
    begin
      Result.d := d;
    end;
    
    public procedure Invoke(inp: TInp; c: CLContext) := d(inp);
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  SimpleProcContainerC<TInp> = record(ISimpleProcContainer<TInp>)
    private d: (TInp, CLContext)->();
    
    public static function operator implicit(d: (TInp, CLContext)->()): SimpleProcContainerC<TInp>;
    begin
      Result.d := d;
    end;
    
    public procedure Invoke(inp: TInp; c: CLContext) := d(inp, c);
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  
  {$endregion Proc}
  
  {$region Func}
  
  ISimpleFuncContainer<TInp,TRes> = interface(ISimpleDelegateContainer)
    
    function Invoke(inp: TInp; c: CLContext): TRes;
    
  end;
  
  SimpleFuncContainer<TInp,TRes> = record(ISimpleFuncContainer<TInp,TRes>)
    private d: TInp->TRes;
    
    public static function operator implicit(d: TInp->TRes): SimpleFuncContainer<TInp,TRes>;
    begin
      Result.d := d;
    end;
    
    public function Invoke(inp: TInp; c: CLContext) := d(inp);
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  SimpleFuncContainerC<TInp,TRes> = record(ISimpleFuncContainer<TInp,TRes>)
    private d: (TInp, CLContext)->TRes;
    
    public static function operator implicit(d: (TInp, CLContext)->TRes): SimpleFuncContainerC<TInp,TRes>;
    begin
      Result.d := d;
    end;
    
    public function Invoke(inp: TInp; c: CLContext) := d(inp, c);
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  
  {$endregion Func}
  
function PreInvoke<TInp,TRes>(self: ISimpleDelegateContainer; inp: TInp): TRes; extensionmethod;
begin
  match self with
    ISimpleFuncContainer<TInp,TRes>(var f): Result := f.Invoke(inp, nil);
    ISimpleProcContainer<TInp>(var p):
    begin
      p.Invoke(inp, nil);
      if typeof(TInp)<>typeof(TRes) then
        raise new OpenCLABCInternalException($'Proc inp [{TypeToTypeName(typeof(TInp))}] <> res [{TypeToTypeName(typeof(TRes))}]');
      Result := TRes(object(inp)); //TODO Убрать object. Пока не заменил as на TRes(...) - работало без него
    end;
    else raise new OpenCLABCInternalException($'Wrong DC type: [{TypeName(self)}] is not [{TypeToTypeName(typeof(TInp))}]=>[{TypeToTypeName(typeof(TRes))}]');
  end;
end;

{$endregion SimpleDelegateContainer's}

{$endregion Basic}

{$region Invoke result}

{$region EventList}

type
  AttachCallbackData = class
    public work: Action;
    {$ifdef EventDebug}
    public reason: string;
    {$endif EventDebug}
    
    public constructor(work: Action{$ifdef EventDebug}; reason: string{$endif});
    begin
      self.work := work;
      {$ifdef EventDebug}
      self.reason := reason;
      {$endif EventDebug}
    end;
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  MultiAttachCallbackData = class(AttachCallbackData)
    public left_c: integer;
    {$ifdef EventDebug}
    public all_evs: sequence of cl_event;
    {$endif EventDebug}
    
    public constructor(work: Action; left_c: integer{$ifdef EventDebug}; reason: string; all_evs: sequence of cl_event{$endif});
    begin
      inherited Create(work{$ifdef EventDebug}, reason{$endif});
      self.left_c := left_c;
      {$ifdef EventDebug}
      self.all_evs := all_evs;
      {$endif EventDebug}
    end;
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  EventList = record
    public evs: array of cl_event;
    public count := 0;
    
    {$region Misc}
    
    public property Item[i: integer]: cl_event read evs[i]; default;
    
    public static function operator=(l1, l2: EventList): boolean;
    begin
      Result := false;
      if object.ReferenceEquals(l1, l2) then
      begin
        Result := true;
        exit;
      end;
      if object.ReferenceEquals(l1, nil) then exit;
      if object.ReferenceEquals(l2, nil) then exit;
      if l1.count <> l2.count then exit;
      for var i := 0 to l1.count-1 do
        if l1[i]<>l2[i] then exit;
      Result := true;
    end;
    public static function operator<>(l1, l2: EventList): boolean := not (l1=l2);
    
    {$endregion Misc}
    
    {$region constructor's}
    
    public constructor(count: integer) :=
    self.evs := new cl_event[count];
    public constructor := raise new OpenCLABCInternalException;
    public static Empty := default(EventList);
    
    public static function operator implicit(ev: cl_event): EventList;
    begin
      if ev=cl_event.Zero then
        Result := Empty else
      begin
        Result := new EventList(1);
        Result += ev;
      end;
    end;
    
    public constructor(params evs: array of cl_event);
    begin
      self.evs := evs;
      self.count := evs.Length;
    end;
    
    {$endregion constructor's}
    
    {$region operator+}
    
    public static procedure operator+=(var l: EventList; ev: cl_event);
    begin
      l.evs[l.count] := ev;
      l.count += 1;
    end;
    
    public static procedure operator+=(var l: EventList; ev: EventList);
    begin
      for var i := 0 to ev.count-1 do
        l += ev[i];
    end;
    
    public static function operator+(l1, l2: EventList): EventList;
    begin
      Result := new EventList(l1.count+l2.count);
      Result += l1;
      Result += l2;
    end;
    
    public static function operator+(l: EventList; ev: cl_event): EventList;
    begin
      Result := new EventList(l.count+1);
      Result += l;
      Result += ev;
    end;
    
    private static function Combine<TList>(evs: TList): EventList; where TList: IList<EventList>;
    begin
      Result := EventList.Empty;
      var count := 0;
      
      //TODO #2589
      for var i := 0 to (evs as IList<EventList>).Count-1 do
        count += evs.Item[i].count;
      if count=0 then exit;
      
      Result := new EventList(count);
      //TODO #2589
      for var i := 0 to (evs as IList<EventList>).Count-1 do
        Result += evs.Item[i];
      
    end;
    
    {$endregion operator+}
    
    {$region AttachCallback}
    
    private static procedure InvokeAttachedCallback(ev: cl_event; st: CommandExecutionStatus; data: IntPtr);
    begin
      var hnd := GCHandle(data);
      var cb_data := AttachCallbackData(hnd.Target);
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(ev, $'released in callback, working on {cb_data.reason}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseEvent(ev) );
      hnd.Free;
      cb_data.work();
    end;
    private static attachable_callback: EventCallback := InvokeAttachedCallback;
    
    public static procedure AttachCallback(ev: cl_event; work: Action{$ifdef EventDebug}; reason: string{$endif});
    begin
      var cb_data := new AttachCallbackData(work{$ifdef EventDebug}, reason{$endif});
      var ec := cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, attachable_callback, GCHandle.ToIntPtr(GCHandle.Alloc(cb_data)));
      OpenCLABCInternalException.RaiseIfError(ec);
    end;
    
    {$endregion AttachCallback}
    
    {$region MultiAttachCallback}
    
    private static procedure InvokeMultiAttachedCallback(ev: cl_event; st: CommandExecutionStatus; data: IntPtr);
    begin
      var hnd := GCHandle(data);
      var cb_data := MultiAttachCallbackData(hnd.Target);
      // st копирует значение переданное в cl.SetEventCallback, поэтому он не подходит
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(ev, $'released in multi-callback, working on {cb_data.reason}, together with evs: {cb_data.all_evs.JoinToString}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError(cl.ReleaseEvent(ev));
      if Interlocked.Decrement(cb_data.left_c) <> 0 then exit;
      hnd.Free;
      cb_data.work();
    end;
    private static multi_attachable_callback: EventCallback := InvokeMultiAttachedCallback;
    
    public procedure MultiAttachCallback(work: Action{$ifdef EventDebug}; reason: string{$endif}) :=
    case self.count of
      0: work;
      1: AttachCallback(self.evs[0], work{$ifdef EventDebug}, reason{$endif});
      else
      begin
        var cb_data := new MultiAttachCallbackData(work, self.count{$ifdef EventDebug}, reason, evs.Take(count){$endif});
        var hnd_ptr := GCHandle.ToIntPtr(GCHandle.Alloc(cb_data));
        for var i := 0 to count-1 do
        begin
          var ec := cl.SetEventCallback(evs[i], CommandExecutionStatus.COMPLETE, multi_attachable_callback, hnd_ptr);
          OpenCLABCInternalException.RaiseIfError(ec);
        end;
      end;
    end;
    
    {$endregion MultiAttachCallback}
    
    {$region Retain/Release}
    
    public procedure Retain({$ifdef EventDebug}reason: string{$endif}) :=
    for var i := 0 to count-1 do
    begin
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(evs[i], $'{reason}, together with evs: {evs.Take(count).JoinToString}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError( cl.RetainEvent(evs[i]) );
    end;
    
    public procedure Release({$ifdef EventDebug}reason: string{$endif}) :=
    for var i := 0 to count-1 do
    begin
      {$ifdef EventDebug}
      EventDebug.RegisterEventRelease(evs[i], $'{reason}, together with evs: {evs.Take(count).JoinToString}');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError( cl.ReleaseEvent(evs[i]) );
    end;
    
    // - cl.WaitForEvents spin waits until all events fire
    // - ManualResetEventSlim only spin waits for a bit (configurable)
    //
    // - cl.WaitForEvents may cancel wait on error in on branch
    // - MultiAttachCallback fires when everything is done
    public function ToMRE({$ifdef EventDebug}reason: string{$endif}): ManualResetEventSlim;
    begin
      Result := nil;
      if self.count=0 then exit;
      Result := new ManualResetEventSlim(false);
      var mre := Result;
      self.MultiAttachCallback(mre.Set{$ifdef EventDebug}, $'setting mre for {reason}'{$endif});
    end;
    
    {$endregion Retain/Release}
    
    {$region Event status}
    
    {$ifdef DEBUG}
    public static function GetStatus(ev: cl_event): CommandExecutionStatus;
    begin
      {$ifdef EventDebug}
      EventDebug.VerifyExists(ev, $'checking event status');
      {$endif EventDebug}
      OpenCLABCInternalException.RaiseIfError(
        cl.GetEventInfo(ev, EventInfo.EVENT_COMMAND_EXECUTION_STATUS, new UIntPtr(sizeof(CommandExecutionStatus)), Result, IntPtr.Zero)
      );
    end;
    {$endif DEBUG}
    
    {$ifdef DEBUG}
    public static function HasCompleted(ev: cl_event): boolean;
    begin
      var st := GetStatus(ev);
      Result := (st=CommandExecutionStatus.COMPLETE) or (st.val<0);
    end;
    {$endif DEBUG}
    
    {$ifdef DEBUG}
    public function HasCompleted: boolean;
    begin
      Result := false;
      for var i := 0 to count-1 do
        if not HasCompleted(evs[i]) then
          exit;
      Result := true;
    end;
    {$endif DEBUG}
    
    {$endregion Event status}
    
  end;
  
{$endregion EventList}

{$region DoubleEventListList}

type
  DoubleEventListList = sealed class
    private evs: array of EventList;
    private c1 := 0;
    private c2 := 0;
    {$ifdef DEBUG}
    private skipped := 0;
    {$endif DEBUG}
    
    public constructor(cap: integer) :=
    evs := new EventList[cap];
    private constructor := raise new OpenCLABCInternalException;
    
    public property Capacity: integer read evs.Length;
    
    {$ifdef DEBUG}
    private procedure CheckFill(exp_done: boolean);
    begin
      var done_c := c1+c2+skipped;
      if (done_c=Capacity) <> exp_done then raise new OpenCLABCInternalException(
        if exp_done then
          $'Too much EnqEv capacity: {done_c}/{evs.Length} used' else
          $'Not enough EnqEv capacity'
      );
    end;
    {$endif DEBUG}
    
    public procedure AddL1(ev: EventList);
    begin
      {$ifdef DEBUG}
      CheckFill(false);
      if ev.count=0 then raise new OpenCLABCInternalException($'Empty event');
      {$endif DEBUG}
      evs[c1] := ev;
      c1 += 1;
    end;
    public procedure AddL2(ev: EventList);
    begin
      {$ifdef DEBUG}
      CheckFill(false);
      if ev.count=0 then raise new OpenCLABCInternalException($'Empty event');
      {$endif DEBUG}
      c2 += 1;
      evs[evs.Length-c2] := ev;
    end;
    {$ifdef DEBUG}
    private procedure FakeAdd := skipped += 1;
    {$endif DEBUG}
    
    public function MakeLists: ValueTuple<EventList, EventList>;
    begin
      {$ifdef DEBUG}
      CheckFill(true);
      {$endif DEBUG}
      Result := ValueTuple.Create(
        EventList.Combine(new ArraySegment<EventList>(evs,0,c1)),
        EventList.Combine(new ArraySegment<EventList>(evs,evs.Length-c2,c2))
      );
    end;
    
  end;
  
{$endregion DoubleEventListList}

{$region CLTaskErrHandler}

{$region Def}

type
  CLTaskErrHandler = abstract class
    private local_err_lst := new List<Exception>;
    
    public function AccessErrors: List<Exception>;
    begin
      {$ifdef DEBUG}
      EndMaybeError($'.AccessErrors[{self.GetHashCode}]');
      {$endif DEBUG}
      had_error_cache := nil;
      Result := local_err_lst;
    end;
    
    {$region AddErr}
    
    protected procedure AddErr(e: Exception{$ifdef DEBUG}; test_reason: string{$endif});
    begin
      if e is OpenCLABCInternalException then
        // Inner exceptions should not get handled
        System.Runtime.ExceptionServices.ExceptionDispatchInfo.Capture(e).Throw;
      {$ifdef DEBUG}
      VerifyDoneInPrev(new HashSet<CLTaskErrHandler>);
      if test_reason not in tests_exp then raise new OpenCLABCInternalException($'AddMaybeError was not called');
      {$endif DEBUG}
      
      // One ErrHandler object can be reused:
      // HPQ + HPQ(raise)
      had_error_cache := true;
      
      local_err_lst += e;
    end;
    
    {$endregion AddErr}
    
    {$region HadError}
    
    private had_error_cache := default(boolean?);
    protected function HadErrorInPrev: boolean; abstract;
    public function HadError: boolean;
    begin
      {$ifdef DEBUG}
      VerifyDoneInPrev(new HashSet<CLTaskErrHandler>);
      {$endif DEBUG}
      
      if had_error_cache<>nil then
      begin
        Result := had_error_cache.Value;
        exit;
      end;
      
      Result := (local_err_lst.Count<>0) or HadErrorInPrev;
      had_error_cache := Result;
    end;
    
    {$endregion HadError}
    
    {$region Error transfer}
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; abstract;
    protected function TryRemoveErrors(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean;
    begin
      Result := false;
      if had_error_cache=false then exit;
      
      Result := TryRemoveErrorsInPrev(origin_cache, handler);
      
      Result := (local_err_lst.RemoveAll(handler)<>0) or Result;
      if Result then had_error_cache := nil;
    end;
    public procedure TryRemoveErrors(handler: Exception->boolean) :=
    TryRemoveErrors(new Dictionary<CLTaskErrHandler, boolean>, handler);
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); abstract;
    protected procedure FillErrLst(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>);
    begin
      {$ifdef DEBUG}
      {$else DEBUG}
      if not HadError then exit;
      {$endif DEBUG}
      
      FillErrLstWithPrev(origin_cache, lst);
      
      lst.AddRange(local_err_lst);
    end;
    public procedure FillErrLst(lst: List<Exception>) :=
    FillErrLst(new HashSet<CLTaskErrHandler>, lst);
    
    {$endregion Error transfer}
    
    {$region Done checks} {$ifdef DEBUG}
    
    private tests_exp := new List<string>;
    private tests_done := new HashSet<string>;
    private function TestsReport: string;
    begin
      var res := new StringBuilder;
      res += 'Expected: ['#10;
      lock tests_exp do foreach var t in tests_exp do
      begin
        res += #9;
        res += t;
        res += #10;
      end;
      res += ']; Done: ['#10;
      lock tests_done do foreach var t in tests_done do
      begin
        res += #9;
        res += t;
        res += #10;
      end;
      res += ']';
      Result := res.ToString;
    end;
    
    public procedure AddMaybeError(reason: string) :=
    lock tests_exp do tests_exp += reason;
    
    public procedure EndMaybeError(reason: string) :=
    lock tests_exp do
    begin
      if not tests_exp.Remove(reason) then
        raise new OpenCLABCInternalException($'Test [{reason}] was no expected; {TestsReport}');
      tests_done += reason;
    end;
    
    protected procedure VerifyDoneInPrev(origin_cache: HashSet<CLTaskErrHandler>); abstract;
    protected procedure VerifyDone(origin_cache: HashSet<CLTaskErrHandler>);
    begin
      VerifyDoneInPrev(origin_cache);
      if tests_exp.Count<>0 then
        raise new OpenCLABCInternalException($'Not all tests done; {TestsReport}');
    end;
    
    public procedure SanityCheck(err_lst: List<Exception>);
    begin
      VerifyDone(new HashSet<CLTaskErrHandler>);
      
      // QErr*QErr - second cache wouldn't be calculated
//      if had_error_cache=nil then
//        raise new OpenCLABCInternalException($'SanityCheck expects all had_error_cache to exist');
      
      begin
        var had_error := self.HadError;
        if had_error <> (err_lst.Count<>0) then
          raise new OpenCLABCInternalException($'{had_error} <> {err_lst.Count}');
      end;
      
    end;
    
    {$endif DEBUG} {$endregion Done checks}
    
  end;
  
  CLTaskErrHandlerEmpty = sealed class(CLTaskErrHandler)
    
    public constructor := exit;
    
    protected function HadErrorInPrev: boolean; override := false;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override := false;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override := exit;
    
    {$ifdef DEBUG}
    protected procedure VerifyDoneInPrev(origin_cache: HashSet<CLTaskErrHandler>); override := exit;
    {$endif DEBUG}
    
  end;
  
  CLTaskErrHandlerBranchBud = sealed class(CLTaskErrHandler)
    private origin: CLTaskErrHandler;
    
    public constructor(origin: CLTaskErrHandler) := self.origin := origin;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function HadErrorInPrev: boolean; override := origin.HadError;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      if origin_cache.TryGetValue(origin, Result) then exit;
      // Can't remove from here, because "A + B*C.Handle" would otherwise consume error in A
      // Instead CLTaskErrHandlerBranchCombinator handles origin
//      Result := origin.TryRemoveErrors(origin_cache, handler);
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      if origin in origin_cache then exit;
      origin.FillErrLst(origin_cache, lst);
    end;
    
    {$ifdef DEBUG}
    protected procedure VerifyDoneInPrev(origin_cache: HashSet<CLTaskErrHandler>); override;
    begin
      if origin in origin_cache then exit;
      origin.VerifyDone(origin_cache);
    end;
    {$endif DEBUG}
    
  end;
  CLTaskErrHandlerBranchCombinator = sealed class(CLTaskErrHandler)
    private origin: CLTaskErrHandler;
    private branches: array of CLTaskErrHandler;
    
    public constructor(origin: CLTaskErrHandler; branches: array of CLTaskErrHandler);
    begin
      self.origin := origin;
      self.branches := branches;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function HadErrorInPrev: boolean; override;
    begin
      Result := origin.HadError;
      if Result then exit;
      foreach var h in branches do
      begin
        Result := h.HadError;
        if Result then exit;
      end;
    end;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      Result := origin.TryRemoveErrors(origin_cache, handler);
      origin_cache.Add(origin, Result);
      foreach var h in branches do
        Result := h.TryRemoveErrors(origin_cache, handler) or Result;
      origin_cache.Remove(origin);
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      origin.FillErrLst(origin_cache, lst);
      {$ifdef DEBUG}if not{$endif}origin_cache.Add(origin)
      {$ifdef DEBUG}then
        raise new OpenCLABCInternalException($'Origin added multiple times');
      {$endif DEBUG};
      foreach var h in branches do
        h.FillErrLst(origin_cache, lst);
      origin_cache.Remove(origin);
    end;
    
    {$ifdef DEBUG}
    protected procedure VerifyDoneInPrev(origin_cache: HashSet<CLTaskErrHandler>); override;
    begin
      origin.VerifyDone(origin_cache);
      origin_cache += origin;
      foreach var h in branches do
        h.VerifyDone(origin_cache);
      origin_cache -= origin;
    end;
    {$endif DEBUG}
    
  end;
  
  CLTaskErrHandlerThiefBase = abstract class(CLTaskErrHandler)
    protected victim: CLTaskErrHandler;
    
    public constructor(victim: CLTaskErrHandler) := self.victim := victim;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function CanSteal: boolean; abstract;
    public procedure StealPrevErrors;
    begin
      if victim=nil then exit;
      if CanSteal then
        victim.FillErrLst(self.local_err_lst);
      victim := nil;
    end;
    
    protected function HadErrorInVictim: boolean :=
    (victim<>nil) and victim.HadError;
    
  end;
  CLTaskErrHandlerThief = sealed class(CLTaskErrHandlerThiefBase)
    
    protected function CanSteal: boolean; override := true;
    
    protected function HadErrorInPrev: boolean; override := HadErrorInVictim;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      StealPrevErrors;
      Result := false;
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      StealPrevErrors;
    end;
    
    {$ifdef DEBUG}
    protected procedure VerifyDoneInPrev(origin_cache: HashSet<CLTaskErrHandler>); override;
    begin
      victim.VerifyDone(origin_cache);
    end;
    {$endif DEBUG}
    
  end;
  /// Repeats first handler, but also steals errors from second, if first is OK
  CLTaskErrHandlerThiefRepeater = sealed class(CLTaskErrHandlerThiefBase)
    private prev_handler: CLTaskErrHandler;
    
    public constructor(prev_handler, victim: CLTaskErrHandler);
    begin
      inherited Create(victim);
      self.prev_handler := prev_handler;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function CanSteal: boolean; override :=
    not prev_handler.HadError;
    
    protected function HadErrorInPrev: boolean; override :=
    // mu_handler.HadError would be called more often,
    // so it's more likely to already have cache
    HadErrorInVictim or prev_handler.HadError;
    
    protected function TryRemoveErrorsInPrev(origin_cache: Dictionary<CLTaskErrHandler, boolean>; handler: Exception->boolean): boolean; override;
    begin
      Result := prev_handler.TryRemoveErrors(origin_cache, handler);
      if CanSteal then StealPrevErrors;
    end;
    
    protected procedure FillErrLstWithPrev(origin_cache: HashSet<CLTaskErrHandler>; lst: List<Exception>); override;
    begin
      var prev_c := lst.Count;
      prev_handler.FillErrLst(lst);
      if prev_c=lst.Count then StealPrevErrors;
    end;
    
    {$ifdef DEBUG}
    protected procedure VerifyDoneInPrev(origin_cache: HashSet<CLTaskErrHandler>); override;
    begin
      if victim<>nil then victim.VerifyDone(origin_cache);
      prev_handler.VerifyDone(origin_cache);
    end;
    {$endif DEBUG}
    
  end;
  
{$endregion Def}

{$region Use}

type
  CLTaskGlobalData = sealed partial class
    
    public curr_err_handler: CLTaskErrHandler := new CLTaskErrHandlerEmpty;
    
  end;
  
procedure TODO_2036_1 := exit; //TODO #2036

[MethodImpl(MethodImplOptions.AggressiveInlining)]
procedure Invoke<TInp>(self: ISimpleProcContainer<TInp>; err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}; inp: TInp; c: CLContext); extensionmethod;
begin
  if not err_handler.HadError then
  try
    self.Invoke(inp, c);
  except
    on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif});
  end;
  {$ifdef DEBUG}
  err_handler.EndMaybeError(err_test_reason);
  {$endif DEBUG}
end;

[MethodImpl(MethodImplOptions.AggressiveInlining)]
function Invoke<TInp,TRes>(self: ISimpleFuncContainer<TInp,TRes>; err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}; inp: TInp; c: CLContext): TRes; extensionmethod;
begin
  if not err_handler.HadError then
  try
    Result := self.Invoke(inp, c);
  except
    on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif});
  end;
  {$ifdef DEBUG}
  err_handler.EndMaybeError(err_test_reason);
  {$endif DEBUG}
end;

{$endregion Use}

{$endregion CLTaskErrHandler}

{$region UserEvent}

type
  UserEvent = sealed class
    private uev: cl_event;
    private done := new InterlockedBoolean;
    
    {$region constructor's}
    
    private constructor(c: cl_context{$ifdef EventDebug}; reason: string{$endif});
    begin
      var ec: ErrorCode;
      self.uev := cl.CreateUserEvent(c, ec);
      OpenCLABCInternalException.RaiseIfError(ec);
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(self.uev, $'Created for {reason}');
      {$endif EventDebug}
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public static function StartWorkThread(after: EventList; work: Action; g: CLTaskGlobalData{$ifdef EventDebug}; reason: string{$endif}): UserEvent;
    begin
      var res := new UserEvent(g.cl_c
        {$ifdef EventDebug}, $'ThreadedWork, executing {reason}, after waiting on: {after.evs?.JoinToString}'{$endif}
      );
      
      var mre := after.ToMRE({$ifdef EventDebug}$'Threaded work with res_ev={res}'{$endif});
      var err_handler := g.curr_err_handler;
      var thr := new Thread(()->
      try
        if mre<>nil then mre.Wait;
        work;
      finally
        res.SetComplete(err_handler.HadError);
      end);
      thr.IsBackground := true;
      thr.Start;
      
      Result := res;
    end;
    
    {$endregion constructor's}
    
    {$region Status}
    
    /// True если статус получилось изменить
    public function SetComplete(had_error: boolean): boolean;
    begin
      Result := done.TrySet(true);
      if not Result then exit;
      // - Old INTEL drivers break if callback invoked by SetUserEventStatus deletes own event
      //TODO Delete this retain/release pair at some point
      OpenCLABCInternalException.RaiseIfError(cl.RetainEvent(uev));
      try
        OpenCLABCInternalException.RaiseIfError(
          cl.SetUserEventStatus(uev,
            if had_error then
              CommandExecutionStatus.Create(OpenCLABCInternalException.RelayErrorCode) else
              CommandExecutionStatus.COMPLETE
          )
        );
      finally
        OpenCLABCInternalException.RaiseIfError(cl.ReleaseEvent(uev));
      end;
    end;
    
    {$endregion Status}
    
    {$region operator's}
    
    public static function operator implicit(ev: UserEvent): cl_event := ev.uev;
    public static function operator implicit(ev: UserEvent): EventList := ev.uev;
    
    //TODO #????
//    public static function operator+(ev1: EventList; ev2: UserEvent): EventList;
//    begin
//      Result := ev1 + ev2.uev;
//      Result.abortable := true;
//    end;
//    public static procedure operator+=(ev1: EventList; ev2: UserEvent);
//    begin
//      ev1 += ev2.uev;
//      ev1.abortable := true;
//    end;
    
    public function ToString: string; override := $'UserEvent[{uev.val}]';
    
    {$endregion operator's}
    
  end;
  
{$endregion UserEvent}

{$region QueueResAction}

type
  QueueResAction = CLContext->();
  
  [StructLayout(LayoutKind.Auto)]
  QueueResComplDelegateData = record
    private call_list: array of QueueResAction := nil;
    private count := 0;
    
    private const initial_cap = 4;
    
    public constructor := exit;
    public constructor(d: QueueResAction);
    begin
      call_list := new QueueResAction[initial_cap];
      call_list[0] := d;
      count := 1;
    end;
    
    public procedure AddAction(d: QueueResAction);
    begin
      if count=0 then
        call_list := new QueueResAction[initial_cap] else
      if count=call_list.Length then
        System.Array.Resize(call_list, call_list.Length * 4);
      call_list[count] := d;
      count += 1;
    end;
    public procedure AddActions(l: QueueResComplDelegateData);
    begin
      {$ifdef DEBUG}
      if l.count=0 then raise new OpenCLABCInternalException($'');
      {$endif DEBUG}
      if self.count=0 then
      begin
        self.call_list := l.call_list;
        self.count := l.count;
        exit;
      end;
      
      var new_cap := Max(self.call_list.Length, l.call_list.Length);
      if self.count+l.count > new_cap then
        new_cap *= 2;
      
      if l.call_list.Length=new_cap then
      begin
        System.Array.Copy(   l.call_list,0, l.call_list,self.count, l.count);
        System.Array.Copy(self.call_list,0, l.call_list,0,          self.count);
        self.call_list := l.call_list;
        self.count += l.count;
      end else
      begin
        if self.call_list.Length<>new_cap then
          System.Array.Resize(self.call_list, new_cap);
        System.Array.Copy(l.call_list,0, self.call_list,self.count, l.count);
        self.count += l.count;
      end;
      
    end;
    
    {$ifdef DEBUG}
    private last_invoke_trace := default(string);
    {$endif DEBUG}
    public procedure Invoke(c: CLContext);
    begin
      {$ifdef DEBUG}
      if last_invoke_trace<>nil then raise new System.InvalidProgramException($'{TypeName(self)}: {#10}{last_invoke_trace}{#10+''-''*30+#10}{System.Environment.StackTrace}');
      last_invoke_trace := System.Environment.StackTrace;
      {$endif DEBUG}
      for var i := 0 to count-1 do
        call_list[i](c);
    end;
    
    {$ifdef DEBUG}
    private const _taken_out_acts_c = -1;
    {$endif DEBUG}
    public function IsTakenOut: boolean;
    begin
      Result := false;
      {$ifdef DEBUG}
      Result := self.count = _taken_out_acts_c;
      {$endif DEBUG}
    end;
    public function TakeOut: QueueResComplDelegateData;
    begin
      Result := self;
      self.call_list := nil;
      {$ifdef DEBUG}
      self.count := _taken_out_acts_c;
      {$endif DEBUG}
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AttachInvokeTo(ev: EventList; g: CLTaskGlobalData{$ifdef EventDebug}; qr: object{$endif}): EventList;
    begin
      var acts := self.TakeOut;
      
      if acts.count=0 then
      begin
        Result := ev;
        exit;
      end else
      {$ifdef DEBUG}
      if acts.IsTakenOut then // Check double .AttachInvokeTo call
        raise new OpenCLABCInternalException($'.AttachInvokeActions called twice') else
      if (ev.count=0) and (acts.count<>0) then
        raise new OpenCLABCInternalException($'Broken .Invoke') else
      {$endif DEBUG}
        ;
      
      var uev := new UserEvent(g.cl_c{$ifdef EventDebug}, $'res_ev for {TypeName(qr)}.AttachInvokeActions, after: {ev.evs?.JoinToString}'{$endif});
      var c := g.c;
      var err_handler := g.curr_err_handler;
      ev.MultiAttachCallback(()->
      begin
        acts.Invoke(c);
        uev.SetComplete(err_handler.HadError);
      end{$ifdef EventDebug}, $'body of {TypeName(qr)}.AttachInvokeActions with res_ev={uev}'{$endif});
      
      Result := uev;
    end;
    
    {$ifdef DEBUG}
    public procedure AssertFinalIntegrity :=
    if (call_list<>nil) and (last_invoke_trace=nil) then
    begin
      var sb := new StringBuilder;
      sb += 'Actions were not called:'#10;
      for var i := 0 to count-1 do
      begin
        CommandQueueBase.ToStringWriteDelegate(sb, call_list[i]);
        sb += #10;
      end;
      raise new System.InvalidProgramException(sb.ToString);
    end;
    {$endif DEBUG}
    
  end;
  
{$endregion QueueResAction}

{$region CLTaskLocalData}

type
  [StructLayout(LayoutKind.Auto)]
  CLTaskLocalData = record
    public prev_delegate := default(QueueResComplDelegateData);
    public prev_ev := EventList.Empty;
    
    public constructor := exit;
    public constructor(ev: EventList) := self.prev_ev := ev;
    
    public function ShouldInstaCallAction: boolean;
    begin
      // Only const can have not events
      Result := prev_ev.count=0;
      {$ifdef DEBUG}
      if Result and (prev_delegate.count<>0) then raise new OpenCLABCInternalException($'Broken Quick.Invoke detected');
      {$endif DEBUG}
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AttachInvokeActions(g: CLTaskGlobalData) :=
    prev_delegate.AttachInvokeTo(prev_ev, g{$ifdef EventDebug}, self{$endif});
    
  end;
  
  CommandQueueInvoker<TR> = (CLTaskGlobalData, CLTaskLocalData)->TR;
  
{$endregion CLTaskLocalData}

{$region QueueRes}

{$region Base}

type
  IQueueRes = interface
    
    property ResEv: EventList read;
    
    function ShouldInstaCallAction: boolean;
    procedure AddAction(d: QueueResAction);
    procedure AddActions(d: QueueResComplDelegateData);
    
    function AttachInvokeActions(g: CLTaskGlobalData): EventList;
    
    function MakeWrapWithImpl(new_ev: EventList): IQueueRes;
    
    procedure SetRes<TRes>(res: TRes);
    
  end;
  
  QueueRes<T> = abstract partial class end;
  IQueueResFactory<T,TR> = interface
  where TR: IQueueRes;
    
    function MakeConst(l: CLTaskLocalData; res: T): TR;
    
    function MakeDelayed(l: CLTaskLocalData; make_act: TR->QueueResAction): TR;
    function MakeDelayed(make_l: TR->CLTaskLocalData): TR;
    
    function MakeWrap(qr: QueueRes<T>; new_ev: EventList): TR;
    
  end;
  
  [StructLayout(LayoutKind.Auto)]
  QueueResData = record
    private complition_delegate  := default(QueueResComplDelegateData);
    private ev                   := EventList.Empty;
    {$ifdef DEBUG}
    private creation_trace := Environment.StackTrace;
    {$endif DEBUG}
    
    public static function operator implicit(base: QueueResData): CLTaskLocalData;
    begin
      Result := new CLTaskLocalData(base.ev);
      Result.prev_delegate := base.complition_delegate;
    end;
    
    public property ResEv: EventList read ev;
    
    public function ShouldInstaCallAction: boolean;
    begin
      {$ifdef DEBUG}
      if complition_delegate.IsTakenOut then
        raise new OpenCLABCInternalException($'ShouldInstaCallAction when action is already gone');
      {$endif DEBUG}
      Result := CLTaskLocalData(self).ShouldInstaCallAction;
    end;
    
    private procedure CheckValidAddAction;
    begin
      {$ifdef DEBUG}
      if ShouldInstaCallAction then raise new OpenCLABCInternalException($'Broken Quick.Invoke detected');
      {$endif DEBUG}
    end;
    public procedure AddAction(d: QueueResAction);
    begin
      CheckValidAddAction;
      complition_delegate.AddAction(d);
    end;
    public procedure AddActions(d: QueueResComplDelegateData);
    begin
      if d.count=0 then exit;
      CheckValidAddAction;
      complition_delegate.AddActions(d);
    end;
    
  end;
  
{$endregion Base}

{$region Nil}

type
  [StructLayout(LayoutKind.Auto)]
  QueueResNil = record(IQueueRes)
    private base := new QueueResData;
    
    {$ifdef DEBUG}
    public static created_count := 0;
    {$endif DEBUG}
    
    public constructor(l: CLTaskLocalData);
    begin
      {$ifdef DEBUG}
      Interlocked.Increment(created_count);
      {$endif DEBUG}
      base.ev := l.prev_ev;
      base.complition_delegate := l.prev_delegate;
    end;
    public constructor(ev: EventList) := Create(new CLTaskLocalData(ev));
    public constructor := raise new OpenCLABCInternalException;
    
    public property ResEv: EventList read base.ResEv;
    
    public function ShouldInstaCallAction := base.ShouldInstaCallAction;
    public procedure AddAction(d: QueueResAction) := base.AddAction(d);
    public procedure AddActions(d: QueueResComplDelegateData) := base.AddActions(d);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AttachInvokeActions(g: CLTaskGlobalData) :=
    base.complition_delegate.AttachInvokeTo(base.ResEv, g{$ifdef EventDebug}, self{$endif});
    
    public procedure InvokeActions(c: CLContext) := base.complition_delegate.Invoke(c);
    
    //TODO mono#11034
    public function {IQueueRes.}MakeWrapWithImpl(new_ev: EventList): IQueueRes := new QueueResNil(new_ev);
    
    //TODO mono#11034
    public procedure {IQueueRes.}SetRes<TRes>(res: TRes) := exit;
    
  end;
  
  QueueResNilFactory<T> = record(IQueueResFactory<T, QueueResNil>)
    
    public function MakeConst(l: CLTaskLocalData; res: T) := new QueueResNil(l);
    
    public function MakeDelayed(l: CLTaskLocalData; make_act: QueueResNil->QueueResAction): QueueResNil;
    begin
      Result := new QueueResNil(l);
      Result.AddAction(make_act(Result));
    end;
    public function MakeDelayed(make_l: QueueResNil->CLTaskLocalData) := new QueueResNil(make_l(default(QueueResNil)));
    
    public function MakeWrap(qr: QueueRes<T>; new_ev: EventList) := new QueueResNil(new_ev);
    
  end;
  QueueRes<T> = abstract partial class
    static nil_factory := new QueueResNilFactory<T>;
  end;
  
{$endregion Nil}

{$region <T>}

{$region Base}

type
  QueueResT = abstract class(IQueueRes)
    private base := new QueueResData;
    private res_const: boolean; // Whether res can be read before event completes
    
    {$ifdef DEBUG}
    public static created_count := new ConcurrentDictionary<string, integer>;
    public constructor;
    begin
      created_count.AddOrUpdate(TypeName(self), t->1, (t,c)->c+1);
    end;
    {$endif DEBUG}
    
    public property ResEv: EventList read base.ResEv;
    
    private function GetIsConst: boolean;
    begin
      Result := res_const;
      {$ifdef DEBUG}
      if not Result and not base.complition_delegate.IsTakenOut and ShouldInstaCallAction then
        raise new OpenCLABCInternalException($'Need to insta call implies const result');
      {$endif DEBUG}
    end;
    public property IsConst: boolean read GetIsConst;
    
    public function ShouldInstaCallAction := base.ShouldInstaCallAction;
    public procedure AddAction(d: QueueResAction) := base.AddAction(d);
    public procedure AddActions(d: QueueResComplDelegateData) := base.AddActions(d);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AttachInvokeActions(g: CLTaskGlobalData) :=
    base.complition_delegate.AttachInvokeTo(base.ResEv, g{$ifdef EventDebug}, self{$endif});
    
    public function MakeWrapWithImpl(new_ev: EventList): IQueueRes; abstract;
    
    {$ifdef DEBUG}
    private procedure CancelStatusCheck(reason: string) :=
    ResEv.Release({$ifdef EventDebug}$'cancel status check of {TypeName(self)}[{self.GetHashCode}], because {reason}'{$endif});
    {$endif DEBUG}
    public function TakeBaseOut: QueueResData;
    begin
      Result := self.base;
      {$ifdef DEBUG}
      CancelStatusCheck($'base was taken out');
      {$endif DEBUG}
      self.base := default(QueueResData);
      {$ifdef DEBUG}
      base.complition_delegate.count := QueueResComplDelegateData._taken_out_acts_c;
      {$endif DEBUG}
    end;
    
    public procedure SetRes<TRes>(res: TRes); abstract;
    
  end;
  
  QueueRes<T> = abstract partial class(QueueResT)
    
    protected procedure InitConst(l: CLTaskLocalData; res: T);
    begin
      base.ev := l.prev_ev;
      base.complition_delegate := l.prev_delegate;
      SetRes(res);
      res_const := true;
      {$ifdef DEBUG}
      ExpectCheckStatus;
      {$endif DEBUG}
    end;
    
    protected procedure InitDelayed(l: CLTaskLocalData);
    begin
      base.ev := l.prev_ev;
      base.complition_delegate := l.prev_delegate;
      {$ifdef DEBUG}
      if ResEv.count=0 then raise new OpenCLABCInternalException($'Delayed QueueRes, but it is not delayed');
      ExpectCheckStatus;
      {$endif DEBUG}
    end;
    protected procedure InitDelayed(l: CLTaskLocalData; act: QueueResAction);
    begin
      InitDelayed(l);
      AddAction(act);
    end;
    
    protected procedure InitWrap(prev_qr: QueueRes<T>; new_ev: EventList);
    begin
      base.ev := new_ev;
      {$ifdef DEBUG}
      ExpectCheckStatus;
      MarkResSet;
      {$endif DEBUG}
      self.res_const := prev_qr.res_const;
    end;
    
    {$ifdef DEBUG}
    private res_last_set := default(string);
    protected procedure MarkResSet;
    begin
      if res_const then raise new OpenCLABCInternalException($'Result set on const qr');
      if res_last_set<>nil then raise new OpenCLABCInternalException($'Result set twice: {#10}{res_last_set}{#10+''-''*30+#10}{System.Environment.StackTrace}');
      res_last_set := Environment.StackTrace;
    end;
    {$endif DEBUG}
    
    {$ifdef DEBUG}
    private status_checked := new InterlockedBoolean;
    protected procedure ExpectCheckStatus :=
    ResEv.Retain({$ifdef EventDebug}$'for status check of {TypeName(self)}[{self.GetHashCode}]'{$endif});
    protected procedure CheckStatus :=
    if status_checked.TrySet(true) then
    begin
      if not IsConst and not ResEv.HasCompleted then
      begin
        var err := new StringBuilder($'Result read before {ResEv.count} events completed:');
        for var i := 0 to ResEv.count-1 do
        begin
          err += #10#9;
          err += ResEv[i].ToString;
          err += ': ';
          err += EventList.GetStatus(ResEv[i]).ToString;
        end;
        {$ifdef EventDebug}
        EventDebug.ReportEventLogs(Console.Error);
        {$endif EventDebug}
        raise new OpenCLABCInternalException(err.ToString);
      end;
      ResEv.Release({$ifdef EventDebug}$'after status check of {TypeName(self)}[{self.GetHashCode}]'{$endif});
    end;
    {$endif DEBUG}
    
    public procedure SetRes<TRes>(res: TRes); override := SetRes(T(res as object));
    public procedure SetRes(res: T);
    begin
      {$ifdef DEBUG}
      MarkResSet;
      {$endif DEBUG}
      SetResImpl(res);
    end;
    protected procedure SetResImpl(res: T); abstract;
    public function GetRes(c: CLContext): T;
    begin
      base.complition_delegate.Invoke(c);
      Result := GetResDirect;
    end;
    public function GetResDirect: T;
    begin
      {$ifdef DEBUG}
      CheckStatus;
      {$endif DEBUG}
      Result := GetResImpl;
    end;
    protected function GetResImpl: T; abstract;
    
    {$ifdef DEBUG}
    protected procedure Finalize; override;
    begin
      base.complition_delegate.AssertFinalIntegrity;
      if res_last_set=nil then raise new OpenCLABCInternalException($'Result was not set for qr created at{#10}{base.creation_trace}{#10+''-''*30}');
    end;
    {$endif DEBUG}
    
  end;
  
{$endregion Base}

{$region Val}

type
  QueueResVal<T> = abstract partial class(QueueRes<T>)
    
    public function MakeWrapWithImpl(new_ev: EventList): IQueueRes; override;
    
  end;
  
  QueueResValDirect<T> = sealed class(QueueResVal<T>)
    private res: T;
    
    public constructor(l: CLTaskLocalData; res: T) := InitConst(l, res);
    
    public constructor(l: CLTaskLocalData; make_act: QueueResVal<T>->QueueResAction) := InitDelayed(l, make_act(self));
    public constructor(make_l: QueueResVal<T>->CLTaskLocalData) := InitDelayed(make_l(self));
    
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure SetResImpl(res: T); override := self.res := res;
    protected function GetResImpl: T; override := self.res;
    
  end;
  
  QueueResValWrap<T> = sealed class(QueueResVal<T>)
    private prev_qr: QueueRes<T>;
    
    public constructor(prev_qr: QueueRes<T>; new_ev: EventList);
    begin
      {$ifdef DEBUG}
      // While debuging .GetResDirect should be called on all wraps
      // Otherwise some status checks would be skipped
      {$else DEBUG}
      if prev_qr is QueueResValWrap<T>(var qrw) then prev_qr := qrw.prev_qr;
      {$endif DEBUG}
      InitWrap(prev_qr, new_ev);
      self.prev_qr := prev_qr;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure SetResImpl(res: T); override := raise new OpenCLABCInternalException($'QueueResValWrap is made for indirect read of QueueRes, it should not be written to');
    protected function GetResImpl: T; override := prev_qr.GetResDirect;
    
  end;
  
  QueueResValFactory<T> = sealed class(IQueueResFactory<T, QueueResVal<T>>)
    
    public function MakeConst(l: CLTaskLocalData; res: T): QueueResVal<T> :=
    new QueueResValDirect<T>(l, res);
    
    public function MakeDelayed(l: CLTaskLocalData; make_act: QueueResVal<T>->QueueResAction): QueueResVal<T> :=
    new QueueResValDirect<T>(l, make_act);
    public function MakeDelayed(make_l: QueueResVal<T>->CLTaskLocalData): QueueResVal<T> :=
    new QueueResValDirect<T>(make_l);
    
    public function MakeWrap(qr: QueueRes<T>; new_ev: EventList): QueueResVal<T> :=
    new QueueResValWrap<T>(qr, new_ev);
    
  end;
  QueueRes<T> = abstract partial class(QueueResT)
    public static function val_factory := new QueueResValFactory<T>;
  end;
  
{$endregion Val}

{$region Ptr}

type
  // LayoutKind.Auto is not compatible with GCHandle
  [StructLayout(LayoutKind.Sequential)]
  QueueResPtrData<T> = record
    public val: T;
    public ref_count: integer;
    
    public procedure Retain := Interlocked.Increment(ref_count);
    public function Release := Interlocked.Decrement(ref_count)=0;
    
  end;
  
  QueueResPtr<T> = sealed partial class(QueueRes<T>)
    private data: NativeValueArea<QueueResPtrData<T>>;
    
    static constructor := BlittableHelper.RaiseIfBad(typeof(T), $'%Err:Blittable:Source:QueueResPtr%');
    
    private procedure AllocData;
    begin
      data.Alloc;
      data.Pointer^.ref_count := 1;
    end;
    
    public constructor(l: CLTaskLocalData; res: T);
    begin
      AllocData;
      InitConst(l, res);
    end;
    
    public constructor(l: CLTaskLocalData; make_act: QueueResPtr<T>->QueueResAction);
    begin
      AllocData;
      InitDelayed(l, make_act(self));
    end;
    public constructor(make_l: QueueResPtr<T>->CLTaskLocalData);
    begin
      AllocData;
      InitDelayed(make_l(self));
    end;
    
    public constructor(prev_qr: QueueResPtr<T>; new_ev: EventList);
    begin
      InitWrap(prev_qr, new_ev);
      self.data := prev_qr.data;
      self.data.Value.Retain;
    end;
    public function MakeWrapWithImpl(new_ev: EventList): IQueueRes; override := new QueueResPtr<T>(self, new_ev);
    
    private constructor := raise new OpenCLABCInternalException;
    
    private function GetResPtrImpl := @(data.Pointer^.val);
    public function GetResPtrForRead: ^T;
    begin
      {$ifdef DEBUG}
      // The whole point of QRPtr is to not wait for ev before enq
      CancelStatusCheck($'result would be read from ptr');
      {$endif DEBUG}
      Result := GetResPtrImpl;
    end;
    public function GetResPtrForWrite: ^T;
    begin
      {$ifdef DEBUG}
      MarkResSet;
      {$endif DEBUG}
      Result := GetResPtrImpl;
    end;
    
    protected procedure SetResImpl(res: T); override := GetResPtrImpl^ := res;
    protected function GetResImpl: T; override := GetResPtrImpl^;
    
    protected procedure Finalize; override;
    begin
      if data.IsAllocated and data.Value.Release then data.Release;
      inherited;
    end;
    
  end;
  
  QueueResPtrFactory<T> = sealed class(IQueueResFactory<T, QueueResPtr<T>>)
    
    public function MakeConst(l: CLTaskLocalData; res: T) := new QueueResPtr<T>(l, res);
    
    public function MakeDelayed(l: CLTaskLocalData; make_act: QueueResPtr<T>->QueueResAction) := new QueueResPtr<T>(l, make_act);
    public function MakeDelayed(make_l: QueueResPtr<T>->CLTaskLocalData) := new QueueResPtr<T>(make_l);
    
    public function MakeWrap(prev_qr: QueueRes<T>; new_ev: EventList): QueueResPtr<T>;
    begin
      {$ifdef DEBUG}
      if not prev_qr.base.complition_delegate.IsTakenOut then
        raise new OpenCLABCInternalException($'.AttachInvokeActions should be called before making a wrap qr');
      {$endif DEBUG}
      
      if prev_qr is QueueResPtr<T>(var qrp) then
        Result := new QueueResPtr<T>(qrp, new_ev) else
      begin
        var l := new CLTaskLocalData(new_ev);
        
        Result := if prev_qr.IsConst then
          new QueueResPtr<T>(l, prev_qr.GetResDirect) else
          new QueueResPtr<T>(l, qr->c->qr.SetRes(prev_qr.GetResDirect));
        
      end;
      
    end;
    
  end;
  QueueRes<T> = abstract partial class(QueueResT)
    public static function ptr_factory := new QueueResPtrFactory<T>;
  end;
  
{$endregion Ptr}

{$endregion <T>}

{$region Impl}

{$region MakeWrapWith}

function QueueResVal<T>.MakeWrapWithImpl(new_ev: EventList) := val_factory.MakeWrap(self, new_ev);

[MethodImpl(MethodImplOptions.AggressiveInlining)]
function MakeWrapWith<TR>(self: TR; new_ev: EventList): TR; extensionmethod; where TR: IQueueRes;
begin
  Result := TR( self.MakeWrapWithImpl(new_ev) );
end;

{$endregion MakeWrapWith}

{$region TransformResult}

type
  QueueRes<T> = abstract partial class(QueueResT)
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function TransformResult<T2,TR>(factory: IQueueResFactory<T2,TR>; can_pre_call: boolean; transform: T->T2): TR; where TR: IQueueRes;
    begin
      // Before .TakeBaseOut, because .IsConst checks ResEv
      var should_make_const := if can_pre_call then
        self.IsConst else self.ShouldInstaCallAction;
      var res_l := CLTaskLocalData(self.TakeBaseOut);
      
      Result := if should_make_const then
        factory.MakeConst(res_l, transform(self.GetResDirect)) else
        factory.MakeDelayed(res_l, qr->c->qr.SetRes(transform(self.GetResDirect)));
      
    end;
    
  end;
  
{$endregion TransformResult}

{$region TrySkipInvoke}

function TrySkipInvoke<T,TR>(self: IQueueResFactory<T,TR>;
  g: CLTaskGlobalData; l: CLTaskLocalData;
  q: CommandQueue<T>; sub_inv: CommandQueueInvoker<QueueResNil>;
  var qr: TR
): boolean; extensionmethod; where TR: IQueueRes;
begin
  Result := g.CheckDeps(q.const_res_dep);
  if not Result then exit;
  qr := self.MakeConst(
    sub_inv(g,l).base,
    q.expected_const_res
  );
end;

{$endregion TrySkipInvoke}

{$region AddToEvLst}

type
  QueueRes<T> = abstract partial class
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function AddToEvLst<TR>(qr: TR; g: CLTaskGlobalData; evs: DoubleEventListList; to_l1: boolean): TR; where TR: QueueRes<T>;
    begin
      var ev := qr.AttachInvokeActions(g);
      if ev.count=0 then
        {$ifdef DEBUG}evs.FakeAdd{$endif} else
      if to_l1 and not qr.IsConst then
        evs.AddL1(ev) else
        evs.AddL2(ev);
      Result := qr;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AddToEvLst(g: CLTaskGlobalData; evs: DoubleEventListList; to_l1: boolean) := AddToEvLst(self, g, evs, to_l1);
    
  end;
  QueueResPtr<T> = sealed partial class
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AddToEvLst(g: CLTaskGlobalData; evs: DoubleEventListList; to_l1: boolean) := AddToEvLst(self, g, evs, to_l1);
    
  end;
  
{$endregion AddToEvLst}

{$endregion Impl}

{$endregion QueueRes}

{$endregion Invoke result}

{$region Invoke state}

{$region MultiuseableResultData}

type
  IMultiusableCommandQueue = interface end;
  [StructLayout(LayoutKind.Auto)]
  MultiuseableResultData = record
    public qres: IQueueRes;
    public ev: EventList;
    public err_handler: CLTaskErrHandler;
    
    public constructor(qres: IQueueRes; ev: EventList; err_handler: CLTaskErrHandler);
    begin
      self.qres := qres;
      self.ev := ev;
      self.err_handler := err_handler;
    end;
    
  end;
  CLTaskGlobalData = sealed partial class
    
    public mu_res := new Dictionary<IMultiusableCommandQueue, MultiuseableResultData>;
    
    public prev_mu := new HashSet<IMultiusableCommandQueue>;
    
  end;
  
{$endregion MultiuseableResultData}

{$region CLTaskBranchInvoker}

type
  CLTaskBranchInvoker = sealed class
    private g: CLTaskGlobalData;
    private prev_ev: EventList?;
    private prev_cq := cl_command_queue.Zero;
    private prev_mu: HashSet<IMultiusableCommandQueue>;
    
    private make_base_err_handler: ()->CLTaskErrHandler;
    private branch_handlers := new List<CLTaskErrHandler>;
    
    {$ifdef DEBUG}
    private missing_handler_c: integer;
    {$endif DEBUG}
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    constructor(g: CLTaskGlobalData; prev_ev: EventList?; capacity: integer);
    begin
      self.g := g;
      self.prev_ev := prev_ev;
      {$ifdef DEBUG}
      self.missing_handler_c := capacity;
      {$endif DEBUG}
      
      if g.curr_inv_cq<>cl_command_queue.Zero then
      begin
        {$ifdef DEBUG}
        if g.outer_cq<>cl_command_queue.Zero then raise new OpenCLABCInternalException($'outer_cq should be taken when curr_inv_cq is not Zero');
        {$endif DEBUG}
        
        // Make outer only if ParallelInvoke is said to wait for event of current cq
        // Otherwise command parameters would be added to outer cq, causing them to wait anyway
        if prev_ev<>nil then
        begin
          {$ifdef DEBUG}
          if prev_ev.Value.count=0 then raise new OpenCLABCInternalException($'prev_ev should not be Zero when curr_inv_cq is not Zero');
          {$endif DEBUG}
          g.outer_cq := g.curr_inv_cq;
        end else
          self.prev_cq := g.curr_inv_cq;
        
        g.curr_inv_cq := cl_command_queue.Zero;
      end;
      
      self.prev_mu := g.prev_mu;
      {$ifdef DEBUG}
      g.prev_mu := nil;
      {$endif DEBUG}
      
      if prev_ev=nil then
        self.make_base_err_handler := ()->new CLTaskErrHandlerEmpty else
      begin
        var origin_handler := g.curr_err_handler;
        self.make_base_err_handler := ()->new CLTaskErrHandlerBranchBud(origin_handler);
      end;
      self.branch_handlers.Capacity := capacity;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeBranch<TR>(branch: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      g.curr_err_handler := make_base_err_handler();
      var l := if self.prev_ev=nil then
        new CLTaskLocalData else
        new CLTaskLocalData(self.prev_ev.Value);
      
      g.prev_mu := if prev_ev<>nil then
        self.prev_mu.ToHashSet else
        new HashSet<IMultiusableCommandQueue>;
      
      Result := branch(g, l);
      
      self.prev_mu.UnionWith(g.prev_mu);
      {$ifdef DEBUG}
      g.prev_mu := nil;
      {$endif DEBUG}
      
      var cq := g.curr_inv_cq;
      if cq<>cl_command_queue.Zero then
      begin
        g.curr_inv_cq := cl_command_queue.Zero;
        if prev_cq=cl_command_queue.Zero then
          prev_cq := cq else
        begin
          OpenCLABCInternalException.RaiseIfError( cl.Flush(cq) );
          Result.AddAction(c->self.g.ReturnCQ(cq));
        end;
      end;
      
      branch_handlers += g.curr_err_handler;
      {$ifdef DEBUG}
      missing_handler_c -= 1;
      {$endif DEBUG}
    end;
    
    function GroupHandlers: CLTaskErrHandler;
    begin
      {$ifdef DEBUG}
      if prev_ev<>nil then
        raise new OpenCLABCInternalException($'Only expected to be used for l1/l2 separation');
      if branch_handlers.Count=0 then
        raise new OpenCLABCInternalException($'Optimization possible');
      {$endif DEBUG}
      Result := new CLTaskErrHandlerBranchCombinator(new CLTaskErrHandlerEmpty, branch_handlers.ToArray);
      branch_handlers.Clear;
      branch_handlers += Result;
    end;
    
  end;
  
  CLTaskGlobalData = sealed partial class
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ParallelInvoke(l: CLTaskLocalData?; capacity: integer; use: CLTaskBranchInvoker->());
    begin
      var prev_ev := default(EventList?);
      if l<>nil then
      begin
        var ev := l.Value.AttachInvokeActions(self);
        if ev.count<>0 then loop capacity-1 do
          ev.Retain({$ifdef EventDebug}$'for all async branches'{$endif});
        prev_ev := ev;
      end;
      
      var origin_handler := self.curr_err_handler;
      var invoker := new CLTaskBranchInvoker(self, prev_ev, capacity);
      use(invoker);
      
      {$ifdef DEBUG}
      if invoker.missing_handler_c<>0 then
        raise new OpenCLABCInternalException($'Missing {invoker.missing_handler_c} parallel branches of {capacity}');
      {$endif DEBUG}
      self.curr_err_handler := new CLTaskErrHandlerBranchCombinator(origin_handler, invoker.branch_handlers.ToArray);
      
      self.curr_inv_cq := invoker.prev_cq;
      if outer_cq<>cl_command_queue.Zero then self.GetCQ(false);
      
      self.prev_mu := invoker.prev_mu;
    end;
    
  end;
  
{$endregion CLTaskBranchInvoker}

{$region CLTaskGlobalData}

type
  CLTaskGlobalData = sealed partial class
    
    public constructor(c: CLContext);
    begin
      
      self.c := c;
      self.cl_c := c.ntv;
      self.cl_dvc := c.main_dvc.ntv;
      
    end;
    
    public procedure FinishInvoke;
    begin
      
      // mu выполняют лишний .Retain, чтобы ивент не удалился пока очередь ещё запускается
      foreach var mrd in mu_res.Values do
        mrd.ev.Release({$ifdef EventDebug}$'excessive mu ev'{$endif});
      mu_res := nil;
      
      if curr_inv_cq<>cl_command_queue.Zero then
      begin
        OpenCLABCInternalException.RaiseIfError( cl.Flush(curr_inv_cq) );
        ReturnCQ(curr_inv_cq);
      end;
      
    end;
    
    public procedure FinishExecution(var err_lst: List<Exception>);
    begin
      
      foreach var cq in free_cqs do
        OpenCLABCInternalException.RaiseIfError( cl.ReleaseCommandQueue(cq) );
      
      err_lst := new List<Exception>;
      curr_err_handler.FillErrLst(err_lst);
      {$ifdef DEBUG}
      curr_err_handler.SanityCheck(err_lst);
      {$endif DEBUG}
    end;
    
  end;
  
{$endregion CLTaskGlobalData}

{$endregion Invoke state}

{$endregion Util type's}

{$region CommandQueue}

{$region Base}

type
  CommandQueueBase = abstract partial class
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); abstract;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; abstract;
    
  end;
  
  CommandQueueNil = abstract partial class(CommandQueueBase)
    
  end;
  
  CommandQueue<T> = abstract partial class(CommandQueueBase)
    
    protected static function qr_nil_factory := QueueRes&<T>.nil_factory;
    protected static function qr_val_factory := QueueRes&<T>.val_factory;
    protected static function qr_ptr_factory := QueueRes&<T>.ptr_factory;
    
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; abstract;
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; abstract;
    
  end;
  
{$endregion Base}

{$region Const} type
  
  ConstQueueNil = sealed partial class(CommandQueueNil)
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := exit;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := new QueueResNil(l);
    
  end;
  
  ConstQueue<T> = sealed partial class(CommandQueue<T>)
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := exit;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := new QueueResNil(l);
    //TODO #????: Если убрать - ошибки компиляции нет, но сборка не загружается
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := qr_val_factory.MakeConst(l, self.Value);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := qr_ptr_factory.MakeConst(l, self.Value);
    
  end;
  
{$endregion Const}

{$region Parameter}

type
  ParameterQueue<T> = sealed partial class(CommandQueue<T>, IParameterQueue)
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override;
    begin
      //TODO #????
      if g.parameters.ContainsKey(self as object as IParameterQueue) then exit;
      //TODO #????
      g.parameters[self as object as IParameterQueue] := if self.DefaultDefined then
        new CLTaskParameterData(self.Default) else
        new CLTaskParameterData;
    end;
    
    private function GetParVal(g: CLTaskGlobalData) :=
    //TODO #????
    T(g.parameters[self as object as IParameterQueue].val);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := new QueueResNil(l);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := qr_val_factory.MakeConst(l, self.GetParVal(g));
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := qr_ptr_factory.MakeConst(l, self.GetParVal(g));
    
  end;
  
{$endregion Parameter}

{$endregion CommandQueue}

{$region CLTask}

type
  CLTaskBase = abstract partial class
    
  end;
  
  CLTaskNil = sealed partial class(CLTaskBase)
    
    private constructor(q: CommandQueueNil; c: CLContext; pars: array of ParameterQueueSetter);
    begin
      self.q := q;
      self.org_c := c;
      
      var g := new CLTaskGlobalData(c);
      
      q.InitBeforeInvoke(g, new HashSet<IMultiusableCommandQueue>);
      g.ApplyParameters(pars);
      var qr := q.InvokeToNil(g, new CLTaskLocalData);
      g.FinishInvoke;
      
      var mre := qr.ResEv.ToMRE({$ifdef EventDebug}$'CLTaskNil.FinishExecution'{$endif});
      var thr := new Thread(()->
      begin
        if mre<>nil then mre.Wait;
        qr.InvokeActions(self.org_c);
        g.FinishExecution(self.err_lst);
        self.wh.Set;
      end);
      thr.IsBackground := true;
      thr.Start;
      
    end;
    
  end;
  CLTask<T> = sealed partial class(CLTaskBase)
    private res: T;
    
    private constructor(q: CommandQueue<T>; c: CLContext; pars: array of ParameterQueueSetter);
    begin
      self.q := q;
      self.org_c := c;
      
      var g := new CLTaskGlobalData(c);
      
      q.InitBeforeInvoke(g, new HashSet<IMultiusableCommandQueue>);
      g.ApplyParameters(pars);
      var qr := q.InvokeToAny(g, new CLTaskLocalData);
      g.FinishInvoke;
      
      var mre := qr.ResEv.ToMRE({$ifdef EventDebug}$'CLTask<{typeof(T)}>.FinishExecution'{$endif});
      var thr := new Thread(()->
      begin
        if mre<>nil then mre.Wait;
        self.res := qr.GetRes(self.org_c);
        g.FinishExecution(self.err_lst);
        self.wh.Set;
      end);
      thr.IsBackground := true;
      thr.Start;
      
    end;
    
  end;
  
  CLTaskFactory = record(ITypedCQConverter<CLTaskBase>)
    private c: CLContext;
    private pars: array of ParameterQueueSetter;
    public constructor(c: CLContext; pars: array of ParameterQueueSetter);
    begin
      self.c := c;
      self.pars := pars;
    end;
    public constructor := raise new OpenCLABCInternalException;
    
    public function ConvertNil(cq: CommandQueueNil): CLTaskBase := new CLTaskNil(cq, c, pars);
    public function Convert<T>(cq: CommandQueue<T>): CLTaskBase := new CLTask<T>(cq, c, pars);
    
  end;
  
function CLContext.BeginInvoke(q: CommandQueueBase; params parameters: array of ParameterQueueSetter) := q.ConvertTyped(new CLTaskFactory(self, parameters));
function CLContext.BeginInvoke(q: CommandQueueNil; params parameters: array of ParameterQueueSetter) := new CLTaskNil(q, self, parameters);
function CLContext.BeginInvoke<T>(q: CommandQueue<T>; params parameters: array of ParameterQueueSetter) := new CLTask<T>(q, self, parameters);

function CLTask<T>.WaitRes: T;
begin
  Wait;
  Result := self.res;
end;

{$endregion CLTask}

{$region Queue converter's}

{$region +/*}

{$region Simple}

//TODO Попробовать пере-групировать
// - И затем сделать регионы
type
  SimpleQueueArrayCommon<TQ> = record
  where TQ: CommandQueueBase;
    public qs: array of CommandQueueBase;
    public last: TQ;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function GetQS: sequence of CommandQueueBase := qs.Append&<CommandQueueBase>(last);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>);
    begin
      foreach var q in qs do q.InitBeforeInvoke(g, inited_mu);
      last.InitBeforeInvoke(g, inited_mu);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeSync<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_last: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      for var i := 0 to qs.Length-1 do
        l := qs[i].InvokeToNil(g, l).base;
      
      Result := invoke_last(g, l);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeAsync<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_last: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      var evs := new EventList[qs.Length+1];
      
      var res: TR;
      g.ParallelInvoke(l, qs.Length+1, invoker->
      begin
        for var i := 0 to qs.Length-1 do
          //TODO #2610
          evs[i] := invoker.InvokeBranch&<IQueueRes>((g,l)->
            qs[i].InvokeToNil(g, l)
          ).AttachInvokeActions(g);
        var l_res := invoker.InvokeBranch(invoke_last);
        res := l_res;
        evs[qs.Length] := l_res.AttachInvokeActions(g);
      end);
      
      Result := res.MakeWrapWith(EventList.Combine(evs));
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      foreach var q in qs do
        q.ToString(sb, tabs, index, delayed);
      last.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  ISimpleQueueArray = interface
    function GetQS: sequence of CommandQueueBase;
  end;
  ISimpleSyncQueueArray = interface(ISimpleQueueArray) end;
  ISimpleAsyncQueueArray = interface(ISimpleQueueArray) end;
  
  SimpleQueueArrayNil = abstract class(CommandQueueNil, ISimpleQueueArray)
    protected data := new SimpleQueueArrayCommon< CommandQueueNil >;
    
    public constructor(qs: array of CommandQueueBase; last: CommandQueueNil);
    begin
      data.qs := qs;
      data.last := last;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function GetQS: sequence of CommandQueueBase := data.GetQS;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    data.InitBeforeInvoke(g, inited_mu);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  SimpleSyncQueueArrayNil = sealed class(SimpleQueueArrayNil, ISimpleSyncQueueArray)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.InvokeSync(g, l, data.last.InvokeToNil);
    
  end;
  SimpleAsyncQueueArrayNil = sealed class(SimpleQueueArrayNil, ISimpleAsyncQueueArray)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.InvokeAsync(g, l, data.last.InvokeToNil);
    
  end;
  
  SimpleQueueArray<T> = abstract class(CommandQueue<T>, ISimpleQueueArray)
    protected data := new SimpleQueueArrayCommon< CommandQueue<T> >;
    
    public constructor(qs: array of CommandQueueBase; last: CommandQueue<T>);
    begin
      data.qs := qs;
      data.last := last;
      self.const_res_dep      := last.const_res_dep;
      self.expected_const_res := last.expected_const_res;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public function GetQS: sequence of CommandQueueBase := data.GetQS;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    data.InitBeforeInvoke(g, inited_mu);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  SimpleSyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleSyncQueueArray)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := data.InvokeSync(g, l, data.last.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<T>;    override := data.InvokeSync(g, l, data.last.InvokeToAny);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.InvokeSync(g, l, data.last.InvokeToPtr);
    
  end;
  SimpleAsyncQueueArray<T> = sealed class(SimpleQueueArray<T>, ISimpleAsyncQueueArray)
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := data.InvokeAsync(g, l, data.last.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := data.InvokeAsync(g, l, data.last.InvokeToAny);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.InvokeAsync(g, l, data.last.InvokeToPtr);
    
  end;
  
{$region Utils}

type
  CastQueueBase<TRes> = abstract class(CommandQueue<TRes>)
    
    public property SourceBase: CommandQueueBase read; abstract;
    
  end;
  
  QueueArrayFlattener<TArray> = sealed class(ITypedCQUser)
  where TArray: ISimpleQueueArray;
    public qs := new List<CommandQueueBase>;
    private has_next := false;
    private last_added_nil := false;
    
    public procedure ProcessSeq(s: sequence of CommandQueueBase);
    begin
      var enmr := s.GetEnumerator;
      if not enmr.MoveNext then exit;
      
      var upper_had_next := self.has_next;
      while true do
      begin
        var curr := enmr.Current;
        var l_has_next := enmr.MoveNext;
        self.has_next := upper_had_next or l_has_next;
        curr.UseTyped(self);
        if not l_has_next then break;
      end;
      // last val was "upper_had_next or false"
//      self.has_next := upper_had_next;
      
    end;
    
    //TODO mono#11034
    public procedure {ITypedCQUser.}UseNil(cq: CommandQueueNil);
    begin
      if has_next or last_added_nil then
      begin
        if cq is ConstQueueNil then exit;
      end;
      if cq is TArray(var sqa) then
        ProcessSeq(sqa.GetQs) else
      begin
        qs.Add(cq);
        last_added_nil := true;
      end;
    end;
    //TODO mono#11034
    public procedure {ITypedCQUser.}Use<T>(cq: CommandQueue<T>);
    begin
      if has_next then
      begin
        if cq is ConstQueue<T> then exit;
        if cq is ParameterQueue<T> then exit;
        if cq is CastQueueBase<T>(var cqb) then
        begin
          cqb.SourceBase.UseTyped(self);
          exit;
        end;
      end;
      if cq is TArray(var sqa) then
        ProcessSeq(sqa.GetQs) else
      begin
        qs.Add(cq);
        last_added_nil := false;
      end;
    end;
    
  end;
  
  QueueArrayConstructorBase = abstract class
    private body: array of CommandQueueBase;
    
    public constructor(body: array of CommandQueueBase) := self.body := body;
    private constructor := raise new OpenCLABCInternalException;
    
  end;
  
  QueueArraySyncConstructor = sealed class(QueueArrayConstructorBase, ITypedCQConverter<CommandQueueBase>)
    public function ConvertNil(last: CommandQueueNil): CommandQueueBase := new SimpleSyncQueueArrayNil(body, last);
    public function Convert<T>(last: CommandQueue<T>): CommandQueueBase := new SimpleSyncQueueArray<T>(body, last);
  end;
  QueueArrayAsyncConstructor = sealed class(QueueArrayConstructorBase, ITypedCQConverter<CommandQueueBase>)
    public function ConvertNil(last: CommandQueueNil): CommandQueueBase := new SimpleAsyncQueueArrayNil(body, last);
    public function Convert<T>(last: CommandQueue<T>): CommandQueueBase := new SimpleAsyncQueueArray<T>(body, last);
  end;
  
  QueueArrayUtils = static class
    
    private static function FlattenQueueArray<T>(inp: sequence of CommandQueueBase): List<CommandQueueBase>; where T: ISimpleQueueArray;
    begin
      var res := new QueueArrayFlattener<T>;
      res.ProcessSeq(inp);
      Result := res.qs;
    end;
    private static function SeparateLast(qs: List<CommandQueueBase>): ValueTuple<List<CommandQueueBase>,CommandQueueBase>;
    begin
      var last_ind := qs.Count-1;
      var last := qs[last_ind];
      qs.RemoveAt(last_ind);
      Result := ValueTuple.Create(qs,last);
    end;
    
    private static function Construct<T,TQ>(inp: sequence of CommandQueueBase; make_constructor: Func<array of CommandQueueBase, ITypedCQConverter<CommandQueueBase>>): TQ;
    where T: ISimpleQueueArray;
    where TQ: CommandQueueBase;
    begin
      var qs := FlattenQueueArray&<T>(inp);
      case qs.Count of
        0:
        if CQNil is TQ(var res) then
          Result := res else
          raise new System.ArgumentException('%Err:QueueArrayUtils:EmptyNotAllowed%');
        1:
          Result := TQ(qs[0]);
        else
        begin
          var (body, last) := SeparateLast(qs);
          Result := TQ(last.ConvertTyped(make_constructor(body.ToArray)));
        end;
      end;
    end;
    
    public static function ConstructSync<TQ>(inp: sequence of CommandQueueBase): TQ; where TQ: CommandQueueBase;
    begin
      Result := Construct&<ISimpleSyncQueueArray,TQ>(inp, body->new QueueArraySyncConstructor(body));
    end;
    
    public static function ConstructAsync<TQ>(inp: sequence of CommandQueueBase): TQ; where TQ: CommandQueueBase;
    begin
      Result := Construct&<ISimpleAsyncQueueArray,TQ>(inp, body->new QueueArrayAsyncConstructor(body));
    end;
    
  end;
  
{$endregion Utils}

{$region CQ operator's}

function operator+(q1, q2: CommandQueueBase); extensionmethod := QueueArrayUtils.ConstructSync &<CommandQueueBase>(|q1, q2|);
function operator*(q1, q2: CommandQueueBase); extensionmethod := QueueArrayUtils.ConstructAsync&<CommandQueueBase>(|q1, q2|);

function operator+(q1: CommandQueueBase; q2: CommandQueueNil); extensionmethod := QueueArrayUtils.ConstructSync &<CommandQueueNil>(|q1, q2|);
function operator*(q1: CommandQueueBase; q2: CommandQueueNil); extensionmethod := QueueArrayUtils.ConstructAsync&<CommandQueueNil>(|q1, q2|);

function operator+<T>(q1: CommandQueueBase; q2: CommandQueue<T>); extensionmethod := QueueArrayUtils.ConstructSync &<CommandQueue<T>>(|q1, q2|);
function operator*<T>(q1: CommandQueueBase; q2: CommandQueue<T>); extensionmethod := QueueArrayUtils.ConstructAsync&<CommandQueue<T>>(|q1, q2|);



procedure operator+=(var q1: CommandQueueBase; q2: CommandQueueBase); extensionmethod := q1 := q1+q2;
procedure operator*=(var q1: CommandQueueBase; q2: CommandQueueBase); extensionmethod := q1 := q1*q2;

procedure operator+=(var q1: CommandQueueNil; q2: CommandQueueNil); extensionmethod := q1 := q1+q2;
procedure operator*=(var q1: CommandQueueNil; q2: CommandQueueNil); extensionmethod := q1 := q1*q2;

procedure operator+=<T>(var q1: CommandQueue<T>; q2: CommandQueue<T>); extensionmethod := q1 := q1+q2;
procedure operator*=<T>(var q1: CommandQueue<T>; q2: CommandQueue<T>); extensionmethod := q1 := q1*q2;



procedure operator-=(var q1: CommandQueueBase; q2: CommandQueueBase); extensionmethod := q1 := q2+q1;
procedure operator/=(var q1: CommandQueueBase; q2: CommandQueueBase); extensionmethod := q1 := q2*q1;

procedure operator-=(var q1: CommandQueueNil; q2: CommandQueueBase); extensionmethod := q1 := q2+q1;
procedure operator/=(var q1: CommandQueueNil; q2: CommandQueueBase); extensionmethod := q1 := q2*q1;

procedure operator-=<T>(var q1: CommandQueue<T>; q2: CommandQueueBase); extensionmethod := q1 := q2+q1;
procedure operator/=<T>(var q1: CommandQueue<T>; q2: CommandQueueBase); extensionmethod := q1 := q2*q1;

{$endregion CQ operator's}

{$region WaitMarker operator's}

function operator+(m1, m2: WaitMarker); extensionmethod := CommandQueueBase(m1) + m2;
function operator*(m1, m2: WaitMarker); extensionmethod := CommandQueueBase(m1) * m2;

{$endregion WaitMarker operator's}

{$endregion Simple}

{$region [Any]} type
  
  {$region Invokers}
  
  QueueArrayInvokerData<T> = record
    public all_qrs_const := true;
    public next_l: CLTaskLocalData;
    public qrs: array of QueueRes<T>;
    
    public constructor(c: integer) := qrs := new QueueRes<T>[c];
    public constructor := raise new OpenCLABCInternalException;
    
  end;
  IQueueArrayInvoker = interface
    
    function InvokeToNil<T>(qs: array of CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): CLTaskLocalData;
    function InvokeToAny<T>(qs: array of CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueArrayInvokerData<T>;
    
  end;
  
  QueueArraySyncInvoker = record(IQueueArrayInvoker)
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeToNil<T>(qs: array of CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): CLTaskLocalData;
    begin
      for var i := 0 to qs.Length-1 do
        l := qs[i].InvokeToNil(g, l).base;
      Result := l;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeToAny<T>(qs: array of CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueArrayInvokerData<T>;
    begin
      Result := new QueueArrayInvokerData<T>(qs.Length);
      
      for var i := 0 to qs.Length-1 do
      begin
        var qr := qs[i].InvokeToAny(g, l);
        if not qr.IsConst then
          Result.all_qrs_const := false;
        l := qr.TakeBaseOut;
        Result.qrs[i] := qr;
      end;
      
      Result.next_l := l;
    end;
    
  end;
  QueueArrayAsyncInvoker = record(IQueueArrayInvoker)
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeToNil<T>(qs: array of CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): CLTaskLocalData;
    begin
      var evs := new EventList[qs.Length];
      
      g.ParallelInvoke(l, qs.Length, invoker->
        for var i := 0 to qs.Length-1 do
          evs[i] := invoker.InvokeBranch(qs[i].InvokeToNil).AttachInvokeActions(invoker.g)
      );
      
      Result := new CLTaskLocalData(EventList.Combine(evs));
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function MakeInvokeBody<T>(qs: array of CommandQueue<T>; qrs: array of QueueRes<T>): CLTaskBranchInvoker->() := invoker->
    for var i := 0 to qs.Length-1 do qrs[i] := invoker.InvokeBranch(qs[i].InvokeToAny);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeToAny<T>(qs: array of CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueArrayInvokerData<T>;
    begin
      Result := new QueueArrayInvokerData<T>(qs.Length);
      
      g.ParallelInvoke(l, qs.Length, MakeInvokeBody(qs,Result.qrs));
      
      for var i := 0 to qs.Length-1 do
        if not Result.qrs[i].IsConst then
          Result.all_qrs_const := false;
      
      var evs := new EventList[qs.Length];
      for var i := 0 to qs.Length-1 do
        evs[i] := Result.qrs[i].AttachInvokeActions(g);
      Result.next_l := new CLTaskLocalData(EventList.Combine(evs));
    end;
    
  end;
  
  {$endregion Invokers}
  
  {$region Work}
  
  IQueueArrayWork<TInp,TRes, TDelegate> = interface
  where TDelegate: ISimpleDelegateContainer;
    
    function Invoke(d: TDelegate; err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}; inp: array of TInp; c: CLContext): TRes;
    
  end;
  
  QueueArrayWorkConvert<TInp,TRes, TFunc> = record(IQueueArrayWork<TInp,TRes, TFunc>)
  where TFunc: ISimpleFuncContainer<array of TInp,TRes>;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke(f: TFunc; err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}; inp: array of TInp; c: CLContext) :=
    f.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, inp, c);
    
  end;
  
  QueueArrayWorkUse<T, TProc> = record(IQueueArrayWork<T,array of T, TProc>)
  where TProc: ISimpleProcContainer<array of T>;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke(p: TProc; err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}; inp: array of T; c: CLContext): array of T; 
    begin
      p.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, inp, c);
      Result := inp;
    end;
    
  end;
  
  {$endregion Work}
  
  {$region Common}
  
  CommandQueueArrayWithWork<TInp,TRes, TInv,TDelegate> = abstract class(CommandQueue<TRes>)
  where TInv: IQueueArrayInvoker, constructor;
  where TDelegate: ISimpleDelegateContainer;
    protected qs: array of CommandQueue<TInp>;
    protected d: TDelegate;
    protected can_pre_call: boolean;
    
    public constructor(qs: array of CommandQueue<TInp>; d: TDelegate; can_pre_call: boolean);
    begin
      self.qs := qs;
      self.d := d;
      self.can_pre_call := can_pre_call;
      if can_pre_call and qs.All(q->q.const_res_dep<>nil) then
      begin
        self.expected_const_res := d.PreInvoke&<array of TInp, TRes>(
          qs.ConvertAll(q->q.expected_const_res)
        );
        
        var c := qs.Sum(q->q.const_res_dep.Length);
        {$ifdef DEBUG}
        if c=0 then raise new OpenCLABCInternalException($'0dep version is CQ/HFQ/HPQ');
        {$endif DEBUG}
        
        self.const_res_dep := new CommandQueueBase[c];
        for var i := qs.Length-1 downto 0 do
        begin
          var dep := qs[i].const_res_dep;
          c -= dep.Length;
          dep.CopyTo(self.const_res_dep, c);
        end;
        
      end;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    foreach var q in qs do q.InitBeforeInvoke(g, inited_mu);
    
    protected function TrySkipInvoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>; var res: TR): boolean; where TR: IQueueRes;
    begin
      Result := qr_factory.TrySkipInvoke(
        g, l,
        self,(g,l)->new QueueResNil(TInv.Create.InvokeToNil(self.qs, g,l)),
        res
      );
    end;
    
    protected static function GetAllResDirect(qrs: array of QueueRes<TInp>): array of TInp;
    begin
      Result := new TInp[qrs.Length];
      for var i := 0 to Result.Length-1 do
        Result[i] := qrs[i].GetResDirect;
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      foreach var q in qs do
        q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      d.ToStringB(sb);
      sb += #10;
      
    end;
    
  end;
  
  {$endregion Common}
  
  {$region Quick}
  
  CommandQueueQuickArray<TInp,TRes, TInv, TDelegate, TWork> = sealed class(CommandQueueArrayWithWork<TInp,TRes, TInv,TDelegate>)
  where TInv: IQueueArrayInvoker, constructor;
  where TDelegate: ISimpleDelegateContainer;
  where TWork: IQueueArrayWork<TInp,TRes, TDelegate>, constructor;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: IQueueRes;
    begin
      if TrySkipInvoke(g,l, qr_factory, Result) then exit;
      var inv_data := TInv.Create.InvokeToAny(self.qs, g, l);
      l := inv_data.next_l;
      
      var should_make_const := if can_pre_call then
        inv_data.all_qrs_const else
        l.ShouldInstaCallAction;
      
      var qrs := inv_data.qrs;
      var err_handler := g.curr_err_handler;
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.d.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      if should_make_const then
        Result := qr_factory.MakeConst(l, TWork.Create.Invoke(d,
          err_handler{$ifdef DEBUG}, err_test_reason{$endif}, GetAllResDirect(qrs), g.c
        )) else
        Result := qr_factory.MakeDelayed(l, qr->c->qr.SetRes(TWork.Create.Invoke(d,
          err_handler{$ifdef DEBUG}, err_test_reason{$endif}, GetAllResDirect(qrs), c
        )));
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
  CommandQueueConvertQuickArray<TInp,TRes, TInv, TFunc> = CommandQueueQuickArray<TInp,TRes,    TInv, TFunc, QueueArrayWorkConvert<TInp,TRes, TFunc>>;
  CommandQueueUseQuickArray    <T,         TInv, TProc> = CommandQueueQuickArray<T,array of T, TInv, TProc, QueueArrayWorkUse    <T,         TProc>>;
  
  {$endregion Quick}
  
  {$region Threaded}
  
  //TODO #2657
  QueueResArr<T> = array of QueueRes<T>;
  
  CommandQueueThreadedArray<TInp,TRes, TInv, TDelegate, TWork> = sealed class(CommandQueueArrayWithWork<TInp,TRes, TInv,TDelegate>)
  where TInv: IQueueArrayInvoker, constructor;
  where TDelegate: ISimpleDelegateContainer;
  where TWork: IQueueArrayWork<TInp,TRes, TDelegate>, constructor;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function MakeNilBody    (acts: QueueResComplDelegateData; qrs: array of QueueRes<TInp>; err_handler: CLTaskErrHandler; c: CLContext; own_qr: QueueResNil{$ifdef DEBUG}; err_test_reason: string{$endif}): Action;
    begin
      Result := ()->
      begin
        acts.Invoke(c);
        TWork.Create.Invoke(d, err_handler{$ifdef DEBUG}, err_test_reason{$endif}, GetAllResDirect(qrs), c)
      end;
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function MakeResBody<TR>(acts: QueueResComplDelegateData; qrs: array of QueueRes<TInp>; err_handler: CLTaskErrHandler; c: CLContext; own_qr: TR{$ifdef DEBUG}; err_test_reason: string{$endif}): Action; where TR: QueueRes<TRes>;
    begin
      Result := ()->
      begin
        acts.Invoke(c);
        own_qr.SetRes(
          TWork.Create.Invoke(d, err_handler{$ifdef DEBUG}, err_test_reason{$endif}, GetAllResDirect(qrs), c)
        );
      end;
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>;
      make_body: (QueueResComplDelegateData, QueueResArr<TInp>,CLTaskErrHandler,CLContext,TR{$ifdef DEBUG},string{$endif})->Action
    ): TR; where TR: IQueueRes;
    begin
      if TrySkipInvoke(g,l, qr_factory, Result) then exit;
      var inv_data := TInv.Create.InvokeToAny(self.qs, g, l);
      l := inv_data.next_l;
      
      var qrs := inv_data.qrs;
      var err_handler := g.curr_err_handler;
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.d.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      if can_pre_call and inv_data.all_qrs_const then
        Result := qr_factory.MakeConst(l, TWork.Create.Invoke(d,
          err_handler{$ifdef DEBUG}, err_test_reason{$endif}, GetAllResDirect(qrs), g.c)
        ) else
      begin
        var prev_ev := l.prev_ev;
        var acts := l.prev_delegate;
        Result := qr_factory.MakeDelayed(qr->new CLTaskLocalData(UserEvent.StartWorkThread(
          prev_ev, make_body(acts, qrs, err_handler, g.c, qr{$ifdef DEBUG}, err_test_reason{$endif}), g
          {$ifdef EventDebug}, $'body of {TypeName(self)}'{$endif}
        )));
      end;
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory, MakeNilBody);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <TRes>; override := Invoke(g, l, qr_val_factory, MakeResBody&<QueueResVal<TRes>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory, MakeResBody&<QueueResPtr<TRes>>);
    
  end;
  
  CommandQueueConvertThreadedArray<TInp,TRes, TInv, TFunc> = CommandQueueThreadedArray<TInp,TRes,    TInv, TFunc, QueueArrayWorkConvert<TInp,TRes, TFunc>>;
  CommandQueueUseThreadedArray    <T,         TInv, TProc> = CommandQueueThreadedArray<T,array of T, TInv, TProc, QueueArrayWorkUse    <T,         TProc>>;
  
  {$endregion Threaded}
  
{$endregion [Any]}

{%QueueArray\AllStaticArrays!QueueStaticArrayWithWork.pas%}

{$endregion +/*}

{$region Cast}

type
  TypedNilQueue<T> = sealed class(CommandQueue<T>)
    private static nil_val := default(T);
    private q: CommandQueueNil;
    
    static constructor;
    begin
      if object(nil_val)<>nil then
        raise new System.InvalidCastException($'%Err:Cast:nil->T%');
    end;
    public constructor(q: CommandQueueNil) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := q.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<T>; override := qr_val_factory.MakeConst(q.InvokeToNil(g, l).base, nil_val);
    
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override;
    begin
      Result := nil;
      raise new OpenCLABCInternalException($'%Err:Invoke:InvalidToPtr%');
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CastQueue<TInp, TRes> = sealed class(CastQueueBase<TRes>)
    private q: CommandQueue<TInp>;
    
    static constructor;
    begin
      if typeof(TInp)=typeof(object) then exit;
      try
        var res := TRes(object(default(TInp)));
        System.GC.KeepAlive(res);
      except
        raise new System.InvalidCastException($'%Err:Cast:TInp->TRes%');
      end;
    end;
    public constructor(q: CommandQueue<TInp>);
    begin
      self.q := q;
      if q.const_res_dep<>nil then
      begin
        self.expected_const_res := TRes(q.expected_const_res as object);
        self.const_res_dep := q.const_res_dep;
      end;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public property SourceBase: CommandQueueBase read q as CommandQueueBase; override;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    q.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: QueueRes<TRes>;
    begin
      if qr_factory.TrySkipInvoke(g,l, self,q.InvokeToNil, Result) then exit;
      var prev_qr := q.InvokeToAny(g,l);
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      Result := prev_qr.TransformResult(qr_factory, true, o->
      begin
        if not err_handler.HadError then
        try
          Result := TRes(o as object);
        except
          on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif});
        end;
        {$ifdef DEBUG}
        err_handler.EndMaybeError(err_test_reason);
        {$endif DEBUG}
      end);
    end;
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CastQueueConstructor<TRes> = record(ITypedCQConverter<CommandQueue<TRes>>)
    
    public function ConvertNil(q: CommandQueueNil): CommandQueue<TRes> :=
    if q is ConstQueueNil then
      CQ(TypedNilQueue&<TRes>.nil_val) else
      new TypedNilQueue<TRes>(q);
    
    public function Convert<TInp>(q: CommandQueue<TInp>): CommandQueue<TRes> :=
    if q is CastQueueBase<TInp>(var cqb) then
      cqb.SourceBase.Cast&<TRes> else
    if q.IsConstResDepEmpty then
      q + CQ(TRes(q.expected_const_res as object)) else
      new CastQueue<TInp, TRes>(q);
    
  end;
  
function CommandQueueBase.Cast<T>: CommandQueue<T>;
begin
  if self is CommandQueue<T>(var tcq) then
    Result := tcq else
  try
    Result := self.ConvertTyped(new CastQueueConstructor<T>);
  except
    on e: TypeInitializationException do
      raise e.InnerException;
    on e: InvalidCastException do
      raise e;
  end;
end;

function CommandQueueNil.Cast<T> := new TypedNilQueue<T>(self);

{$endregion Cast}

{$region DiscardResult}

type
  CommandQueueDiscardResult<T> = sealed class(CommandQueueNil)
    private q: CommandQueue<T>;
    
    public constructor(q: CommandQueue<T>) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    q.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function CommandQueue<T>.DiscardResult :=
if (self is ConstQueue<T>) or (self is ParameterQueue<T>) then
  CQNil else new CommandQueueDiscardResult<T>(self);

{$endregion DiscardResult}

{$region Then[Convert,Use]}

{$region Common}

type
  CommandQueueThenWork<TInp,TRes, TDelegate> = abstract class(CommandQueue<TRes>)
  where TDelegate: ISimpleDelegateContainer;
    protected q: CommandQueue<TInp>;
    protected d: TDelegate;
    protected can_pre_call: boolean;
    
    public constructor(q: CommandQueue<TInp>; d: TDelegate; can_pre_call: boolean);
    begin
      self.q := q;
      self.d := d;
      self.can_pre_call := can_pre_call;
      if can_pre_call and (q.const_res_dep<>nil) then
      begin
        {$ifdef DEBUG}
        if q.IsConstResDepEmpty then
          raise new OpenCLABCInternalException($'0dep version is CQ/HFQ');
        {$endif DEBUG}
        self.expected_const_res := d.PreInvoke&<TInp,TRes>(q.expected_const_res);
        self.const_res_dep := q.const_res_dep;
      end;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := q.InitBeforeInvoke(g, inited_mu);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      d.ToStringB(sb);
      sb += #10;
      
    end;
    
  end;
  CommandQueueThenConvert<TInp,TRes, TFunc> = CommandQueueThenWork<TInp,TRes, TFunc>;
  CommandQueueThenUse<T, TProc> = CommandQueueThenWork<T,T, TProc>;
  
{$endregion Common}

{$region Convert}

type
  CommandQueueThenQuickConvert<TInp, TRes, TFunc> = sealed class(CommandQueueThenConvert<TInp,TRes, TFunc>)
  where TFunc: ISimpleFuncContainer<TInp, TRes>;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: IQueueRes;
    begin
      if qr_factory.TrySkipInvoke(g,l, self,q.InvokeToNil, Result) then exit;
      var prev_qr := q.InvokeToAny(g, l);
      
      var should_make_const := if can_pre_call then
        prev_qr.IsConst else
        prev_qr.ShouldInstaCallAction;
      l := prev_qr.TakeBaseOut;
      
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.d.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      Result := if should_make_const then
        qr_factory.MakeConst(l,
          d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetResDirect, g.c)
        ) else
        qr_factory.MakeDelayed(l, qr->c->qr.SetRes(
          d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetResDirect, c)
        ));
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
  CommandQueueThenThreadedConvert<TInp,TRes, TFunc> = sealed class(CommandQueueThenConvert<TInp,TRes, TFunc>)
  where TFunc: ISimpleFuncContainer<TInp,TRes>;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function MakeNilBody    (prev_qr: QueueRes<TInp>; err_handler: CLTaskErrHandler; c: CLContext; own_qr: QueueResNil{$ifdef DEBUG}; err_test_reason: string{$endif}): Action;
    begin
      Result := ()->
        d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetRes(c), c)
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function MakeResBody<TR>(prev_qr: QueueRes<TInp>; err_handler: CLTaskErrHandler; c: CLContext; own_qr: TR{$ifdef DEBUG}; err_test_reason: string{$endif}): Action; where TR: QueueRes<TRes>;
    begin
      Result := ()->own_qr.SetRes(
        d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetRes(c), c)
      );
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>; make_body: (QueueRes<TInp>,CLTaskErrHandler,CLContext,TR{$ifdef DEBUG},string{$endif})->Action): TR; where TR: IQueueRes;
    begin
      if qr_factory.TrySkipInvoke(g,l, self,q.InvokeToNil, Result) then exit;
      var prev_qr := q.InvokeToAny(g, l);
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.d.Invoke';
      g.curr_err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      Result := if can_pre_call and prev_qr.IsConst then
        qr_factory.MakeConst(l,
          d.Invoke(g.curr_err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetResDirect, nil)
        ) else
        qr_factory.MakeDelayed(qr->new CLTaskLocalData(UserEvent.StartWorkThread(
          prev_qr.ResEv, make_body(prev_qr, g.curr_err_handler, g.c, qr{$ifdef DEBUG}, err_test_reason{$endif}), g
          {$ifdef EventDebug}, $'body of {TypeName(self)}'{$endif}
        )));
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;       override := Invoke(g, l, qr_nil_factory, MakeNilBody);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <TRes>; override := Invoke(g, l, qr_val_factory, MakeResBody&<QueueResVal<TRes>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory, MakeResBody&<QueueResPtr<TRes>>);
    
  end;
  
function CommandQueue<T>.ThenConvert<TOtp>(f: T->TOtp; need_own_thread, can_pre_calc: boolean): CommandQueue<TOtp>;
begin
  if self.IsConstResDepEmpty then
  begin
    var inp := self.expected_const_res;
    Result := self + if can_pre_calc then
      CQ(f(inp)) else
      HFQ(()->f(inp), need_own_thread);
  end else
  if need_own_thread then
    Result := new CommandQueueThenThreadedConvert <T, TOtp, SimpleFuncContainer<T,TOtp>>(self, f, can_pre_calc) else
    Result := new CommandQueueThenQuickConvert    <T, TOtp, SimpleFuncContainer<T,TOtp>>(self, f, can_pre_calc);
end;

function CommandQueue<T>.ThenConvert<TOtp>(f: (T,CLContext)->TOtp; need_own_thread, can_pre_calc: boolean): CommandQueue<TOtp>;
begin
  if self.IsConstResDepEmpty then
  begin
    var inp := self.expected_const_res;
    Result := self + if can_pre_calc then
      CQ(f(inp,nil)) else
      HFQ(c->f(inp,c), need_own_thread);
  end else
  if need_own_thread then
    Result := new CommandQueueThenThreadedConvert <T, TOtp, SimpleFuncContainerC<T,TOtp>>(self, f, can_pre_calc) else
    Result := new CommandQueueThenQuickConvert    <T, TOtp, SimpleFuncContainerC<T,TOtp>>(self, f, can_pre_calc);
end;

{$endregion Convert}

{$region Use}

type
  CommandQueueThenQuickUse<T, TProc> = sealed class(CommandQueueThenUse<T, TProc>)
  where TProc: ISimpleProcContainer<T>;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AddUse<TR1, TR2>(prev_is_const: boolean; prev_qr: TR1; own_qr: TR2; g: CLTaskGlobalData): TR2; where TR1: QueueRes<T>; where TR2: IQueueRes;
    begin
      Result := own_qr;
      
      // .IsConst debug tests executed before this
      // So if prev_is_const then also Result.ShouldInstaCallAction
      var should_insta_call := if can_pre_call then
        prev_is_const else
        Result.ShouldInstaCallAction;
      
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.d.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      if should_insta_call then
        d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetResDirect, g.c) else
        //TODO #????: self.
        Result.AddAction(c->self.d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetResDirect, c));
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      if g.CheckDeps(self.const_res_dep) then
        Result := q.InvokeToNil(g, l) else
      begin
        var prev_qr := q.InvokeToAny(g, l);
        Result := AddUse(prev_qr.IsConst, prev_qr, new QueueResNil(prev_qr.TakeBaseOut), g);
      end;
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AddUse<TR>(qr: TR; g: CLTaskGlobalData): TR; where TR: QueueRes<T>;
    begin
      Result := qr;
      //TODO Единственный способ не вызывать эту же проверку из q.InvokeToAny(g, l)
      // - Передавать данные о том, что все зависимости сработали
      // - Или self=>q, или q=>self
      // - Первый способ должен быть капельку быстрее для Combine очередей,
      //   если один параметр используется в нескольких ветках
      // - А второй поидее проще реализовать, потому что данные будут в qr
      // - Подумать, может ли константность qr сразу говорить и о CheckDeps
      if g.CheckDeps(self.const_res_dep) then exit;
      Result := AddUse(qr.IsConst, qr,qr, g);
    end;
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := AddUse(q.InvokeToAny(g, l), g);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := AddUse(q.InvokeToPtr(g, l), g);
    
  end;
  
  CommandQueueThenThreadedUse<T, TProc> = sealed class(CommandQueueThenUse<T, TProc>)
  where TProc: ISimpleProcContainer<T>;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR1,TR2>(g: CLTaskGlobalData; l: CLTaskLocalData; q_invoker: CommandQueueInvoker<TR1>; qr_factory: IQueueResFactory<T,TR2>): TR2; where TR1: QueueRes<T>; where TR2: IQueueRes;
    begin
      if qr_factory.TrySkipInvoke(g,l, self,q.InvokeToNil, Result) then exit;
      
      var prev_qr := q_invoker(g, l);
      if can_pre_call and prev_qr.IsConst then
      begin
        //TODO И тут тоже (как и ниже) лишний объект во всех случаях кроме TR2=QueueResNil
        Result := qr_factory.MakeConst(prev_qr.TakeBaseOut, prev_qr.GetResDirect);
        exit;
      end;
      
      var acts := prev_qr.base.complition_delegate.TakeOut;
      
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.d.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      var c := g.c;
      var work_ev := UserEvent.StartWorkThread(
        prev_qr.ResEv, ()->
        begin
          acts.Invoke(c);
          //TODO #????: self.
          self.d.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif}, prev_qr.GetResDirect, c);
        end, g
        {$ifdef EventDebug}, $'body of {TypeName(self)}'{$endif}
      );
      
      //TODO На самом деле создавать новый объект, даже если обёртку - ни к чему
      // - Новый объект нужен только при .MakeWrap mu результата
      // - А тут должно быть достаточно подменить ивент
      // --- status check ожидает что ивент не будет меняться
      // - Но InvokeToNil создаёт "new QueueResNil(work_ev)"
      // --- InvokeToAny и InvokeToPtr копируют тип prev_qr
      // - Это касается только .Then и только Use, потому что в остальных случаях нельзя использовать существующий QR
      Result := qr_factory.MakeWrap(prev_qr, work_ev);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := Invoke(g, l, q.InvokeToAny, qr_nil_factory);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, q.InvokeToAny, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, q.InvokeToPtr, qr_ptr_factory);
    
  end;
  
function CommandQueue<T>.ThenUse(p: T->(); need_own_thread, can_pre_calc: boolean): CommandQueue<T>;
begin
  if self.IsConstResDepEmpty then
  begin
    var inp := self.expected_const_res;
    Result := self;
    if can_pre_calc then
      p(inp) else
      Result += HPQ(()->p(inp), need_own_thread) + CQ(inp);
  end else
  if need_own_thread then
    Result := new CommandQueueThenThreadedUse <T, SimpleProcContainer<T>>(self, p, can_pre_calc) else
    Result := new CommandQueueThenQuickUse    <T, SimpleProcContainer<T>>(self, p, can_pre_calc);
end;

function CommandQueue<T>.ThenUse(p: (T,CLContext)->(); need_own_thread, can_pre_calc: boolean): CommandQueue<T>;
begin
  if self.IsConstResDepEmpty then
  begin
    var inp := self.expected_const_res;
    Result := self;
    if can_pre_calc then
      p(inp,nil) else
      Result += HPQ(c->p(inp,c), need_own_thread) + CQ(inp);
  end else
  if need_own_thread then
    Result := new CommandQueueThenThreadedUse <T, SimpleProcContainerC<T>>(self, p, can_pre_calc) else
    Result := new CommandQueueThenQuickUse    <T, SimpleProcContainerC<T>>(self, p, can_pre_calc);
end;

{$endregion Use}

{$endregion Then[Convert,Use}

{$region Multiusable}

type
  MultiusableCommandQueueCommon = static class
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static procedure InitBeforeInvoke(self: IMultiusableCommandQueue; q: CommandQueueBase; g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>) :=
    if inited_mu.Add(self) then q.InitBeforeInvoke(g, inited_mu);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function Invoke<TR1, TR2>(
      self: IMultiusableCommandQueue;
      g: CLTaskGlobalData; l: CLTaskLocalData;
      invoke_q: CommandQueueInvoker<TR1>;
      make_wrap: (TR1, EventList)->TR2
    ): TR2; where TR1,TR2: IQueueRes;
    begin
      var res_data: MultiuseableResultData;
      var qr: TR1;
      
      // Потоко-безопасно, потому что все .Invoke выполняются синхронно
      //TODO А что будет когда .ThenIf и т.п.?
      if g.mu_res.TryGetValue(self, res_data) then
        qr := TR1(res_data.qres) else
      begin
        var prev_err_handler := g.curr_err_handler;
        g.curr_err_handler := new CLTaskErrHandlerEmpty;
        
        qr := invoke_q(g, new CLTaskLocalData);
        var ev := qr.AttachInvokeActions(g);
        
        res_data := new MultiuseableResultData(qr, ev, g.curr_err_handler);
        g.mu_res[self] := res_data;
        
        g.curr_err_handler := prev_err_handler;
      end;
      g.curr_err_handler := new CLTaskErrHandlerThiefRepeater(g.curr_err_handler, res_data.err_handler);
      
      if g.prev_mu.Add(self) then
      begin
        // "all", except Q+Q, because q's in g.prev_mu are already waited upon
        res_data.ev.Retain({$ifdef EventDebug}$'for all mu branches'{$endif});
        Result := make_wrap(qr, res_data.ev + l.AttachInvokeActions(g));
      end else
      begin
        Result := make_wrap(qr, l.prev_ev);
        Result.AddActions(l.prev_delegate);
      end;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function InvokeToNil<TR>(self: IMultiusableCommandQueue; g: CLTaskGlobalData; l: CLTaskLocalData; invoke_q: CommandQueueInvoker<TR>): QueueResNil; where TR: IQueueRes;
    begin
      Result := Invoke(self, g,l, invoke_q, (qr, ev)->new QueueResNil(ev));
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static procedure ToString(q: CommandQueueBase; sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += ' => ';
      if q.ToStringHeader(sb, index) then
        delayed.Add(q);
      sb += #10;
    end;
    
  end;
  
  MultiusableCommandQueueNil = sealed class(CommandQueueNil, IMultiusableCommandQueue)
    public q: CommandQueueNil;
    
    public constructor(q: CommandQueueNil) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    MultiusableCommandQueueCommon.InitBeforeInvoke(self,q, g,inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    MultiusableCommandQueueCommon.InvokeToNil(self, g,l, q.InvokeToNil);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    MultiusableCommandQueueCommon.ToString(q, sb,tabs,index,delayed);
    
  end;
  
  MultiusableCommandQueue<T> = sealed class(CommandQueue<T>, IMultiusableCommandQueue)
    public q: CommandQueue<T>;
    
    public constructor(q: CommandQueue<T>);
    begin
      inherited Create(q.expected_const_res, q.const_res_dep);
      self.q := q;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    MultiusableCommandQueueCommon.InitBeforeInvoke(self,q, g,inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override :=
    MultiusableCommandQueueCommon.InvokeToNil(self, g,l, q.InvokeToAny);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      Result := MultiusableCommandQueueCommon
        .Invoke(self, g,l, q.InvokeToAny, qr_factory.MakeWrap);
    end;
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    MultiusableCommandQueueCommon.ToString(q, sb,tabs,index,delayed);
    
  end;
  
function CommandQueueNil.Multiusable :=
if (self is MultiusableCommandQueueNil) or (self is ConstQueueNil) then
  self else new MultiusableCommandQueueNil(self);

function CommandQueue<T>.Multiusable :=
// No const_res_dep checks, because (HPQ+CQ).MU should execute HPQ once
if (self is MultiusableCommandQueue<T>) or (self is ConstQueue<T>) or (self is ParameterQueue<T>) then
  self else new MultiusableCommandQueue<T>(self);

{$endregion Multiusable}

{$region Wait}

{$region Def}
//TODO Куча дублей кода, особенно в Combination
//TODO data ничего не делает, кроме как для WaitDebug, потому что state хранится в sub_info
// - Лучше передавать self.GetHashCode
//TODO Отписка никогда не происходит - пока не сделал, чтоб перепродумывать как обрабатывать всё при циклах

{$region Base}

type
  WaitMarker = abstract partial class
    
    public procedure InitInnerHandles(g: CLTaskGlobalData); abstract;
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; abstract;
    public function MakeWaitEv(g: CLTaskGlobalData; l: CLTaskLocalData) := MakeWaitEv(g, l.AttachInvokeActions(g));
    
  end;
  
{$endregion Base}

{$region Outer}

type
  /// wait_handler, который можно встроить в очередь как есть
  WaitHandlerOuter = abstract class
    public uev: UserEvent;
    private state := 0;
    private gc_hnd: GCHandle;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList);
    begin
      
      uev := new UserEvent(g.cl_c{$ifdef EventDebug}, $'Wait result'{$endif});
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Created outer with prev_ev=[ {prev_ev.evs?.JoinToString} ], res_ev={uev}');
      {$endif WaitDebug}
      self.gc_hnd := GCHandle.Alloc(self);
      
      // Code of .ThenFinallyWaitFor expects
      // g.curr_err_handler to not change
      // and no new errors to be added
      var err_handler := g.curr_err_handler;
      prev_ev.MultiAttachCallback(()->
      begin
        if err_handler.HadError then
        begin
          {$ifdef WaitDebug}
          WaitDebug.RegisterAction(self, $'Aborted');
          {$endif WaitDebug}
          uev.SetComplete(true);
          self.gc_hnd.Free;
        end else
        begin
          {$ifdef WaitDebug}
          WaitDebug.RegisterAction(self, $'Got prev_ev boost');
          {$endif WaitDebug}
          self.IncState;
        end;
      end{$ifdef EventDebug}, $'prev_ev boost for wait handler[{self.GetHashCode}]'{$endif});
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function TryConsume: boolean; abstract;
    
    protected function IncState: boolean;
    begin
      var new_state := Interlocked.Increment(self.state);
      
      {$ifdef DEBUG}
      if not new_state.InRange(1,2) then raise new OpenCLABCInternalException($'WaitHandlerOuter.state={new_state}');
      {$endif DEBUG}
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Advanced to state {new_state}');
      {$endif WaitDebug}
      
      Result := (new_state=2) and TryConsume;
      if Result then self.gc_hnd.Free;
    end;
    protected procedure DecState;
    begin
      {$ifdef DEBUG}
      var new_state :=
      {$endif DEBUG}
      Interlocked.Decrement(self.state);
      
      {$ifdef DEBUG}
      if not new_state.InRange(0,1) then
        raise new OpenCLABCInternalException($'WaitHandlerOuter.state={new_state}');
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Gone back to state {new_state}');
      {$endif WaitDebug}
      
      {$endif DEBUG}
      
    end;
    
  end;
  
{$endregion Outer}

{$region Direct}

type
  IWaitHandlerSub = interface
    
    // Возвращает true, если активацию успешно съели
    function HandleChildInc(data: integer): boolean;
    procedure HandleChildDec(data: integer);
    
  end;
  
  WaitHandlerDirectSubInfo = class
    public threshold, data: integer;
    public state := new InterlockedBoolean;
    public constructor(threshold, data: integer);
    begin
      self.threshold := threshold;
      self.data := data;
    end;
    public constructor := raise new OpenCLABCInternalException;
  end;
  /// Напрямую хранит активации конкретного CLTaskGlobalData
  WaitHandlerDirect = sealed class
    private subs := new ConcurrentDictionary<IWaitHandlerSub, WaitHandlerDirectSubInfo>;
    private activations := 0;
    private reserved := 0;
    
    public procedure Subscribe(sub: IWaitHandlerSub; info: WaitHandlerDirectSubInfo);
    begin
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got new sub {sub.GetHashCode}');
      {$endif WaitDebug}
      
      if not subs.TryAdd(sub, info) then
      begin
        {$ifdef DEBUG}
        raise new OpenCLABCInternalException($'Sub added twice');
        {$endif DEBUG}
      end else
      if activations>=info.threshold then
        if info.state.TrySet(true) then
        begin
          {$ifdef WaitDebug}
          WaitDebug.RegisterAction(self, $'Add immidiatly inced sub {sub.GetHashCode}');
          {$endif WaitDebug}
          // Может выполняться одновременно с AddActivation, в таком случае 
          sub.HandleChildInc(info.data);
        end;
    end;
    
    public procedure AddActivation;
    begin
      {$ifdef WaitDebug}
      var new_act :=
      {$endif WaitDebug}
      Interlocked.Increment(activations);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation =>{new_act}');
      {$endif WaitDebug}
      
      foreach var kvp in subs do
        // activations может изменится, если .HandleChildInc из
        // .AddActivation другого хэндлера или .Subscribe затронет self.activations
        // Поэтому результат Interlocked.Increment использовать нельзя
        if activations>=kvp.Value.threshold then
          if kvp.Value.state.TrySet(true) and kvp.Key.HandleChildInc(kvp.Value.data) then
          begin
            {$ifdef WaitDebug}
            WaitDebug.RegisterAction(self, $'Sub {kvp.Key.GetHashCode} consumed activation =>{activations}');
            {$endif WaitDebug}
            // Если активацию съели - нет смысла продолжать
            break;
          end;
    end;
    
    public function TryReserve(c: integer): boolean;
    begin
      var n_reserved := Interlocked.Add(reserved, c);
      Result := n_reserved<=activations;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Tried to reserve {c}=>{n_reserved}: {Result}');
      {$endif WaitDebug}
      
      // Надо делать там, где было вызвано TryReserve
      // Потому что TryReserve не последняя проверка, есть ещё uev.SetComplete
//      if not Result then ReleaseReserve(c);
    end;
    public procedure ReleaseReserve(c: integer) :=
    if Interlocked.Add(reserved, -c)<0 then
    begin
      {$ifdef DEBUG}
      raise new OpenCLABCInternalException($'reserved={reserved}');
      {$endif DEBUG}
    end else
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Released reserve {c}=>{reserved}');
      {$endif WaitDebug}
    end;
    
    public procedure Comsume(c: integer);
    begin
      var new_act := Interlocked.Add(activations, -c);
      var new_res := Interlocked.Add(reserved, -c);
      {$ifdef DEBUG}
      if (new_act<0) or (new_res<0) then
        raise new OpenCLABCInternalException($'new_act={new_act}, new_res={new_res}');
      {$endif DEBUG}
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Sub consumed {c}, new_act={new_act}, new_res={new_res}');
      {$endif WaitDebug}
      
      foreach var kvp in subs do
        if activations<kvp.Value.threshold then
          if kvp.Value.state.TrySet(false) then
            kvp.Key.HandleChildDec(kvp.Value.data);
    end;
    
  end;
  /// Обёртка WaitHandlerDirect, которая является WaitHandlerOuter
  WaitHandlerDirectWrap = sealed class(WaitHandlerOuter, IWaitHandlerSub)
    private source: WaitHandlerDirect;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList; source: WaitHandlerDirect);
    begin
      inherited Create(g, prev_ev);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'This is DirectWrap for {source.GetHashCode}');
      {$endif WaitDebug}
      self.source := source;
      source.Subscribe(self, new WaitHandlerDirectSubInfo(1,0));
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    //TODO mono#11034
    public function {IWaitHandlerSub.}HandleChildInc(data: integer) := self.IncState;
    public procedure {IWaitHandlerSub.}HandleChildDec(data: integer) := self.DecState;
    
    protected function TryConsume: boolean; override;
    begin
      Result := source.TryReserve(1) and self.uev.SetComplete(false);
      if not Result then source.ReleaseReserve(1);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Tried reserving {1} in source[{source.GetHashCode}]: {Result}');
      {$endif WaitDebug}
      
      if Result then source.Comsume(1);
    end;
    
  end;
  
  /// Маркер, не ссылающийся на другие маркеры
  WaitMarkerDirect = abstract class(WaitMarker)
    private handlers := new ConcurrentDictionary<CLTaskGlobalData, WaitHandlerDirect>;
    
    public procedure InitInnerHandles(g: CLTaskGlobalData); override :=
    handlers.GetOrAdd(g, g->
    begin
      Result := new WaitHandlerDirect;
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(Result, $'Created for {TypeName(self)}[{self.GetHashCode}]');
      {$endif WaitDebug}
    end);
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; override :=
    WaitHandlerDirectWrap.Create(g, prev_ev, handlers[g]).uev;
    
    public procedure SendSignal; override :=
    foreach var h in handlers.Values do
      h.AddActivation;
    
  end;
  
{$endregion Direct}

{$region Combination}

{$region Base}

type
  WaitMarkerCombination<TChild> = abstract class(WaitMarker)
  where TChild: WaitMarker;
    private children: array of TChild;
    
    public constructor(children: array of TChild) := self.children := children;
    public constructor := raise new OpenCLABCInternalException;
    
    public procedure InitInnerHandles(g: CLTaskGlobalData); override :=
    foreach var child in children do child.InitInnerHandles(g);
    
    {$region Disabled override's}
    
    private function ConvertToQBase: CommandQueueBase; override;
    begin
      Result := nil;
      raise new System.InvalidProgramException($'%Err:WaitMarkerCombination.ConvertToQBase%');
    end;
    
    public procedure SendSignal; override :=
    raise new System.InvalidProgramException($'%Err:WaitMarkerCombination.SendSignal%');
    
    {$endregion Disabled override's}
    
  end;
  
{$endregion Base}

{$region All}

type
  WaitHandlerAllInner<TSub> = sealed class(IWaitHandlerSub)
  where TSub: IWaitHandlerSub;
    private sources: array of WaitHandlerDirect;
    private ref_counts: array of integer;
    private done_c := 0;
    
    private sub: TSub;
    private sub_data: integer;
    
    public constructor(sources: array of WaitHandlerDirect; ref_counts: array of integer; sub: TSub; sub_data: integer);
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Created AllInner for: {sources.Select(s->s.GetHashCode).JoinToString}');
      {$endif WaitDebug}
      self.sources := sources;
      for var i := 0 to sources.Length-1 do
        sources[i].Subscribe(self, new WaitHandlerDirectSubInfo(ref_counts[i], i));
      self.ref_counts := ref_counts;
      self.sub := sub;
      self.sub_data := sub_data;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    //TODO mono#11034
    public function {IWaitHandlerSub.}HandleChildInc(data: integer): boolean;
    begin
      var new_done_c := Interlocked.Increment(done_c);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation from {sources[data].GetHashCode}, new_done_c={new_done_c}/{sources.Length}');
      {$endif WaitDebug}
      
      Result := (new_done_c=sources.Length) and sub.HandleChildInc(sub_data);
    end;
    //TODO mono#11034
    public procedure {IWaitHandlerSub.}HandleChildDec(data: integer);
    begin
      var prev_done_c := Interlocked.Decrement(done_c)+1;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got deactivation from {sources[data].GetHashCode}, new_done_c={prev_done_c-1}/{sources.Length}');
      {$endif WaitDebug}
      
      if prev_done_c=sources.Length then sub.HandleChildDec(sub_data);
    end;
    
    public function TryConsume(uev: UserEvent): boolean;
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Trying to reserve');
      {$endif WaitDebug}
      Result := false;
      for var i := 0 to sources.Length-1 do
      begin
        if sources[i].TryReserve(ref_counts[i]) then continue;
        for var prev_i := 0 to i do
          sources[i].ReleaseReserve(ref_counts[i]);
        exit;
      end;
      Result := uev.SetComplete(false);
      if Result then
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Consuming');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].Comsume(ref_counts[i]);
      end else
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Abort consume');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].ReleaseReserve(ref_counts[i]);
      end;
    end;
    
  end;
  WaitHandlerAllOuter = sealed class(WaitHandlerOuter, IWaitHandlerSub)
    private sources: array of WaitHandlerDirect;
    private ref_counts: array of integer;
    private done_c := 0;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList; sources: array of WaitHandlerDirect; ref_counts: array of integer);
    begin
      inherited Create(g, prev_ev);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'This is AllOuter for: {sources.Select(s->s.GetHashCode).JoinToString}');
      {$endif WaitDebug}
      self.sources := sources;
      for var i := 0 to sources.Length-1 do
        sources[i].Subscribe(self, new WaitHandlerDirectSubInfo(ref_counts[i], i));
      self.ref_counts := ref_counts;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    //TODO mono#11034
    public function {IWaitHandlerSub.}HandleChildInc(data: integer): boolean;
    begin
      var new_done_c := Interlocked.Increment(done_c);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation from {sources[data].GetHashCode}, new_done_c={new_done_c}/{sources.Length}');
      {$endif WaitDebug}
      
      Result := (new_done_c=sources.Length) and self.IncState;
    end;
    //TODO mono#11034
    public procedure {IWaitHandlerSub.}HandleChildDec(data: integer);
    begin
      var prev_done_c := Interlocked.Decrement(done_c)+1;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got deactivation from {sources[data].GetHashCode}, new_done_c={prev_done_c-1}/{sources.Length}');
      {$endif WaitDebug}
      
      if prev_done_c=sources.Length then self.DecState;
    end;
    
    protected function TryConsume: boolean; override;
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Trying to reserve');
      {$endif WaitDebug}
      Result := false;
      for var i := 0 to sources.Length-1 do
      begin
        if sources[i].TryReserve(ref_counts[i]) then continue;
        for var prev_i := 0 to i do
          sources[i].ReleaseReserve(ref_counts[i]);
        exit;
      end;
      Result := uev.SetComplete(false);
      if Result then
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Consuming');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].Comsume(ref_counts[i]);
      end else
      begin
        {$ifdef WaitDebug}
        WaitDebug.RegisterAction(self, $'Abort consume');
        {$endif WaitDebug}
        for var i := 0 to sources.Length-1 do
          sources[i].ReleaseReserve(ref_counts[i]);
      end;
    end;
    
  end;
  
  WaitMarkerAll = sealed partial class(WaitMarkerCombination<WaitMarkerDirect>)
    private ref_counts: array of integer;
    
    public constructor(children: Dictionary<WaitMarkerDirect, integer>);
    begin
      inherited Create(children.Keys.ToArray);
      self.ref_counts := self.children.ConvertAll(key->children[key]);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      foreach var i in Range(0,children.Length-1).OrderByDescending(i->ref_counts[i]) do
      begin
        children[i].ToString(sb, tabs, index, delayed);
        if ref_counts[i]<>1 then
        begin
          sb.Length -= 1;
          sb += ' * ';
          sb.Append(ref_counts[i]);
          sb += #10;
        end;
      end;
    end;
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; override :=
    WaitHandlerAllOuter.Create(g, prev_ev, children.ConvertAll(m->m.handlers[g]), ref_counts).uev;
    
    private function GetChildrenArr: array of WaitMarkerDirect;
    begin
      Result := new WaitMarkerDirect[ref_counts.Sum];
      var res_ind := 0;
      for var i := 0 to children.Length-1 do
        loop ref_counts[i] do
        begin
          Result[res_ind] := children[i];
          res_ind += 1;
        end;
    end;
    
  end;
  
{$endregion All}

{$region Any}

type
  WaitHandlerAnyOuter = sealed class(WaitHandlerOuter, IWaitHandlerSub)
    private sources: array of WaitHandlerAllInner<WaitHandlerAnyOuter>;
    
    private done_c := 0;
    
    public constructor(g: CLTaskGlobalData; prev_ev: EventList; markers: array of WaitMarkerAll);
    begin
      inherited Create(g, prev_ev);
      self.sources := new WaitHandlerAllInner<WaitHandlerAnyOuter>[markers.Length];
      for var i := 0 to markers.Length-1 do
        self.sources[i] := new WaitHandlerAllInner<WaitHandlerAnyOuter>(markers[i].children.ConvertAll(m->m.handlers[g]), markers[i].ref_counts, self, i);
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'This is AnyOuter for: {sources.Select(s->s.GetHashCode).JoinToString}');
      {$endif WaitDebug}
    end;
    public constructor := raise new OpenCLABCInternalException;
    
    //TODO mono#11034
    public function {IWaitHandlerSub.}HandleChildInc(data: integer): boolean;
    begin
      var new_done_c := Interlocked.Increment(done_c);
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got activation from {sources[data].GetHashCode}, new_done_c={new_done_c}/{sources.Length}');
      {$endif WaitDebug}
      
      Result := (new_done_c=1) and self.IncState;
    end;
    //TODO mono#11034
    public procedure {IWaitHandlerSub.}HandleChildDec(data: integer);
    begin
      var prev_done_c := Interlocked.Decrement(done_c)+1;
      
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Got deactivation from {sources[data].GetHashCode}, new_done_c={prev_done_c-1}/{sources.Length}');
      {$endif WaitDebug}
      
      if prev_done_c=1 then self.DecState;
    end;
    
    protected function TryConsume: boolean; override;
    begin
      {$ifdef WaitDebug}
      WaitDebug.RegisterAction(self, $'Trying to consume');
      {$endif WaitDebug}
      Result := false;
      for var i := 0 to sources.Length-1 do
        if sources[i].TryConsume(uev) then
        begin
          Result := true;
          break;
        end;
    end;
    
  end;
  
  WaitMarkerAny = sealed partial class(WaitMarkerCombination<WaitMarkerAll>)
    
    public constructor(sources: array of WaitMarkerAll) := inherited Create(sources);
    private constructor := raise new OpenCLABCInternalException;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      foreach var child in children do
        child.ToString(sb, tabs, index, delayed);
    end;
    
    public function MakeWaitEv(g: CLTaskGlobalData; prev_ev: EventList): EventList; override :=
    WaitHandlerAnyOuter.Create(g, prev_ev, children).uev;
    
  end;
  
{$endregion Any}

{$region public}

type
  WaitMarkerAllFast = sealed class
    private children: Dictionary<WaitMarkerDirect, integer>;
    
    public constructor(c: integer) :=
    children := new Dictionary<WaitMarkerDirect, integer>(c);
    public constructor(m: WaitMarkerDirect);
    begin
      Create(1);
      self.children.Add(m, 1);
    end;
    public constructor(m: WaitMarkerAll);
    begin
      Create(m.children.Length);
      for var i := 0 to m.children.Length-1 do
        self.children.Add(m.children[i], m.ref_counts[i]);
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    public static function operator in(what, in_what: WaitMarkerAllFast): boolean;
    begin
      Result := false;
      
      if what.children.Count>in_what.children.Count then
        exit;
      foreach var kvp in what.children do
        if in_what.children.Get(kvp.Key) < kvp.Value then
          exit;
      
      Result := true;
    end;
    
    public static function operator+(c1, c2: WaitMarkerAllFast): WaitMarkerAllFast;
    begin
      Result := new WaitMarkerAllFast(c1.children.Count+c2.children.Count);
      foreach var kvp in c1.children do
        Result.children.Add(kvp.Key, kvp.Value);
      foreach var kvp in c2.children do
        Result.children[kvp.Key] := Result.children.Get(kvp.Key) + kvp.Value;
    end;
    
    public static procedure TryAdd(lst: List<WaitMarkerAllFast>; c: WaitMarkerAllFast);
    begin
      
      for var i := 0 to lst.Count-1 do
      begin
        var c0 := lst[i];
        
        if c0 in c then
          lst[i] := c else
        if c in c0 then
          {nothing} else
          continue;
        
        exit;
      end;
      
      lst += c;
    end;
    
    public static function MarkerFromLst(lst: IList<WaitMarkerAllFast>): WaitMarker;
    begin
      if lst.Count>1 then
      begin
        var res := new WaitMarkerAll[lst.Count];
        for var i := 0 to res.Length-1 do
          res[i] := new WaitMarkerAll(lst[i].children);
        Result := new WaitMarkerAny(res);
      end else
      case lst[0].children.Values.Sum of
        0: raise new System.ArgumentException($'%Err:WaitCombine:InpEmpty%');
        1: Result := lst[0].children.Keys.Single;
        else Result := new WaitMarkerAll(lst[0].children);
      end;
    end;
    
  end;
  
function CombineWaitAll(sub_markers: sequence of WaitMarker): WaitMarker;
begin
  var prev := |new WaitMarkerAllFast(0)| as IList<WaitMarkerAllFast>;
  var next := new List<WaitMarkerAllFast>;
  
  foreach var m in sub_markers do
  begin
    
    if m is WaitMarkerAny(var ma) then
    begin
      foreach var child in ma.children do
      begin
        var c2 := new WaitMarkerAllFast(child);
        foreach var c1 in prev do
          WaitMarkerAllFast.TryAdd(next, c1+c2);
      end;
    end else
    begin
      var c2 := if m is WaitMarkerDirect(var md) then
        new WaitMarkerAllFast(md) else
        new WaitMarkerAllFast(WaitMarkerAll(m));
      foreach var c1 in prev do
        next += c1+c2;
    end;
    
    prev := next.ToArray;
    next.Clear;
  end;
  
  Result := WaitMarkerAllFast.MarkerFromLst(prev);
end;
function CombineWaitAll(params sub_markers: array of WaitMarker) := CombineWaitAll(sub_markers.AsEnumerable);

function CombineWaitAny(sub_markers: sequence of WaitMarker): WaitMarker;
begin
  var res := new List<WaitMarkerAllFast>;
  foreach var m in sub_markers do
    if m is WaitMarkerAny(var ma) then
    begin
      foreach var child in ma.children do
        WaitMarkerAllFast.TryAdd(res, new WaitMarkerAllFast(child));
    end else
    begin
      var c := if m is WaitMarkerDirect(var md) then
        new WaitMarkerAllFast(md) else
        new WaitMarkerAllFast(WaitMarkerAll(m));
      WaitMarkerAllFast.TryAdd(res, c);
    end;
  Result := WaitMarkerAllFast.MarkerFromLst(res);
end;
function CombineWaitAny(params sub_markers: array of WaitMarker) := CombineWaitAny(sub_markers.AsEnumerable);

static function WaitMarker.operator and(m1, m2: WaitMarker) := CombineWaitAll(|m1, m2|);
static function WaitMarker.operator or(m1, m2: WaitMarker) := CombineWaitAny(|m1, m2|);

{$endregion public}

{$endregion Combination}

{$endregion Def}

{$region WaitMarkerDummy}

type
  WaitMarkerDummyExecutor = sealed class(CommandQueueNil)
    private m: WaitMarkerDirect;
    
    public constructor(m: WaitMarkerDirect) := self.m := m;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := exit;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      Result := new QueueResNil(l);
      
      if Result.ShouldInstaCallAction then
      begin
        if not g.curr_err_handler.HadError then
          m.SendSignal;
      end else
      begin
        var err_handler := g.curr_err_handler;
        Result.AddAction(c->if not err_handler.HadError then m.SendSignal);
      end;
      
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      m.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  WaitMarkerDummy = sealed class(WaitMarkerDirect)
    private executor: WaitMarkerDummyExecutor;
    public constructor := executor := new WaitMarkerDummyExecutor(self);
    
    private function ConvertToQBase: CommandQueueBase; override := executor;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override := sb += #10;
    
  end;
  
static function WaitMarker.Create := new WaitMarkerDummy;

{$endregion WaitMarkerDummy}

{$region ThenMarkerSignal}

type
  CommandQueueMarkedCapWrapper<TQ> = sealed class(WaitMarkerDirect)
  where TQ: CommandQueueBase;
    protected org: TQ;
    
    public constructor(org: TQ) := self.org := org;
    private constructor := raise new OpenCLABCInternalException;
    
    private function ConvertToQBase: CommandQueueBase; override := org;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      sb.Append(#9, tabs);
      org.ToStringHeader(sb, index);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueMarkedCapCommon<TQ> = record
  where TQ: CommandQueueBase;
    public q: TQ;
    public wrap: CommandQueueMarkedCapWrapper<TQ>;
    public signal_in_finally: boolean;
    
    public procedure Init(q: TQ; wrap: CommandQueueMarkedCapWrapper<TQ>; signal_in_finally: boolean);
    begin
      self.q := q;
      self.wrap := wrap;
      self.signal_in_finally := signal_in_finally;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>) := q.InitBeforeInvoke(g, inited_mu);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(prev_qr: TR; err_handler: CLTaskErrHandler): TR; where TR: IQueueRes;
    begin
      if prev_qr.ShouldInstaCallAction then
      begin
        if signal_in_finally or not err_handler.HadError then
          wrap.SendSignal;
      end else
      if signal_in_finally then
        prev_qr.AddAction(c->wrap.SendSignal()) else
        prev_qr.AddAction(c->if not err_handler.HadError then wrap.SendSignal);
      Result := prev_qr;
    end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_q: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      Result := Invoke(invoke_q(g,l), g.curr_err_handler);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      
      sb.Append(#9, tabs);
      wrap.ToStringHeader(sb, index);
      sb += #10;
      
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CommandQueueMarkedCapNil = sealed partial class(CommandQueueNil)
    data: CommandQueueMarkedCapCommon<CommandQueueNil>;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := data.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.Invoke(data.q.InvokeToNil(g,l), g.curr_err_handler);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  CommandQueueMarkedCap<T> = sealed partial class(CommandQueue<T>)
    data: CommandQueueMarkedCapCommon<CommandQueue<T>>;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := data.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := data.Invoke(g, l, data.q.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := data.Invoke(g, l, data.q.InvokeToAny);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.Invoke(g, l, data.q.InvokeToPtr);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
function CommandQueueMarkedCapNil.get_signal_in_finally := data.signal_in_finally;
function CommandQueueMarkedCap<T>.get_signal_in_finally := data.signal_in_finally;

constructor CommandQueueMarkedCapNil.Create(q: CommandQueueNil; signal_in_finally: boolean);
begin
  data.Init(q, new CommandQueueMarkedCapWrapper<CommandQueueNil>(self), signal_in_finally);
end;
constructor CommandQueueMarkedCap<T>.Create(q: CommandQueue<T>; signal_in_finally: boolean);
begin
  data.Init(q, new CommandQueueMarkedCapWrapper<CommandQueue<T>>(self), signal_in_finally);
  self.const_res_dep      := q.const_res_dep;
  self.expected_const_res := q.expected_const_res;
end;

static function CommandQueueMarkedCapNil.operator implicit(dms: CommandQueueMarkedCapNil) := dms.data.wrap;
static function CommandQueueMarkedCap<T>.operator implicit(dms: CommandQueueMarkedCap<T>) := dms.data.wrap;

{$endregion ThenMarkerSignal}

{$region WaitFor}

type
  CommandQueueWaitFor = sealed class(CommandQueueNil)
    public marker: WaitMarker;
    public constructor(marker: WaitMarker) := self.marker := marker;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    marker.InitInnerHandles(g);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    new QueueResNil( marker.MakeWaitEv(g,l) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      marker.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function WaitFor(marker: WaitMarker) := new CommandQueueWaitFor(marker);

{$endregion WaitFor}

{$region ThenWaitFor}

type
  CommandQueueThenBaseWaitFor<T> = abstract class(CommandQueue<T>)
    public q: CommandQueue<T>;
    public marker: WaitMarker;
    
    public constructor(q: CommandQueue<T>; marker: WaitMarker);
    begin
      self.q := q;
      self.marker := marker;
      self.const_res_dep      := q.const_res_dep;
      self.expected_const_res := q.expected_const_res;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override;
    begin
      q.InitBeforeInvoke(g, inited_mu);
      marker.InitInnerHandles(g);
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
      marker.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CommandQueueThenWaitFor<T> = sealed class(CommandQueueThenBaseWaitFor<T>)
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_q: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      var prev_qr := invoke_q(g, l);
      Result := prev_qr.MakeWrapWith(
        marker.MakeWaitEv(g,
          prev_qr.AttachInvokeActions(g)
        )
      );
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := Invoke(g, l, q.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, q.InvokeToAny);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, q.InvokeToPtr);
    
  end;
  CommandQueueThenFinallyWaitFor<T> = sealed class(CommandQueueThenBaseWaitFor<T>)
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_q: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      
      var pre_q_err_handler := g.curr_err_handler;
      var prev_qr := invoke_q(g, l);
      var post_q_err_handler := g.curr_err_handler;
      
      g.curr_err_handler := pre_q_err_handler;
      var res_ev := marker.MakeWaitEv(g, prev_qr.AttachInvokeActions(g));
      {$ifdef DEBUG}
      if g.curr_err_handler <> pre_q_err_handler then
        raise new OpenCLABCInternalException($'MakeWaitEv should not change g.curr_err_handler');
      // Otherwise, CLTaskErrHandlerBranchBud (like in >=) would be needed
      {$endif DEBUG}
      g.curr_err_handler := post_q_err_handler;
      
      Result := prev_qr.MakeWrapWith(res_ev);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := Invoke(g, l, q.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, q.InvokeToAny);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, q.InvokeToPtr);
    
  end;
  
function CommandQueue<T>.ThenWaitFor(marker: WaitMarker) := new CommandQueueThenWaitFor<T>(self, marker);
function CommandQueue<T>.ThenFinallyWaitFor(marker: WaitMarker) := new CommandQueueThenFinallyWaitFor<T>(self, marker);

{$endregion ThenWaitFor}

{$endregion Wait}

{$region Finally}

type
  CommandQueueTryFinallyCommon<TQ> = record
  where TQ: CommandQueueBase;
    public try_do: CommandQueueBase;
    public do_finally: TQ;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>);
    begin
      try_do.InitBeforeInvoke(g, inited_mu);
      do_finally.InitBeforeInvoke(g, inited_mu);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; invoke_finally: CommandQueueInvoker<TR>): TR; where TR: IQueueRes;
    begin
      var origin_err_handler := g.curr_err_handler;
      
      {$region try_do}
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(origin_err_handler);
      l := try_do.InvokeToNil(g, l).base;
      var try_handler := g.curr_err_handler;
      
      {$endregion try_do}
      
      {$region do_finally}
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(origin_err_handler);
      Result := invoke_finally(g, l);
      var fin_handler := g.curr_err_handler;
      
      {$endregion do_finally}
      
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(origin_err_handler, |try_handler, fin_handler|);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      try_do.ToString(sb, tabs, index, delayed);
      do_finally.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  CommandQueueTryFinallyNil = sealed class(CommandQueueNil)
    private data := new CommandQueueTryFinallyCommon< CommandQueueNil >;
    
    private constructor(try_do: CommandQueueBase; do_finally: CommandQueueNil);
    begin
      data.try_do := try_do;
      data.do_finally := do_finally;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    data.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := data.Invoke(g, l, data.do_finally.InvokeToNil);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  CommandQueueTryFinally<T> = sealed class(CommandQueue<T>)
    private data := new CommandQueueTryFinallyCommon< CommandQueue<T> >;
    
    private constructor(try_do: CommandQueueBase; do_finally: CommandQueue<T>);
    begin
      data.try_do := try_do;
      data.do_finally := do_finally;
      self.const_res_dep      := do_finally.const_res_dep;
      self.expected_const_res := do_finally.expected_const_res;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    data.InitBeforeInvoke(g, inited_mu);
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := data.Invoke(g, l, data.do_finally.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := data.Invoke(g, l, data.do_finally.InvokeToAny);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := data.Invoke(g, l, data.do_finally.InvokeToPtr);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override :=
    data.ToString(sb, tabs, index, delayed);
    
  end;
  
  CommandQueueTryFinallyConstructor = sealed auto class(ITypedCQConverter<CommandQueueBase>)
    private try_do: CommandQueueBase;
    
    public function ConvertNil(do_finally: CommandQueueNil): CommandQueueBase :=
    new CommandQueueTryFinallyNil(try_do, do_finally);
    public function Convert<T>(do_finally: CommandQueue<T>): CommandQueueBase :=
    new CommandQueueTryFinally<T>(try_do, do_finally);
    
  end;
  
function operator>=<TQ>(try_do: CommandQueueBase; do_finally: TQ): TQ; extensionmethod; where TQ: CommandQueueBase;
begin
  Result := TQ(do_finally.ConvertTyped(
    new CommandQueueTryFinallyConstructor(try_do)
  ));
end;

function operator>=(q: CommandQueueBase; m: WaitMarker); extensionmethod := q >= CommandQueueBase(m);

{$endregion Finally}

{$region Handle}

type
  
  CommandQueueHandleWithoutRes = sealed class(CommandQueueNil)
    private try_do: CommandQueueBase;
    private handler: Exception->boolean;
    
    public constructor(try_do: CommandQueueBase; handler: Exception->boolean);
    begin
      self.try_do := try_do;
      self.handler := handler;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    try_do.InitBeforeInvoke(g, inited_mu);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ApplyTo(err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG});
    begin
      try
        err_handler.TryRemoveErrors(self.handler);
      except
        on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
      end;
      {$ifdef DEBUG}
      err_handler.EndMaybeError(err_test_reason);
      {$endif DEBUG}
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(pre_inv_handler);
      Result := try_do.InvokeToNil(g, l);
      var post_inv_handler := g.curr_err_handler;
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, |post_inv_handler|);
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.Apply';
      post_inv_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      if Result.ShouldInstaCallAction then
        self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}) else
        Result.AddAction(c->self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}));
      
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      try_do.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, handler);
      sb += #10;
      
    end;
    
  end;
  
  CommandQueueHandleWithoutResConstructor = record(ITypedCQConverter<CommandQueueNil>)
    
    function ConvertNil(cq: CommandQueueNil): CommandQueueNil :=
    if cq is ConstQueueNil then cq else nil;
    function Convert<T>(cq: CommandQueue<T>): CommandQueueNil :=
    if (cq is ConstQueue<T>) or (cq is ParameterQueue<T>) then CQNil else nil;
    
  end;
  
function CommandQueueBase.HandleWithoutRes(handler: Exception->boolean) :=
self.ConvertTyped(new CommandQueueHandleWithoutResConstructor) ??
new CommandQueueHandleWithoutRes(self, handler);

type
  CommandQueueHandleDefaultRes<T> = sealed class(CommandQueue<T>)
    private try_do: CommandQueue<T>;
    private handler: Exception->boolean;
    private def: T;
    
    public constructor(try_do: CommandQueue<T>; handler: Exception->boolean; def: T);
    begin
      self.try_do := try_do;
      self.handler := handler;
      self.def := def;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    try_do.InitBeforeInvoke(g, inited_mu);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ApplyTo(err_handler: CLTaskErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG});
    begin
      try
        err_handler.TryRemoveErrors(self.handler);
      except
        on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
      end;
      {$ifdef DEBUG}
      err_handler.EndMaybeError(err_test_reason);
      {$endif DEBUG}
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(pre_inv_handler);
      Result := try_do.InvokeToNil(g, l);
      var post_inv_handler := g.curr_err_handler;
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, |post_inv_handler|);
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.Apply';
      post_inv_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      if Result.ShouldInstaCallAction then
        self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}) else
        Result.AddAction(c->self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}));
      
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(pre_inv_handler);
      var prev_qr := try_do.InvokeToAny(g, l);
      var post_inv_handler := g.curr_err_handler;
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, |post_inv_handler|);
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.Apply';
      post_inv_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      Result := prev_qr.TransformResult(qr_factory, true, prev_res->
      begin
        if not post_inv_handler.HadError then
        begin
          Result := prev_res;
          {$ifdef DEBUG}
          post_inv_handler.EndMaybeError(err_test_reason);
          {$endif DEBUG}
        end else
        begin
          self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
          Result := self.def;
        end;
      end);
      
    end;
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      ToStringRuntimeValue(sb, self.def);
      sb += #10;
      
      try_do.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, handler);
      sb += #10;
      
    end;
    
  end;
  
function CommandQueue<T>.HandleDefaultRes(handler: Exception->boolean; def: T): CommandQueue<T> :=
if (self is ConstQueue<T>) or (self is ParameterQueue<T>) then self else
new CommandQueueHandleDefaultRes<T>(self, handler, def);

type
  CommandQueueHandleReplaceRes<T> = sealed class(CommandQueue<T>)
    private try_do: CommandQueue<T>;
    private handler: List<Exception> -> T;
    
    public constructor(try_do: CommandQueue<T>; handler: List<Exception> -> T);
    begin
      self.try_do := try_do;
      self.handler := handler;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    try_do.InitBeforeInvoke(g, inited_mu);
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function ApplyTo(err_handler: CLTaskErrHandlerThiefBase{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG}): ValueTuple<boolean,T>;
    begin
      Result.Item1 := err_handler.HadError;
      if Result.Item1 then
      begin
        err_handler.StealPrevErrors;
        try
          Result.Item2 := self.handler(err_handler.AccessErrors);
        except
          on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
        end;
      end;
      {$ifdef DEBUG}
      err_handler.EndMaybeError(err_test_reason);
      {$endif DEBUG}
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(pre_inv_handler);
      Result := try_do.InvokeToNil(g, l);
      var post_inv_handler := new CLTaskErrHandlerThief(g.curr_err_handler);
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, new CLTaskErrHandler[](post_inv_handler));
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.Apply';
      post_inv_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      if Result.ShouldInstaCallAction then
        self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}) else
        Result.AddAction(c->self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}));
      
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: QueueRes<T>;
    begin
      var pre_inv_handler := g.curr_err_handler;
      
      g.curr_err_handler := new CLTaskErrHandlerBranchBud(pre_inv_handler);
      var prev_qr := try_do.InvokeToAny(g, l);
      var post_inv_handler := new CLTaskErrHandlerThief(g.curr_err_handler);
      g.curr_err_handler := new CLTaskErrHandlerBranchCombinator(pre_inv_handler, new CLTaskErrHandler[](post_inv_handler));
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.Apply';
      post_inv_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      Result := prev_qr.TransformResult(qr_factory, true, prev_res->
      begin
        var (appl, res) := self.ApplyTo(post_inv_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
        Result := if appl then res else prev_res;
      end);
      
    end;
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      
      try_do.ToString(sb, tabs, index, delayed);
      
      sb.Append(#9, tabs);
      ToStringWriteDelegate(sb, handler);
      sb += #10;
      
    end;
    
  end;
  
function CommandQueue<T>.HandleReplaceRes(handler: List<Exception> -> T) :=
if (self is ConstQueue<T>) or (self is ParameterQueue<T>) then self else
new CommandQueueHandleReplaceRes<T>(self, handler);

{$endregion Handle}

{$endregion Queue converter's}

{$region GPUCommand}

{$region Base}

type
  GPUCommand<T> = abstract class
    
    protected function TryPreCall(q: CommandQueue<T>): boolean; abstract;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); abstract;
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; abstract;
    
    protected static procedure ToStringWriteDelegate(sb: StringBuilder; d: System.Delegate) := CommandQueueBase.ToStringWriteDelegate(sb,d);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); abstract;
    
    private procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb.Append(#9, tabs);
      sb += TypeName(self);
      self.ToStringImpl(sb, tabs+1, index, delayed);
    end;
    
  end;
  
{$endregion Base}

{$region Queue}

type
  QueueCommand<T> = sealed class(GPUCommand<T>)
    public q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function TryPreCall(q: CommandQueue<T>): boolean; override := false;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    q.InitBeforeInvoke(g, inited_mu);
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := q.InvokeToNil(g, l);
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  //TODO Разбить на 2 ITypedCQConverter: IsEmpty и CastUnpack
  QueueCommandConstructor<TObj> = sealed class(ITypedCQConverter<GPUCommand<TObj>>)
    
    public function ConvertNil(cq: CommandQueueNil): GPUCommand<TObj> :=
    if cq is ConstQueueNil then nil else
      new QueueCommand<TObj>(cq);
    public function Convert<T>(cq: CommandQueue<T>): GPUCommand<TObj> :=
    if cq is ConstQueue<T> then nil else
    if cq is ParameterQueue<T> then nil else
    if cq is CastQueueBase<T>(var ccq) then
      ccq.SourceBase.ConvertTyped(self) else
      new QueueCommand<TObj>(cq);
    
    public static function Make(q: CommandQueueBase): GPUCommand<TObj> :=
    q.ConvertTyped(new QueueCommandConstructor<TObj>);
    
  end;
  
{$endregion Queue}

{$region Proc} type
  
  {$region Base}
  
  ProcCommandBase<T, TProc> = abstract class(GPUCommand<T>)
  where TProc: ISimpleProcContainer<T>;
    public p: TProc;
    public can_pre_call: boolean;
    
    public constructor(p: TProc; can_pre_call: boolean);
    begin
      self.p := p;
      self.can_pre_call := can_pre_call;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function TryPreCall(q: CommandQueue<T>): boolean; override;
    begin
      Result := false;
      if not can_pre_call then exit;
      if q.const_res_dep=nil then exit;
      p.Invoke(q.expected_const_res, nil);
      Result := q.IsConstResDepEmpty;
    end;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := exit;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      p.ToStringB(sb);
      sb += #10;
    end;
    
  end;
  
  {$endregion Base}
  
  {$region Quick}
  
  QuickProcCommand<T, TProc> = sealed class(ProcCommandBase<T, TProc>)
  where TProc: ISimpleProcContainer<T>;
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      Result := new QueueResNil(l);
      if can_pre_call and dep_ok then exit;
      
      var prev_qr := inp.InvokeToAny(g, l);
      var should_insta_call := if can_pre_call then
        prev_qr.IsConst else
        prev_qr.ShouldInstaCallAction;
      
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.p.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      if should_insta_call then
        p.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}, prev_qr.GetResDirect, g.c) else
        //TODO #????: self.
        Result.AddAction(c->self.p.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}, prev_qr.GetResDirect, c));
      
    end;
    
  end;
  
  {$endregion Quick}
  
  {$region Threaded}
  
  ThreadedProcCommand<T, TProc> = sealed class(ProcCommandBase<T, TProc>)
  where TProc: ISimpleProcContainer<T>;
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      if can_pre_call and dep_ok then
      begin
        Result := new QueueResNil(l);
        exit;
      end;
      
      var prev_qr := inp.InvokeToAny(g, l);
      l := prev_qr.TakeBaseOut;
      var acts := l.prev_delegate;
      var c := g.c;
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.p.Invoke';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      var work_ev := UserEvent.StartWorkThread(l.prev_ev, ()->
      begin
        acts.Invoke(c);
        p.Invoke(err_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}, prev_qr.GetResDirect, c);
      end, g
      {$ifdef EventDebug}, $'body of {TypeName(self)}'{$endif});
      
      Result := new QueueResNil(work_ev);
    end;
    
  end;
  
  {$endregion Threaded}
  
  {$region Constructor}
  
  ProcCommandConstructor<TObj> = sealed class
    
    private constructor := raise new OpenCLABCInternalException;
    
    public static function Make<TProc>(p: TProc; need_own_thread, can_pre_calc: boolean): GPUCommand<TObj>; where TProc: ISimpleProcContainer<TObj>;
    begin
      // Check for const input is in a .Validate
      if need_own_thread then
        Result := new ThreadedProcCommand<TObj, TProc>(p, can_pre_calc) else
        Result := new    QuickProcCommand<TObj, TProc>(p, can_pre_calc);
    end;
    
  end;
  
  {$endregion Constructor}
  
{$endregion Proc}

{$region Wait}

type
  WaitCommand<T> = sealed class(GPUCommand<T>)
    public marker: WaitMarker;
    
    public constructor(marker: WaitMarker) := self.marker := marker;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function TryPreCall(q: CommandQueue<T>): boolean; override := false;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    marker.InitInnerHandles(g);
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override :=
    new QueueResNil( marker.MakeWaitEv(g,l) );
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      marker.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
  WaitCommandConstructor<TObj> = sealed class
    
    private constructor := raise new OpenCLABCInternalException;
    
    public static function Make(marker: WaitMarker) := new WaitCommand<TObj>(marker);
    
  end;
  
{$endregion Wait}

{$endregion GPUCommand}

{$region GPUCommandContainer}

{$region Base}

type
  GPUCommandContainer<T> = abstract class(CommandQueue<T>)
    protected q: CommandQueue<T>;
    
    protected commands := new List<GPUCommand<T>>;
    // Not nil only when commands are nil
    private commands_in: GPUCommandContainer<T>;
    private old_command_count: integer;
    
    protected constructor(q: CommandQueue<T>);
    begin
      self.q := q.Multiusable;
      self.const_res_dep      := q.const_res_dep;
      self.expected_const_res := q.expected_const_res;
    end;
    
    protected constructor(ccq: GPUCommandContainer<T>);
    begin
      self.q := ccq.q;
      self.commands := ccq.commands;
    end;
    
    private constructor := raise new OpenCLABCInternalException;
    
    private procedure TakeCommandsBack;
    begin
      var commands_in := self.commands_in;
      if commands_in=nil then exit;
      
      while true do
      begin
        var next := commands_in.commands_in;
        if next=nil then break;
        commands_in := next;
      end;
      
      var commands := new List<GPUCommand<T>>(old_command_count);
      for var i := 0 to old_command_count-1 do
        commands += commands_in.commands[i];
      
      Volatile.Write(self.commands, commands);
      Volatile.Write(self.commands_in, nil);
    end;
    
    public function Clone: GPUCommandContainer<T>; abstract;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override;
    begin
      q.InitBeforeInvoke(g, inited_mu);
      TakeCommandsBack;
      foreach var comm in self.commands do comm.InitBeforeInvoke(g, inited_mu);
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; last_invoke: CommandQueueInvoker<TR>): TR;
    begin
      var dep_ok := g.CheckDeps(q.const_res_dep);
      l := q.InvokeToNil(g,l).base; //TODO Костыль, но сначала убрать .MU из заголовка
      
      foreach var comm in commands do
        l := comm.Invoke(dep_ok,q, g,l).base;
      
      Result := last_invoke(g,l);
    end;
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := Invoke(g, l, q.InvokeToNil);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<T>; override := Invoke(g, l, q.InvokeToAny);
    
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override;
    begin
      Result := nil;
      raise new OpenCLABCInternalException($'%Err:Invoke:InvalidToPtr%');
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
      TakeCommandsBack;
      foreach var comm in commands do
        comm.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
function AddCommand<TContainer, T>(cc: TContainer; comm: GPUCommand<T>): TContainer; where TContainer: GPUCommandContainer<T>;
begin
  if comm.TryPreCall(cc.q) then exit;
  cc.TakeCommandsBack;
  Result := TContainer(cc.Clone);
  cc.commands_in := Result;
  //TODO #????
  cc.old_command_count := (cc as GPUCommandContainer<T>).commands.Count;
  cc.commands := nil;
  Result.commands += comm;
end;

{$endregion Base}

{$region CLKernel}

type
  CLKernelCCQ = sealed partial class(GPUCommandContainer<CLKernel>)
    
    private constructor(ccq: GPUCommandContainer<CLKernel>) := inherited;
    public function Clone: GPUCommandContainer<CLKernel>; override := new CLKernelCCQ(self);
    
  end;
  
{%ContainerCommon\CLKernel\Implementation!ContainerCommon.pas%}

{$endregion CLKernel}

{$region CLMemory}

type
  CLMemoryCCQ = sealed partial class(GPUCommandContainer<CLMemory>)
    
    private constructor(ccq: GPUCommandContainer<CLMemory>) := inherited;
    public function Clone: GPUCommandContainer<CLMemory>; override := new CLMemoryCCQ(self);
    
  end;
  
{%ContainerCommon\CLMemory\Implementation!ContainerCommon.pas%}

{$endregion CLMemory}

{$region CLValue}

type
  CLValueCCQ<T> = sealed partial class(GPUCommandContainer<CLValue<T>>)
    
    private constructor(ccq: GPUCommandContainer<CLValue<T>>) := inherited;
    public function Clone: GPUCommandContainer<CLValue<T>>; override := new CLValueCCQ<T>(self);
    
  end;
  
{%ContainerCommon\CLValue\Implementation!ContainerCommon.pas%}

{$endregion CLArray}

{$region CLArray}

type
  CLArrayCCQ<T> = sealed partial class(GPUCommandContainer<CLArray<T>>)
    
    private constructor(ccq: GPUCommandContainer<CLArray<T>>) := inherited;
    public function Clone: GPUCommandContainer<CLArray<T>>; override := new CLArrayCCQ<T>(self);
    
  end;
  
{%ContainerCommon\CLArray\Implementation!ContainerCommon.pas%}

{$endregion CLArray}

{$endregion GPUCommandContainer}

{$region CLKernelArg}

{$region Common}

{$region Base}

type
  CLKernelArgCacheEntry = record
    public val_is_set: boolean;
    public last_set_val: object;
    
    public function TrySetVal(val: object): boolean;
    begin
      Result := false;
      if self.val_is_set and Object.Equals(self.last_set_val, val) then exit;
      self.val_is_set := true;
      self.last_set_val := val;
      Result := true;
    end;
    
  end;
  CLKernelArgCache = record
    private ntv: cl_kernel;
    private vals: array of CLKernelArgCacheEntry;
    
    public constructor(k: CLKernel; args_c: integer);
    begin
      self.ntv := k.AllocNative;
      self.vals := new CLKernelArgCacheEntry[args_c];
    end;
    public constructor := raise new OpenCLABCInternalException;
    
    public function TrySetVal(ind: integer; val: object) := vals[ind].TrySetVal(val);
    
    public procedure Release(k: CLKernel);
    begin
      k.ReleaseNative(self.ntv);
      {$ifdef DEBUG}
      self.ntv := cl_kernel.Zero;
      {$endif DEBUG}
    end;
    
  end;
  
  CLKernelArgSetter = abstract class
    private is_const: boolean;
    
    public constructor(is_const: boolean) := self.is_const := is_const;
    private constructor := raise new OpenCLABCInternalException;
    
    public property IsConst: boolean read is_const;
    
    public procedure Apply(ind: UInt32; cache: CLKernelArgCache); abstract;
    
  end;
  CLKernelArgSetterTyped<T> = abstract class(CLKernelArgSetter)
    protected o := default(T);
    {$ifdef DEBUG}
    private o_set := false;
    {$endif DEBUG}
    
    public constructor(o: T);
    begin
      inherited Create(true);
      SetObj(o);
    end;
    public constructor :=
    inherited Create(false);
    
    public procedure SetObj(o: T);
    begin
      {$ifdef DEBUG}
      if o_set then raise new OpenCLABCInternalException($'Conflicting {TypeName(self)} values');
      o_set := true;
      {$endif DEBUG}
      self.o := o;
    end;
    
    public procedure Apply(ind: UInt32; cache: CLKernelArgCache); override;
    begin
      {$ifdef DEBUG}
      if not o_set then
        raise new OpenCLABCInternalException($'Unset {TypeName(self)} value');
      {$endif DEBUG}
      
      if not cache.TrySetVal(ind, self.o) then exit;
      
      ApplyImpl(cache.ntv, ind);
    end;
    public procedure ApplyImpl(k: cl_kernel; ind: UInt32); abstract;
    
  end;
  
  CLKernelArg = abstract partial class
    
    protected function TryGetConstSetter: CLKernelArgSetter; abstract;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); abstract;
    
    protected function Invoke(inv: CLTaskBranchInvoker): ValueTuple<CLKernelArgSetter, EventList>; abstract;
    
  end;
  
{$endregion Base}

{$region Global}

type
  CLKernelArgSetterGlobal<TWrap> = sealed class(CLKernelArgSetterTyped<cl_mem>)
  where TWrap: class;
    private wrap: TWrap := nil;
    
    public constructor(wrap: TWrap; mem: cl_mem);
    begin
      inherited Create(mem);
      self.wrap := wrap;
    end;
    public constructor := inherited;
    
    public procedure SetObj(wrap: TWrap; mem: cl_mem);
    begin
      inherited SetObj(mem);
      self.wrap := wrap;
    end;
    public procedure ApplyImpl(k: cl_kernel; ind: UInt32); override;
    begin
      OpenCLABCInternalException.RaiseIfError(
        cl.SetKernelArg(k, ind, new UIntPtr(cl_mem.Size), self.o)
      );
      
      GC.KeepAlive(self.wrap);
      self.wrap := nil;
    end;
    
  end;
  
  CLKernelArgGlobalCommon<TWrap> = record
  where TWrap: class;
    private q: CommandQueue<TWrap>;
    
    public constructor(q: CommandQueue<TWrap>) := self.q := q;
    public constructor := raise new OpenCLABCInternalException;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function TryGetConstSetter(get_ntv: TWrap->cl_mem): CLKernelArgSetter :=
    if q is ConstQueue<TWrap>(var c_q) then
      new CLKernelArgSetterGlobal<TWrap>(c_q.Value, get_ntv(c_q.Value)) else nil;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke(inv: CLTaskBranchInvoker; get_ntv: TWrap->cl_mem): ValueTuple<CLKernelArgSetter, EventList>;
    begin
      var wrap_qr := inv.InvokeBranch(q.InvokeToAny);
      var arg_setter: CLKernelArgSetter;
      if wrap_qr.IsConst then
      begin
        var wrap := wrap_qr.GetResDirect;
        arg_setter := new CLKernelArgSetterGlobal<TWrap>(wrap, get_ntv(wrap));
      end else
      begin
        var res := new CLKernelArgSetterGlobal<TWrap>;
        wrap_qr.AddAction(c->
        begin
          var wrap := wrap_qr.GetResDirect;
          res.SetObj(wrap, get_ntv(wrap));
        end);
        arg_setter := res;
      end;
      Result := ValueTuple.Create(arg_setter,
        wrap_qr.AttachInvokeActions(inv.g)
      );
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  CLKernelArgConstantCommon<TWrap> = CLKernelArgGlobalCommon<TWrap>;
  
{$endregion GlobalWrap}

{$region Local}

type
  CLKernelArgSetterLocalBytes = sealed class(CLKernelArgSetterTyped<UIntPtr>)
    
    public procedure ApplyImpl(k: cl_kernel; ind: UInt32); override :=
    OpenCLABCInternalException.RaiseIfError( cl.SetKernelArg(k, ind, self.o, nil) );
    
  end;
  
  CLKernelArgLocal = abstract partial class(CLKernelArg) end;
  CLKernelArgLocalBytes = sealed class(CLKernelArgLocal)
    private bytes: CommandQueue<UIntPtr>;
    
    public constructor(bytes: CommandQueue<UIntPtr>) := self.bytes := bytes;
    private constructor := raise new OpenCLABCInternalException;
    
    protected function TryGetConstSetter: CLKernelArgSetter; override :=
    if bytes is ConstQueue<UIntPtr>(var c_bytes) then
      new CLKernelArgSetterLocalBytes(c_bytes.Value) else nil;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override :=
    bytes.InitBeforeInvoke(g, inited_mu);
    
    protected function Invoke(inv: CLTaskBranchInvoker): ValueTuple<CLKernelArgSetter, EventList>; override;
    begin
      var bytes_qr := inv.InvokeBranch(bytes.InvokeToAny);
      var arg_setter: CLKernelArgSetter;
      if bytes_qr.IsConst then
        arg_setter := new CLKernelArgSetterLocalBytes(bytes_qr.GetResDirect) else
      begin
        var res := new CLKernelArgSetterLocalBytes;
        bytes_qr.AddAction(c->res.SetObj(bytes_qr.GetResDirect));
        arg_setter := res;
      end;
      Result := ValueTuple.Create(arg_setter,
        bytes_qr.AttachInvokeActions(inv.g)
      );
    end;
    
    protected procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += #10;
      bytes.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
{$endregion Local}

{$region Private}

type
  CLKernelArgPrivateCommon<TInp> = record
    private q: CommandQueue<TInp>;
    
    public constructor(q: CommandQueue<TInp>) := self.q := q;
    public constructor := raise new OpenCLABCInternalException;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke(inv: CLTaskBranchInvoker; make_const: TInp->CLKernelArgSetterTyped<TInp>; make_delayed: ()->CLKernelArgSetterTyped<TInp>): ValueTuple<CLKernelArgSetter, EventList>;
    begin
      var prev_qr := inv.InvokeBranch(q.InvokeToAny);
      var arg_setter: CLKernelArgSetter;
      if prev_qr.IsConst then
        arg_setter := make_const(prev_qr.GetResDirect) else
      begin
        var res := make_delayed();
        prev_qr.AddAction(c->res.SetObj(prev_qr.GetResDirect));
        arg_setter := res;
      end;
      Result := ValueTuple.Create(arg_setter,
        prev_qr.AttachInvokeActions(inv.g)
      );
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ToString(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>);
    begin
      sb += #10;
      q.ToString(sb, tabs, index, delayed);
    end;
    
  end;
  
{$endregion Private}

{$endregion Common}

{%CLKernelArg\implementation!CLKernelArg.pas%}

{$endregion CLKernelArg}

{$region Enqueueable's}

{$region Core}

type
  DirectEnqRes = ValueTuple<cl_event, QueueResAction>;
  EnqRes = ValueTuple<EventList, QueueResAction>;
  EnqFunc<T> = function(prev_res: T; cq: cl_command_queue; ev_l2: EventList): DirectEnqRes;
  
  ParamInvRes<T> = ValueTuple<CLTaskErrHandler, EnqFunc<T>>;
  InvokeParamsFunc<T> = function(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ParamInvRes<T>;
  
  EnqueueableCore = static class
    
    private static function ExecuteEnqFunc<T>(
      prev_res: T;
      cq: cl_command_queue;
      ev_l2: EventList;
      enq_f: EnqFunc<T>;
      l1_err_handler,l2_err_handler: CLTaskErrHandler
      {$ifdef DEBUG}; err_test_reason: string{$endif}
      {$ifdef EventDebug}; q: object{$endif}
    ): EnqRes;
    begin
      var direct_enq_res: DirectEnqRes;
      try
        {$ifdef DEBUG}
        if prev_res=default(t) then
          raise new OpenCLABCInternalException($'NULL Native');
        {$endif DEBUG}
        Result := new EnqRes(ev_l2, nil);
        if l1_err_handler.HadError then exit;
        
        try
          direct_enq_res := enq_f(prev_res, cq, ev_l2);
        except
          on e: Exception do
          begin
            l1_err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
            exit;
          end;
        end;
      finally
        {$ifdef DEBUG}
        l1_err_handler.EndMaybeError(err_test_reason);
        {$endif DEBUG}
      end;
      
      var (enq_ev, act) := direct_enq_res;
      if enq_ev=cl_event.Zero then exit;
      
      {$ifdef EventDebug}
      EventDebug.RegisterEventRetain(enq_ev, $'Enq by {TypeName(q)}, waiting on [{ev_l2.evs?.JoinToString}]');
      {$endif EventDebug}
      // 1. ev_l2 can only be released after executing dependant command
      // 2. If event in ev_l2 would complete with error, enq_ev would have non-descriptive error code
      Result := new EnqRes(ev_l2+enq_ev, act);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function Invoke<T>(
      enq_c: integer;
      o_const: boolean; get_o: ()->T;
      g: CLTaskGlobalData; l: CLTaskLocalData;
      invoke_params: InvokeParamsFunc<T>;
      on_err: ErrorCode->()
      {$ifdef DEBUG}; q: object{$endif}
    ): EnqRes;
    begin
      
      var enq_evs := new DoubleEventListList(enq_c+1);
      var (l1_err_handler, enq_f) := invoke_params(enq_c, o_const, g, enq_evs);
      var l2_err_handler := g.curr_err_handler;
      
      var need_async_inv := (enq_evs.c1<>0) or not o_const;
      begin
        // If ExecuteEnqFunc (and so prev_qr.GetRes) is insta called
        // There is no point in creating another event for actions
        var start_ev := if not need_async_inv then
          l.prev_ev else l.AttachInvokeActions(g);
        
        if start_ev.count=0 then
          {$ifdef DEBUG}enq_evs.FakeAdd{$endif} else
        if not o_const then
          enq_evs.AddL1(start_ev) else
          enq_evs.AddL2(start_ev);
        
      end;
      var (ev_l1, ev_l2) := enq_evs.MakeLists;
      
      // When need_async_inv, cq needs to be secured for thread safety
      // Otherwise, next command can be written before current one
      //TODO Created even if l1_err_handler had errors
      var cq := g.GetCQ(need_async_inv);
      {$ifdef QueueDebug}
      QueueDebug.Add(cq, TypeName(q));
      {$endif QueueDebug}
      
      {$ifdef DEBUG}
      var err_test_reason := $'[{q.GetHashCode}]:{TypeName(q)}.ExecuteEnqFunc';
      l1_err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      if not need_async_inv then
      begin
        l.prev_delegate.Invoke(g.c);
        Result := ExecuteEnqFunc(get_o(), cq, ev_l2, enq_f, l1_err_handler,l2_err_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}{$ifdef EventDebug}, q{$endif});
      end else
      begin
        var res_ev := new UserEvent(g.cl_c
          {$ifdef EventDebug}, $'{TypeName(q)}, temp for nested AttachCallback: [{ev_l1.evs.JoinToString}], then [{ev_l2.evs?.JoinToString}]'{$endif}
        );
        
        ev_l1.MultiAttachCallback(()->
        begin
          var (enq_ev, enq_act) := ExecuteEnqFunc(get_o(), cq, ev_l2, enq_f, l1_err_handler,l2_err_handler{$ifdef DEBUG}, err_test_reason{$endif DEBUG}{$ifdef EventDebug}, q{$endif});
          OpenCLABCInternalException.RaiseIfError( cl.Flush(cq) );
          enq_ev.MultiAttachCallback(()->
          begin
            if enq_act<>nil then enq_act(g.c);
            g.ReturnCQ(cq);
            res_ev.SetComplete(l2_err_handler.HadError);
          end{$ifdef EventDebug}, $'propagating Enq ev of {TypeName(q)} to res_ev: {res_ev.uev}'{$endif});
        end{$ifdef EventDebug}, $'calling async Enq of {TypeName(q)}'{$endif});
        
        Result := new EnqRes(res_ev, nil);
      end;
      
    end;
    
  end;
  
{$endregion Core}

{$region GPUCommand}

type
  EnqueueableGPUCommand<T> = abstract class(GPUCommand<T>)
    
    protected function TryPreCall(q: CommandQueue<T>): boolean; override := false;
    
    protected function ExpectedEnqCount: integer; abstract;
    
    protected function InvokeParams(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ParamInvRes<T>; abstract;
    protected procedure ProcessError(ec: ErrorCode);
    begin
      var TODO := 0; //TODO abstract
    end;
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<T>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var get_o: ()->T;
      var o_const: boolean;
      if dep_ok then
      begin
        get_o := ()->inp.expected_const_res;
        o_const := true;
      end else
      begin
        var prev_qr := inp.InvokeToAny(g, l);
        l := prev_qr.TakeBaseOut;
        get_o := prev_qr.GetResDirect;
        o_const := prev_qr.IsConst;
      end;
      
      var (enq_ev, enq_act) := EnqueueableCore.Invoke(
        self.ExpectedEnqCount, o_const, get_o, g, l,
        InvokeParams, ProcessError
        {$ifdef DEBUG},self{$endif}
      );
      
      Result := new QueueResNil(enq_ev);
      if enq_act<>nil then Result.AddAction(enq_act);
    end;
    
  end;
  
{$endregion GPUCommand}

{$region ExecCommand}

type
  ExecCommandCLKernelCacheEntry = record
    k: CLKernel;
    cache: CLKernelArgCache;
    last_use: DateTime;
    
    procedure Bump := last_use := DateTime.Now;
    
    procedure TryRelease({$ifdef ExecDebug}command: object{$endif}) := if k<>nil then
    begin
      {$ifdef ExecDebug}
      ExecDebug.RegisterExecCacheTry(command, false, $'For {k} returned {cache.ntv}');
      {$endif ExecDebug}
      cache.Release(k);
    end;
    procedure Replace(k: CLKernel; cache: CLKernelArgCache{$ifdef ExecDebug}; command: object{$endif});
    begin
      self.TryRelease({$ifdef ExecDebug}command{$endif});
      self.k := k;
      self.cache := cache;
      self.Bump;
    end;
    
  end;
  ExecCommandCLKernelCache = record
    private const cache_size = 16;
    
    private data := new ExecCommandCLKernelCacheEntry[cache_size];
    private data_ind := new Dictionary<CLKernel, integer>(cache_size);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function GetArgCache(k: CLKernel; make_new: CLKernel->CLKernelArgCache{$ifdef ExecDebug}; command: object{$endif}): CLKernelArgCache;
    begin
      lock data do
      begin
        
        var ind := 0;
        if data_ind.TryGetValue(k, ind) then
        begin
          data[ind].Bump;
          Result := data[ind].cache;
          {$ifdef ExecDebug}
          ExecDebug.RegisterExecCacheTry(command, false, $'For {k} taken {Result.ntv}');
          {$endif ExecDebug}
        end else
        
        begin
          for var i := 1 to cache_size-1 do
            if data[i].last_use<data[ind].last_use then
              ind := i;
          Result := make_new(k);
          data[ind].Replace(k, Result{$ifdef ExecDebug}, command{$endif});
          data_ind[k] := ind;
          {$ifdef ExecDebug}
          ExecDebug.RegisterExecCacheTry(command, true, $'For {k} made {Result.ntv}');
          {$endif ExecDebug}
        end;
        
      end;
    end;
    
    public procedure Release({$ifdef ExecDebug}command: object{$endif}) :=
    for var i := 0 to cache_size-1 do
      data[i].TryRelease({$ifdef ExecDebug}command{$endif});
    
  end;
  
  EnqueueableExecCommand = abstract class(GPUCommand<CLKernel>)
    private args: array of CLKernelArg;
    private const_args_setters: array of CLKernelArgSetter;
    private args_c, args_non_const_c: integer;
    
    protected constructor(args: array of CLKernelArg);
    begin
      args := args.ToArray;
      self.args := args;
      self.const_args_setters := new CLKernelArgSetter[args.Length];
      self.args_c := args.Length;
      self.args_non_const_c := args.Length;
      for var i := 0 to args_c-1 do
      begin
        var setter := args[i].TryGetConstSetter;
        if setter=nil then continue;
        args_non_const_c -= 1;
        const_args_setters[i] := setter;
        args[i] := nil;
      end;
      if args_non_const_c=0 then
        self.args := nil else
      if args_non_const_c=args_c then
        self.const_args_setters := nil;
    end;
    private constructor := raise new OpenCLABCInternalException;
    
    private procedure ApplyConstArgsTo(arg_cache: CLKernelArgCache);
    begin
      if const_args_setters=nil then exit;
      for var i := 0 to args_c-1 do
      begin
        if const_args_setters[i]=nil then continue;
        const_args_setters[i].Apply(i, arg_cache);
      end;
    end;
    
    private k_cache := new ExecCommandCLKernelCache;
    private function GetArgCache(k: CLKernel) :=
    k_cache.GetArgCache(k, k->
    begin
      Result := new CLKernelArgCache(k, self.args_c);
      ApplyConstArgsTo(Result);
    end{$ifdef ExecDebug}, self{$endif});
    
    protected function TryPreCall(q: CommandQueue<CLKernel>): boolean; override;
    begin
      Result := false;
      if q.const_res_dep=nil then exit;
      GetArgCache(q.expected_const_res); // Auto calls ApplyConstArgsTo
    end;
    
    protected function ExpectedEnqCount: integer; abstract;
    
    protected function InvokeParams(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList; get_arg_cache: ()->CLKernelArgCache): ParamInvRes<cl_kernel>; abstract;
    protected procedure ProcessError(ec: ErrorCode);
    begin
      var TODO := 0; //TODO abstract
    end;
    
    {$region DerCommon}
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeArgs(inv: CLTaskBranchInvoker; enq_evs: DoubleEventListList): array of CLKernelArgSetter;
    begin
      if args=nil then exit;
      Result := new CLKernelArgSetter[self.args_c];
      for var i := 0 to self.args_c-1 do
      begin
        if args[i]=nil then continue;
        var (arg_setter, arg_ev) := self.args[i].Invoke(inv);
        Result[i] := arg_setter;
        
        if arg_ev.count=0 then
          {$ifdef DEBUG}enq_evs.FakeAdd{$endif} else
        if not arg_setter.IsConst then
          enq_evs.AddL1(arg_ev) else
          enq_evs.AddL2(arg_ev);
      end;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure ApplySetters(cache: CLKernelArgCache; setters: array of CLKernelArgSetter);
    begin
      if setters=nil then exit;
      for var i := 0 to self.args_c-1 do
      begin
        if setters[i]=nil then continue;
        setters[i].Apply(i, cache);
      end;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure KeepArgsGCAlive := GC.KeepAlive(self.args);
    
    {$endregion DerCommon}
    
    protected function Invoke(dep_ok: boolean; inp: CommandQueue<CLKernel>; g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      var get_k: ()->CLKernel;
      var k_const: boolean;
      if dep_ok then
      begin
        get_k := ()->inp.expected_const_res;
        k_const := true;
      end else
      begin
        var prev_qr := inp.InvokeToAny(g, l);
        l := prev_qr.TakeBaseOut;
        get_k := prev_qr.GetResDirect;
        k_const := prev_qr.IsConst;
      end;
      
      var get_k_ntv: ()->cl_kernel;
      var arg_cache := default(CLKernelArgCache);
      if k_const then
      begin
        arg_cache := self.GetArgCache(get_k);
        get_k_ntv := ()->arg_cache.ntv;
      end else
        get_k_ntv := ()->
        begin
          arg_cache := self.GetArgCache(get_k);
          Result := arg_cache.ntv;
        end;
      
      //TODO Надо ли "()->" перед arg_cache? Разница в том что:
      // - Без "()->" его будет читать прямо перед вызовом InvokeParams
      // - А сейчас его считает аж в EnqFunc<cl_kernel>
      var (enq_ev, enq_act) := EnqueueableCore.Invoke(
        self.ExpectedEnqCount+args_non_const_c, k_const, get_k_ntv, g, l,
        (enq_c, o_const, g, enq_evs)->
          InvokeParams(enq_c, o_const, g, enq_evs, ()->arg_cache),
        ProcessError
        {$ifdef DEBUG},self{$endif}
      );
      
      Result := new QueueResNil(enq_ev);
      if enq_act<>nil then Result.AddAction(enq_act);
    end;
    
    protected procedure Finalize; override :=
    k_cache.Release({$ifdef ExecDebug}self{$endif});
    
  end;
  
{$endregion ExecCommand}

{$region GetCommand}

type
  EnqueueableGetCommand<TObj, TRes> = abstract class(CommandQueue<TRes>)
    protected prev_commands: GPUCommandContainer<TObj>;
    
    public constructor(prev_commands: GPUCommandContainer<TObj>) :=
    self.prev_commands := prev_commands;
    
    protected function ExpectedEnqCount: integer; abstract;
    
    protected function InvokeParams(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList; own_qr: QueueRes<TRes>): ParamInvRes<TObj>; abstract;
    protected procedure ProcessError(ec: ErrorCode);
    begin
      var TODO := 0; //TODO abstract
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>): TR; where TR: QueueRes<TRes>;
    begin
      Result := qr_factory.MakeDelayed(qr->
      begin
        var prev_qr := prev_commands.InvokeToAny(g, l);
        var inp_const := prev_qr.IsConst;
        l := prev_qr.TakeBaseOut;
        
        var (enq_ev, enq_act) := EnqueueableCore.Invoke(
          self.ExpectedEnqCount, inp_const, prev_qr.GetResDirect, g, l,
          (enq_c, o_const, g, enq_evs)->
            InvokeParams(enq_c, o_const, g, enq_evs, qr),
          ProcessError
          {$ifdef DEBUG},self{$endif}
        );
        
        Result := new CLTaskLocalData(enq_ev);
        if enq_act<>nil then Result.prev_delegate.AddAction(enq_act);
      end);
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override := new QueueResNil(l);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <TRes>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<TRes>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
  //TODO Через InvokeParams должно передаваться own_qr: QueueResPtr<TRes>
  // - Для этого надо разделить на GetVal и GetPtr комманды
  EnqueueableGetPtrCommand<TObj, TRes> = abstract class(EnqueueableGetCommand<TObj,TRes>)
    
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<TRes>; override := InvokeToPtr(g,l);
    
  end;
  
{$endregion GetCommand}

{$region CLKernel}

{$region Implicit}

{%ContainerMethods\CLKernel.Exec\Implicit.Implementation!ContainerExecMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLKernel.Exec\Explicit.Implementation!ContainerExecMethods.pas%}

{$endregion Explicit}

{$endregion CLKernel}

{$region CLMemory}

{$region Implicit}

{%ContainerMethods\CLMemory\Implicit.Implementation!ContainerOtherMethods.pas%}

{%ContainerMethods\CLMemory.Get\Implicit.Implementation!ContainerGetMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLMemory\Explicit.Implementation!ContainerOtherMethods.pas%}

{%ContainerMethods\CLMemory.Get\Explicit.Implementation!ContainerGetMethods.pas%}

{$endregion Explicit}

{$endregion CLMemory}

{$region CLValue}

{$region Implicit}

{%ContainerMethods\CLValue\Implicit.Implementation!ContainerOtherMethods.pas%}

{%ContainerMethods\CLValue.Get\Implicit.Implementation!ContainerGetMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLValue\Explicit.Implementation!ContainerOtherMethods.pas%}

{%ContainerMethods\CLValue.Get\Explicit.Implementation!ContainerGetMethods.pas%}

{$endregion Explicit}

{$endregion CLValue}

{$region CLArray}

{$region Implicit}

{%ContainerMethods\CLArray\Implicit.Implementation!ContainerOtherMethods.pas%}

{%ContainerMethods\CLArray.Get\Implicit.Implementation!ContainerGetMethods.pas%}

{$endregion Implicit}

{$region Explicit}

{%ContainerMethods\CLArray\Explicit.Implementation!ContainerOtherMethods.pas%}

{%ContainerMethods\CLArray.Get\Explicit.Implementation!ContainerGetMethods.pas%}

{$endregion Explicit}

{$endregion CLArray}

{$endregion Enqueueable's}

{$region Global subprograms}

{$region CQ}

function CQNil := ConstQueueNil.Instance;

function CQ<T>(o: T) := CommandQueue&<T>(o);

{$endregion CQ}

{$region HFQ/HPQ}

{$region Common} type
  
  {$region Func}
  
  ISimpleFunc0Container<T> = interface(ISimpleDelegateContainer)
    
    function Invoke(c: CLContext): T;
    
  end;
  
  SimpleFunc0Container<T> = record(ISimpleFunc0Container<T>)
    private d: ()->T;
    
    public static function operator implicit(d: ()->T): SimpleFunc0Container<T>;
    begin
      Result.d := d;
    end;
    
    public function Invoke(c: CLContext) := d();
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  SimpleFunc0ContainerC<T> = record(ISimpleFunc0Container<T>)
    private d: CLContext->T;
    
    public static function operator implicit(d: CLContext->T): SimpleFunc0ContainerC<T>;
    begin
      Result.d := d;
    end;
    
    public function Invoke(c: CLContext) := d(c);
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  
  CommandQueueHostFuncBase<T, TFunc> = abstract class(CommandQueue<T>)
  where TFunc: ISimpleFunc0Container<T>;
    protected f: TFunc;
    
    public constructor(f: TFunc) := self.f := f;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := exit;
    
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function InvokeFunc(err_handler: CLTaskErrHandler; c: CLContext{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG}): T;
    begin
      if not err_handler.HadError then
      try
        Result := f.Invoke(c);
      except
        on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
      end;
      {$ifdef DEBUG}
      err_handler.EndMaybeError(err_test_reason);
      {$endif DEBUG}
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      f.ToStringB(sb);
      sb += #10;
    end;
    
  end;
  
  {$endregion Func}
  
  {$region Proc}
  
  ISimpleProc0Container = interface(ISimpleDelegateContainer)
    
    procedure Invoke(c: CLContext);
    
  end;
  
  SimpleProc0Container = record(ISimpleProc0Container)
    private d: ()->();
    
    public static function operator implicit(d: ()->()): SimpleProc0Container;
    begin
      Result.d := d;
    end;
    
    public procedure Invoke(c: CLContext) := d();
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  SimpleProc0ContainerC = record(ISimpleProc0Container)
    private d: CLContext->();
    
    public static function operator implicit(d: CLContext->()): SimpleProc0ContainerC;
    begin
      Result.d := d;
    end;
    
    public procedure Invoke(c: CLContext) := d(c);
    
    public procedure ToStringB(sb: StringBuilder) :=
    CommandQueueBase.ToStringWriteDelegate(sb, d);
    
  end;
  
  CommandQueueHostProcBase<TProc> = abstract class(CommandQueueNil)
  where TProc: ISimpleProc0Container;
    protected p: TProc;
    
    public constructor(p: TProc) := self.p := p;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_mu: HashSet<IMultiusableCommandQueue>); override := exit;
    
    protected [MethodImpl(MethodImplOptions.AggressiveInlining)]
    procedure InvokeProc(err_handler: CLTaskErrHandler; c: CLContext{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG});
    begin
      if not err_handler.HadError then
      try
        p.Invoke(c);
      except
        on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
      end;
      {$ifdef DEBUG}
      err_handler.EndMaybeError(err_test_reason);
      {$endif DEBUG}
    end;
    
    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;
    begin
      sb += ': ';
      p.ToStringB(sb);
      sb += #10;
    end;
    
  end;
  
  {$endregion Proc}
  
{$endregion Common}

{$region Func}

type
  CommandQueueHostQuickFunc<T, TFunc> = sealed class(CommandQueueHostFuncBase<T, TFunc>)
  where TFunc: ISimpleFunc0Container<T>;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>): TR; where TR: IQueueRes;
    begin
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.InvokeFunc';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      Result := if l.ShouldInstaCallAction then
        qr_factory.MakeConst(l,
          InvokeFunc(err_handler, g.c{$ifdef DEBUG}, err_test_reason{$endif DEBUG})
        ) else
        qr_factory.MakeDelayed(l, qr->c->qr.SetRes(
          InvokeFunc(err_handler, g.c{$ifdef DEBUG}, err_test_reason{$endif DEBUG})
        ));
      
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := Invoke(g, l, qr_nil_factory);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, qr_val_factory);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory);
    
  end;
  
  CommandQueueHostThreadedFunc<T, TFunc> = sealed class(CommandQueueHostFuncBase<T, TFunc>)
  where TFunc: ISimpleFunc0Container<T>;
    
    private function MakeNilBody    (prev_d: QueueResComplDelegateData; c: CLContext; err_handler: CLTaskErrHandler; own_qr: QueueResNil{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG}): Action := ()->
    begin
      prev_d.Invoke(c);
      InvokeFunc(err_handler, c{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
    end;
    private function MakeResBody<TR>(prev_d: QueueResComplDelegateData; c: CLContext; err_handler: CLTaskErrHandler; own_qr: TR{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG}): Action; where TR: QueueRes<T>;
    begin
      Result := ()->
      begin
        prev_d.Invoke(c);
        own_qr.SetRes(
          InvokeFunc(err_handler, c{$ifdef DEBUG}, err_test_reason{$endif DEBUG})
        );
      end;
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<T,TR>; make_body: (QueueResComplDelegateData,CLContext,CLTaskErrHandler,TR{$ifdef DEBUG},string{$endif DEBUG})->Action): TR; where TR: IQueueRes;
    begin
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.InvokeFunc';
      g.curr_err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      Result := qr_factory.MakeDelayed(qr->new CLTaskLocalData(
        UserEvent.StartWorkThread(l.prev_ev,
          make_body(l.prev_delegate, g.c, g.curr_err_handler, qr{$ifdef DEBUG}, err_test_reason{$endif DEBUG}), g
          {$ifdef EventDebug}, $'body of {TypeName(self)}'{$endif}
        )
      ));
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil;    override := Invoke(g, l, qr_nil_factory, MakeNilBody);
    protected function InvokeToAny(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes   <T>; override := Invoke(g, l, qr_val_factory, MakeResBody&<QueueResVal<T>>);
    protected function InvokeToPtr(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResPtr<T>; override := Invoke(g, l, qr_ptr_factory, MakeResBody&<QueueResPtr<T>>);
    
  end;
  
function HFQ<T,TFunc>(f: TFunc; need_own_thread: boolean): CommandQueue<T>; where TFunc: ISimpleFunc0Container<T>;
begin
  if need_own_thread then
    Result := new CommandQueueHostThreadedFunc<T, TFunc>(f) else
    Result := new CommandQueueHostQuickFunc   <T, TFunc>(f);
end;

function HFQ<T>(f: ()->T; need_own_thread: boolean) :=
HFQ&<T, SimpleFunc0Container <T>>(f, need_own_thread);
function HFQ<T>(f: CLContext->T; need_own_thread: boolean) :=
HFQ&<T, SimpleFunc0ContainerC<T>>(f, need_own_thread);

{$endregion Func}

{$region Proc}

type
  CommandQueueHostQuickProc<TProc> = sealed class(CommandQueueHostProcBase<TProc>)
  where TProc: ISimpleProc0Container;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      Result := new QueueResNil(l);
      var err_handler := g.curr_err_handler;
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.InvokeProc';
      err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      
      if l.ShouldInstaCallAction then
        InvokeProc(err_handler, g.c{$ifdef DEBUG}, err_test_reason{$endif DEBUG}) else
        Result.AddAction(c->InvokeProc(err_handler, c{$ifdef DEBUG}, err_test_reason{$endif DEBUG}));
      
    end;
    
  end;
  
  CommandQueueHostThreadedProc<TProc> = sealed class(CommandQueueHostProcBase<TProc>)
  where TProc: ISimpleProc0Container;
    
    private function MakeBody(prev_d: QueueResComplDelegateData; err_handler: CLTaskErrHandler; c: CLContext{$ifdef DEBUG}; err_test_reason: string{$endif DEBUG}): Action := ()->
    begin
      prev_d.Invoke(c);
      InvokeProc(err_handler, c{$ifdef DEBUG}, err_test_reason{$endif DEBUG});
    end;
    
    protected function InvokeToNil(g: CLTaskGlobalData; l: CLTaskLocalData): QueueResNil; override;
    begin
      {$ifdef DEBUG}
      var err_test_reason := $'[{self.GetHashCode}]:{TypeName(self)}.InvokeProc';
      g.curr_err_handler.AddMaybeError(err_test_reason);
      {$endif DEBUG}
      Result := new QueueResNil(UserEvent.StartWorkThread(
        l.prev_ev, MakeBody(l.prev_delegate, g.curr_err_handler, g.c{$ifdef DEBUG}, err_test_reason{$endif DEBUG}), g
        {$ifdef EventDebug}, $'body of {TypeName(self)}'{$endif}
      ));
    end;
    
  end;
  
function HPQ<TProc>(p: TProc; need_own_thread: boolean): CommandQueueNil; where TProc: ISimpleProc0Container;
begin
  if need_own_thread then
    Result := new CommandQueueHostThreadedProc<TProc>(p) else
    Result := new CommandQueueHostQuickProc   <TProc>(p);
end;

function HPQ(p: ()->(); need_own_thread: boolean) :=
HPQ&<SimpleProc0Container >(p, need_own_thread);
function HPQ(p: CLContext->(); need_own_thread: boolean) :=
HPQ&<SimpleProc0ContainerC>(p, need_own_thread);

{$endregion Proc}

{$endregion HFQ/HPQ}

{$region CombineQueue's}

{%CombineQueues\Implementation!CombineQueues.pas%}

{$endregion CombineQueue's}

{$endregion Global subprograms}

{$region Properties}

{$region Base}

type
  NtvPropertiesBase<TNtv, TInfo> = abstract class
    protected ntv: TNtv;
    public constructor(ntv: TNtv) := self.ntv := ntv;
    private constructor := raise new OpenCLABCInternalException;
    
    protected procedure GetSizeImpl(id: TInfo; var sz: UIntPtr); abstract;
    protected procedure GetValImpl(id: TInfo; sz: UIntPtr; var res: byte); abstract;
    
    protected function GetSize(id: TInfo): UIntPtr;
    begin GetSizeImpl(id, Result); end;
    
    protected procedure FillPtr(id: TInfo; sz: UIntPtr; ptr: IntPtr) :=
    GetValImpl(id, sz, PByte(pointer(ptr))^);
    protected procedure FillVal<T>(id: TInfo; sz: UIntPtr; var res: T) :=
    GetValImpl(id, sz, PByte(pointer(@res))^);
    
    protected function GetVal<T>(id: TInfo): T; where T: record;
    begin
      FillVal(id, new UIntPtr(Marshal.SizeOf(default(T))), Result);
    end;
    protected function GetValArr<T>(id: TInfo): array of T; where T: record;
    begin
      var sz := GetSize(id);
      Result := new T[uint64(sz) div Marshal.SizeOf(default(T))];
      
      if Result.Length<>0 then
        FillVal(id, sz, Result[0]);
      
    end;
    
    private function GetString(id: TInfo): string;
    begin
      var sz := GetSize(id);
      
      var str_ptr := Marshal.AllocHGlobal(IntPtr(pointer(sz)));
      try
        FillPtr(id, sz, str_ptr);
        Result := Marshal.PtrToStringAnsi(str_ptr);
      finally
        Marshal.FreeHGlobal(str_ptr);
      end;
      
    end;
    
  end;
  
{$endregion Base}

{%WrapperProperties\Implementation!WrapperProperties.pas%}

{$endregion Properties}

{$region Wrappers}

{$region CLDevice}

static function CLDevice.FromNative(ntv: cl_device_id): CLDevice;
begin
  
  var parent: cl_device_id;
  OpenCLABCInternalException.RaiseIfError(
    cl.GetDeviceInfo(ntv, DeviceInfo.DEVICE_PARENT_DEVICE, new UIntPtr(cl_device_id.Size), parent, IntPtr.Zero)
  );
  
  if parent=cl_device_id.Zero then
    Result := new CLDevice(ntv) else
    Result := new CLSubDevice(parent, ntv);
  
end;

{$endregion CLDevice}

{$region CLContext}

static procedure CLContext.GenerateAndCheckDefault(test_size: integer; test_max_seconds: real);
begin
  if Interlocked.CompareExchange(default_was_inited, 1, 0)<>0 then
    raise new System.InvalidOperationException($'%CLContext:GenerateAndCheckDefault:NotFirst%');
  
  var test_prog := 'kernel void k(global int* v) { v[get_global_id(0)]++; }';
  var test_max_time := TimeSpan.FromSeconds(test_max_seconds);
  
  var Q_Test: CommandQueue<boolean>;
  var P_Arr := new ParameterQueue<CLArray<integer>>('A');
  var P_Prog := new ParameterQueue<CLProgramCode>('Prog');
  begin
    var rng := new Random;
    var test_arr := ArrGen(test_size, i->rng.Next);
    {%> Q_Test :=%}
    {%>   P_Prog.ThenConvert(p->p['k'], false, true).MakeCCQ%}
    {%>     .ThenExec1(test_size, P_Arr.MakeCCQ%}
    {%>       .ThenWriteArray(test_arr)%}
    {%>     ) +%}
    {%>   P_Arr.MakeCCQ%}
    {%>     .ThenGetArray%}
    {%>     .ThenConvert(test_res->%}
    {%>       test_res.Zip(test_arr, (a,b)->a=b+1).All(r->r), false%}
    {%>     )!!}test_arr := test_arr{%};
  end;
  
  var c := CLPlatform.All.SelectMany(pl->
  begin
    var dvcs := CLDevice.GetAllFor(pl, CLDeviceType.DEVICE_TYPE_ALL).ToList;
    
    System.Threading.Tasks.Parallel.For(0,dvcs.Count, i->
    begin
      var del := true;
      
      var c := new CLContext(dvcs[i]);
      var S_Arr := P_Arr.NewSetter(new CLArray<integer>(c, test_size));
      var S_Prog := P_Prog.NewSetter(new CLProgramCode(test_prog, c));
      
      var thr := new Thread(()->
      begin
        del := not c.SyncInvoke(Q_Test, S_Arr, S_Prog);
      end);
      thr.IsBackground := true;
      thr.Start;
      
      if not thr.Join(test_max_time) then
        thr.Abort;
      
      if del then dvcs[i] := nil;
    end);
    dvcs.RemoveAll(d->d=nil);
    
    Result := if dvcs.Count=0 then
      System.Linq.Enumerable.Empty&<(CLContext,TimeSpan)> else
      |true,false|.Cartesian(dvcs.Count)
      .Select(choise->
      begin
        Result := new List<CLDevice>(dvcs.Count);
        for var i := 0 to dvcs.Count-1 do
          if choise[i] then Result += dvcs[i];
      end)
      .Where(l_dvcs->l_dvcs.Count<>0)
      .Select(l_dvcs->
      begin
        var c := new CLContext(l_dvcs, l_dvcs[0]);
        
        var sw := Stopwatch.StartNew;
        c.SyncInvoke(Q_Test.DiscardResult,
          P_Arr.NewSetter(new CLArray<integer>(c, test_size)),
          P_Prog.NewSetter(new CLProgramCode(test_prog, c))
        );
        sw.Stop;
        
        Result := (c, sw.Elapsed);
      end);
  end)
  .DefaultIfEmpty((default(CLContext),TimeSpan.Zero))
  .MinBy(t->t[1])[0];
  
  Interlocked.CompareExchange(_default, c, nil);
end;

static function CLContext.LoadTestContext: CLContext;
begin
  Result := nil;
  
  var fname :=
    SeqWhile(GetCurrentDir, System.IO.Path.GetDirectoryName, dir->dir<>nil)
    .Select(dir->System.IO.Path.Combine(dir, 'TestContext.dat'))
    .FirstOrDefault(FileExists);
  if fname=nil then
  begin
    $'Pregenerated context not found'.Println;
    exit;
  end;
  
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  try
    var pl_name := br.ReadString;
    if pl_name.Length=0 then
    begin
      $'Pregenerated context was empty'.Println;
      exit;
    end;
    
    var pl := CLPlatform.All.SingleOrDefault(pl->{%>pl.Properties.Name!!}nil{%}=pl_name);
    if pl=nil then
    begin
      var all_pl_names := CLPlatform.All.Select(pl->$'['+{%>pl.Properties.Name!!}nil{%}+$']').JoinToString(', ');
      raise new InvalidOperationException($'No platform with name [{pl_name}], only: {all_pl_names}');
    end;
    var dvcs := CLDevice.GetAllFor(pl, CLDeviceType.DEVICE_TYPE_ALL).ToDictionary(dvc->{%>dvc.Properties.Name!!}default(string){%});
    Result := new CLContext(ArrGen(br.ReadInt32, i->
    begin
      Result := default(CLDevice);
      var dvc_name := br.ReadString;
      if dvcs.TryGetValue(dvc_name, Result) then exit;
      var all_dvc_names := dvcs.Keys.Select(key->$'[{key}]').JoinToString(', ');
      raise new InvalidOperationException($'No device with name [{dvc_name}], only: {all_dvc_names}');
    end));
    
  finally
    br.Close;
  end;
  
end;

{$endregion CLContext}

{$region CLProgramCompOptions}

procedure CLProgramCompOptions.LowerVersionToSupported;
begin
  var max_v := Version;
  
  foreach var d in BuildContext.AllDevices do
  begin
    var v_str := {%>d.Properties.OpenclCVersion!!}default(string){%};
    var v_str_beg := 'OpenCL C ';
    if not v_str.StartsWith(v_str_beg) then raise new System.NotSupportedException;
    var v_spl := v_str.Substring(v_str_beg.Length).Split(|'.'|, 2);
    var v := (v_spl[0].ToInteger, v_spl[1].ToInteger);
    if max_v<>nil then
      case Sign(v[0]-max_v[0]) of
        1: continue;
        0:
        case Sign(v[1]-max_v[1]) of
          1: continue;
          0: ;
        end;
      end;
    max_v := v; // if max_v=nil or v<=max_v
  end;
  
  Version := max_v;
end;

{$endregion CLProgramCompOptions}

{$region CLKernel}

type
  CLKernelNtvList = record
    private const resize_limit_up = 1/sqrt(2);
    private const resize_limit_down = resize_limit_up/2;
    private const min_size_down = 16;
    
    private ntvs_lock := new object;
    private ntvs: array of record
      k: cl_kernel;
      used: boolean;
    end;
    private ntvs_used := 0;
    private unused_search_shift := 0;
    
    public constructor :=
    SetLength(ntvs, 1);
    
    private function MakeMask: integer;
    begin
      Result := ntvs.Length-1;
      {$ifdef DEBUG}
      if (Result and ntvs.Length) <> 0 then raise new OpenCLABCInternalException($'ntvs.Length was {ntvs.Length}, which is not a power of 2');
      {$endif DEBUG}
    end;
    
    private procedure AddExisting(k: cl_kernel; used: boolean; mask: integer);
    begin
      var search_shift := k.val.ToInt32;
      for var i := 0 to mask do
      begin
        var ind := (i+search_shift) and mask;
        if ntvs[ind].k=cl_kernel.Zero then
        begin
          ntvs[ind].k := k;
          ntvs[ind].used := used;
          ntvs_used += Ord(used);
          exit;
        end;
      end;
      raise new OpenCLABCInternalException($'No space to add, {ntvs_used}/{ntvs.Length} filled');
    end;
    public procedure AddExisting(k: cl_kernel) :=
    lock ntvs_lock do
    begin
      TryResizeUp;
      AddExisting(k, false, MakeMask);
    end;
    
    private static procedure SetSz<T>(var a: array of T; sz: integer) := a := new T[sz];
    private procedure ResizeKeepingUsed(sz: integer);
    begin
      var prev_ntvs := ntvs;
      SetSz(self.ntvs, sz);
      self.ntvs_used := 0;
      self.unused_search_shift := 0;
      
      var mask := MakeMask;
      var added := 0;
      
      foreach var info in prev_ntvs do
        if info.used then
        begin
          AddExisting(info.k, true, mask);
          added += 1;
        end else
        if info.k<>cl_kernel.Zero then
          OpenCLABCInternalException.RaiseIfError(
            cl.ReleaseKernel(info.k)
          );
      
    end;
    private procedure TryResizeUp :=
    if ntvs_used > ntvs.Length*resize_limit_up then
      ResizeKeepingUsed(ntvs.Length shl 1);
    private procedure TryResizeDown :=
    if ntvs_used < ntvs.Length*resize_limit_down then
      ResizeKeepingUsed(ntvs.Length shr 1);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function TakeOrMake(make_new: ()->cl_kernel): cl_kernel;
    begin
      lock ntvs_lock do
      begin
        TryResizeUp;
        var mask := MakeMask;
        var search_shift := self.unused_search_shift;
        for var i := 0 to mask do
        begin
          var ind := (i+search_shift) and mask;
          if ntvs[ind].k=cl_kernel.Zero then
          begin
            Result := make_new;
            ntvs[ind].k := Result;
          end else
          if not ntvs[ind].used then
            Result := ntvs[ind].k else
            continue;
          ntvs[ind].used := true;
          ntvs_used += 1;
          self.unused_search_shift := ind;
          exit;
        end;
        raise new OpenCLABCInternalException($'No unused or empty found, {ntvs_used}/{ntvs.Length} filled');
      end;
    end;
    
    public procedure Return(k: cl_kernel) :=
    lock ntvs_lock do
    begin
      var mask := MakeMask;
      var search_shift := k.val.ToInt32;
      for var i := 0 to mask do
      begin
        var ind := (i+search_shift) and mask;
        if ntvs[ind].k=k then
        begin
          {$ifdef DEBUG}
          if not ntvs[ind].used then raise new OpenCLABCInternalException($'Return of not taken ntv');
          {$endif DEBUG}
          ntvs[ind].used := false;
          ntvs_used -= 1;
          if ntvs.Length > min_size_down then
            TryResizeDown;
          exit;
        end;
      end;
      raise new OpenCLABCInternalException($'Return of unknown ntv');
    end;
    
  end;
  
  CLKernel = partial class
    
    private ntvs := new CLKernelNtvList;
    
    protected procedure Finalize; override :=
    ntvs.ResizeKeepingUsed(ntvs.ntvs.Length);
    
  end;
  
function CLKernel.AllocNative :=
ntvs.TakeOrMake(()->
begin
  var ec: ErrorCode;
  Result := cl.CreateKernel(code.ntv, k_name, ec);
  OpenCLABCInternalException.RaiseIfError(ec);
end);

procedure CLKernel.ReleaseNative(ntv: cl_kernel) := ntvs.Return(ntv);

procedure CLKernel.AddExistingNative(ntv: cl_kernel) := ntvs.AddExisting(ntv);

{$endregion CLKernel}

{$region CLMemory}

static function CLMemory.FromNative(ntv: cl_mem): CLMemory;
begin
  var t: MemObjectType;
  OpenCLABCInternalException.RaiseIfError(
    cl.GetMemObjectInfo(ntv, MemInfo.MEM_TYPE, new UIntPtr(sizeof(MemObjectType)), t, IntPtr.Zero)
  );
  
  if t<>MemObjectType.MEM_OBJECT_BUFFER then
    raise new ArgumentException($'%Err:CLMemory:WrongNtvType%');
  
  var parent: cl_mem;
  OpenCLABCInternalException.RaiseIfError(
    cl.GetMemObjectInfo(ntv, MemInfo.MEM_ASSOCIATED_MEMOBJECT, new UIntPtr(cl_mem.Size), parent, IntPtr.Zero)
  );
  
  if parent=cl_mem.Zero then
    Result := new CLMemory(ntv) else
    Result := new CLMemorySubSegment(parent, ntv);
  
end;

{$endregion CLMemory}

{$region CLArray}

function CLArray<T>.GetItemProp(ind: integer): T :=
{%>GetValue(ind)!!} default(T) {%};
procedure CLArray<T>.SetItemProp(ind: integer; value: T) :=
{%>WriteValue(value, ind)!!} exit() {%};

function CLArray<T>.GetSliceProp(range: IntRange): array of T;
begin
  Result := new T[range.High-range.Low+1];
  {%>ReadArray(Result, 0,Result.Length, range.Low);%}
end;
procedure CLArray<T>.SetSliceProp(range: IntRange; value: array of T) :=
{%>WriteArray(value, range.Low, range.High-range.Low+1, 0)!!} exit() {%};

{$endregion CLArray}

{$endregion Wrappers}

{$ifdef ForceMaxDebug}
initialization
finalization
  
  {$ifdef EventDebug}
  EventDebug.FinallyReport;
  {$endif EventDebug}
  
  {$ifdef QueueDebug}
  QueueDebug.FinallyReport;
  {$endif QueueDebug}
  
  {$ifdef WaitDebug}
  foreach var whd: WaitHandlerDirect in WaitDebug.WaitActions.Keys.OfType&<WaitHandlerDirect> do
    if whd.reserved<>0 then
      raise new OpenCLABCInternalException($'WaitHandler.reserved in finalization was <>0');
  WaitDebug.FinallyReport;
  {$endif WaitDebug}
  
  {$ifdef ExecDebug}
  ExecDebug.FinallyReport;
  {$endif ExecDebug}
  
  if QueueResNil.created_count<>0 then
    $'[QueueResNil]: {QueueResNil.created_count}'.Println;
  if QueueResT.created_count.Count<>0 then
  begin
    $'[QueueRes<T>]: {QueueResT.created_count.Values.Sum}'.Println;
    foreach var t in QueueResT.created_count.Keys.Order do
      $'{#9}{t}: {QueueResT.created_count[t]}'.Println;
  end;
  
{$endif ForceMaxDebug}
end.