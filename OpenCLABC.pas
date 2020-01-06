
//*****************************************************************************************************\\
// Copyright (©) Cergey Latchenko ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\
// Copyright (©) Сергей Латченко ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Этот код распространяется с лицензией Unlicense
// Подробнее в файле LICENSE или тут:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\

///
///Высокоуровневая оболочка модуля OpenCL
///   OpenCL и OpenCLABC можно использовать одновременно
///   Но контактировать они практически не будут
///
///Если не хватает типа/метода или найдена ошибка - писать сюда:
///   https://github.com/SunSerega/POCGL/issues
///
///Справка данного модуля находится в начале его исходника
///   Исходники можно открыть Ctrl-кликом на любом имени из модуля
///
unit OpenCLABC;

{$region 3.6 —— Ожидание очередей}

//ToDo ещё раз переделать этот раздел перед пулом
// 
// В OpenCL для синхронизации команд используются cl_event'ы
// Они позволяют любой 1 очереди ожидать выполнения списка других очередей
// 
// Методика OpenCLABC, использования операций с очередями (как сложение и умножение) для синхронизации - в целом проще
// Но накладывает некоторые ограничения на возможности программиста
// Методы как .ThenConvert и .Multiusable созданны чтоб обойти большинство этих ограничений
// Но всё же они покрывают не все ограничения
// 
// Поэтому на крайний случай - в OpenCLABC так же есть глобальная функция WaitForQueue
// Она создаёт очередь, ожидающую выполнение 1 очереди и затем выполняющую другую
// 
// Первая очередь (wait_source) работает не по правилам остального OpenCLABC
// В качестве wait_source можно передать очередь, уже использованную в том же вызов Context.BeginInvoke
// И так же можно передавать очередь, выполняемую в другом, независимом вызове Context.BeginInvoke
// Это потому, что очередь которую возвращает WaitForQueue не выполняет wait_source
// Она только ожидает сигнала окончания выполнения от wait_source
// 
// Вторая очередь (next) работает уже проще
// Она начинает выполняться как только получен сигнал от wait_source
// Очередь, которую возвращает WaitForQueue считаеться выполненной тогда, когда выполнилась next
// И её возвращаемое значение - это то что вернула next
// 
// Так же у WaitForQueue есть опциональный параметр - allow_wait_source_cloning с типом boolean
// Он указывает, следует ли клонировать wait_source при клонировании возвращённой очереди
// Значение по-умолчанию у него True
// Однако если wait_source выполняеться в отдельном вызове Context.BeginInvoke - его клонирование создаст очередь,
// на которую нет ссылок в программе, а значит она никогда не выполниться
// 
//TODO и теперь, при создании примера, я наконец задумался о применимости такого синтаксиса WaitForQueue
// - Может лучше добавить .ThenWaitFor? Потом как то подумать, есть ли случаи где не сработает .ThenWaitFor, но будет полезно WaitForQueue
// - Возможные примеры:
// 
//     D
//    /
//   B
//  / \
// A   E
//  \ /
//   C
//    \
//     F
// 
//Проблема: это всё делаеться через 3 .Multiusable (A, B и C). Надо бы написать через Mu и подумать, можно ли проще
// 
// A--C--E--G
//  \      /
//   \    /
// B--D--F--H
// 
//Проблема: WaitForQueue не сделает код проще. А вот .ThenWaitFor помогло бы
// 

{$endregion 3.6 —— Ожидание очередей}

interface

uses OpenCL;

uses System;
uses System.Threading;
uses System.Threading.Tasks;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

{$region ToDo}

//===================================
// Обязательно сделать до следующего пула:

//ToDo добавление ивентов в CLTask не безопастно, если он выполнится до их добавления

//ToDo ___EventList.AttachCallback(ev; cb)
// - сильно упростит код, потому что GCHandle не придётся создавать вручную

//ToDo перегрузки cont.AddErr для ErrorCode и CommandExecutionStatus, потому что это много где надо

//ToDo cl.SetKernelArg из нескольких потоков одновременно - предусмотреть

//ToDo синхронные (с припиской Fast) варианты всего работающего по принципу HostQueue
//ToDo и асинхронные умнее запускать - помнить значение, указывающее можно ли выполнить их синхронно

//ToDo может сделать Invoke функцией, возвращающей ___EventList?

//ToDo проверить чтоб небыло утечек памяти
//ToDo проверить чтоб исключение в HPQ нормально выводилось
//ToDo проверить чтоб CheckErr было во всех классах с под-очередями
// - при этом исключения под-очередей должны обрабатываться первыми, потому что они выполнялись раньше

//ToDo использовать пустые inherited
// - но у функций они сейчас сломаны - #2145

//ToDo если в предыдущей очереди исключение - остановить выполнение
// - это не критично, но иначе будет выводить кучу лишних ошибок

//ToDo .ThenWaitFor
//ToDo .ThenWaitForAll
//ToDo .ThenWaitForAny
// - Стоп, а для Any может всё же Then не работает?
// - Может сделать первое и второе методами, а Any глобальными подпрограммами?
// - нет, лучше наверное все 3 методами, но для Any ещё глобальную функцию

//ToDo проверить все raise - лучше сделать свои исключения

//ToDo Написать в справке про AddProc,AddQueue

//ToDo Написать в справке про AddWait
//ToDo Написать в справке про WaitFor
//ToDo написать в справке про опастность того, что ThenWaitFor может выполниться после завершения выполнения очереди если она в другом BeginInvoke

//ToDo раздел справки про оптимизацию
// - почему 1 очередь быстрее 2 её кусков

//ToDo система создания описаний через отдельные файлы
// - и тексты исключений тоже туда куда то

//ToDo проверить все "//ToDo" в модуле

//ToDo снова проверить все cl. на .RaiseIfError

//ToDo вытащить из справки все "```pas" и засунуть в тесты с запуском

//===================================
// Запланированное:

//ToDo исправить десериализацию ProgramCode

//ToDo когда partial классы начнут нормально себя вести - использовать их чтоб переместить все "__*" классы в implementation

//ToDo MW ивенты должны хранится в Dictionary<Context,cl_event>, потому что функция получения MW ивента должна возвращать совместимый с контекстом ивент
//ToDo UnMakeWaitable, вызываемое из финализатора Wait очередей, чтоб очередь имела возможность стать нормальной

//ToDo возможность приделать колбек к завершению CLTask-а
// - и сразу написать об этом в справке

//ToDo CommmandQueueBase.ToString для дебага
// - так же дублирующий protected метод (tabs: integer; index: Dictionary<CommandQueueBase,integer>)

//ToDo CommandQueue.Cycle(integer)
//ToDo CommandQueue.Cycle // бесконечность циклов
//ToDo CommandQueue.CycleWhile(***->boolean)
// - Возможность передать свой обработчик ошибок как Exception->Exception
//
//Update:
// - Бесконечный цикл будет больно делать
// - Чтобы не накапливались Task-и - надо полностью перезапускать очередь
// - А значит надо что то вроде пре-запуска, чтобы не терять время между итерациями
//
//Update2:
// - Нет, надо через контейнер выполнения добится того, чтоб .Clone не нужен был
// - Тогда можно будет сделать просто несколько запусков одной очереди, ожидающих друг друга

//ToDo В продолжение Cycle: Однако всё ещё остаётся проблема - как сделать ветвление?
// - И если уже делать - стоит сделать и метод CQ.ThenIf(res->boolean; if_true, if_false: CQ)
// - Ивенты должны выполнится, иначе останутся GCHandle которые не освободили
// - Наверное надо что то типа cl.SetUserEventStatus(ErrorCode.MyCustomQueueCancelCode)
// - Протестировать как это работает с юзер-ивентами и с маркерами из таких юзер-ивентов

//ToDo Read/Write для массивов - надо бы иметь возможность указывать отступ в массиве

//ToDo Типы Device и Platform
//ToDo А связь с OpenCL.pas сделать всему (и буферам и кёрнелам), но более человеческую

//ToDo Сделать методы BufferCommandQueue.AddGet
// - они особенные, потому что возвращают не BufferCommandQueue, а каждый свою очередь
// - полезно, потому что SyncInvoke такой очереди будет возвращать полученное значение

//ToDo Интегрировать профайлинг очередей

//===================================
// Сделать когда-нибуть:

//ToDo У всего, у чего есть .Finalize - проверить чтобы было и .Dispose, если надо
// - и добавить в справку, про то что этот объект можно удалять
// - из .Dispose можно блокировать .Finalize

//ToDo Пройтись по всем функциям OpenCL, посмотреть функционал каких не доступен из OpenCLABC
// - у Kernel.Exec несколько параметров не используются. Стоит использовать

//ToDo Тесты всех фич модуля

//===================================

//ToDo issue компилятора:
// - #1981
// - #2048
// - #2067
// - #2068
// - #2118
// - #2119
// - #2120
// - #2140

{$endregion ToDo}

{$region Debug}

{ $define DebugMode}
{$ifdef DebugMode}

{$endif DebugMode}

{$endregion Debug}

type
  
  {$region pre def}
  
  CommandQueueBase = class;
  CommandQueue<T> = class;
  
  Buffer = class;
  Kernel = class;
  
  Context = class;
  
  ProgramCode = class;
  
  IConstQueue = interface
    function GetConstVal: Object;
  end;
  ConstQueue<T> = class;
  
  {$endregion pre def}
  
  {$region hidden utils}
  
  __NativUtils = static class
    
    static function CopyToUnm<TRecord>(a: TRecord): ^TRecord; where TRecord: record;
    begin
      Result := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<TRecord>));
      Result^ := a;
    end;
    
    static function AsPtr<T>(p: pointer): ^T := p;
    
    static function GCHndAlloc(o: object) :=
    CopyToUnm(GCHandle.Alloc(o));
    
    static procedure GCHndFree(gc_hnd_ptr: pointer);
    begin
      AsPtr&<GCHandle>(gc_hnd_ptr)^.Free;
      Marshal.FreeHGlobal(IntPtr(gc_hnd_ptr));
    end;
    
  end;
  
  __EventList = sealed class
    private evs: array of cl_event;
    private count := 0;
    
    public constructor := exit;
    
    public constructor(count: integer) :=
    self.evs := count=0 ? nil : new cl_event[count];
    
    public property Item[i: integer]: cl_event read evs[i]; default;
    
    public static function operator implicit(ev: cl_event): __EventList;
    begin
      if ev=cl_event.Zero then
        Result := new __EventList else
      begin
        Result := new __EventList(1);
        Result += ev;
      end;
    end;
    
    public constructor(params evs: array of cl_event);
    begin
      self.evs := evs;
      self.count := evs.Length;
    end;
    
    public static procedure operator+=(l: __EventList; ev: cl_event);
    begin
      l.evs[l.count] := ev;
      l.count += 1;
    end;
    
    public static procedure operator+=(l: __EventList; ev: __EventList);
    begin
      {$ifdef DebugMode}
      for var i := 0 to ev.count-1 do
        l += ev[i];
      exit;
      {$endif DebugMode}
      if ev.count=0 then exit;
      System.Buffer.BlockCopy( ev.evs,0, l.evs,l.count*cl_event.Size, ev.count*cl_event.Size );
      l.count += ev.count;
    end;
    
    public static function operator+(l1,l2: __EventList): __EventList;
    begin
      Result := new __EventList(l1.count+l2.count);
      Result += l1;
      Result += l2;
    end;
    
    public static function Combine(params evs: array of __EventList): __EventList;
    begin
      Result := new __EventList(evs.Sum(ev->ev.count));
      foreach var ev in evs do
        Result += ev;
    end;
    
    public procedure Retain :=
    for var i := 0 to count-1 do
      cl.RetainEvent(evs[i]).RaiseIfError;
    
    public procedure Release :=
    for var i := 0 to count-1 do
      cl.ReleaseEvent(evs[i]).RaiseIfError;
    
    ///cb должен иметь глобальный try и вызывать "state.RaiseIfError" и "__NativUtils.GCHndFree(data)",
    ///А "cl.ReleaseEvent" если и вызывать - то только на результате вызова AttachCallback
    public function AttachCallback(cb: Event_Callback; c: Context; var cq: cl_command_queue): cl_event;
    
  end;
  
  __IQueueRes = interface;
  __QueueExecContainer = abstract class
    private err_lst := new List<Exception>;
    private mu_res := new Dictionary<object, __IQueueRes>;
    
    protected procedure AddErr(e: Exception) :=
    lock err_lst do err_lst += e;
    
  end;
  
  __IQueueRes = interface
    
    function GetBase: object;
    function GetEv: __EventList;
    
    function WaitAndGetBase: object;
    
    function LazyQuickTransformBase<T2>(f: object->T2): __IQueueRes; //ToDo плохо, лишний боксинг результата. Может сделать extensionmethod-ом?
    
    function AttachCallbackBase(cb: Event_Callback; c: Context; var cq: cl_command_queue): __IQueueRes;
    
  end;
  __QueueRes<T> = record(__IQueueRes)
    res: T;
    res_f: ()->T;
    ev: __EventList;
    
    function Get: T := res_f=nil ? res : res_f();
    function GetBase: object := Get();
    
    function GetEv: __EventList := self.ev;
    
    function WaitAndGet: T;
    begin
      
      if ev.count<>0 then
      begin
        cl.WaitForEvents(ev.count,ev.evs).RaiseIfError;
        ev.Release;
      end;
      
      Result := res_f=nil ? res : res_f();
    end;
    function WaitAndGetBase: object := WaitAndGet();
    
    function LazyQuickTransform<T2>(f: T->T2): __QueueRes<T2>;
    begin
      Result.ev := self.ev;
      if self.res_f<>nil then
      begin
        var f0 := self.res_f;
        Result.res_f := ()->f(f0());
      end else
      if self.ev.count=0 then
        Result.res := f(self.res) else
      begin
        var r0 := self.res;
        Result.res_f := ()->f(r0);
      end;
    end;
    function LazyQuickTransformBase<T2>(f: object->T2): __IQueueRes;
    begin
      var res: __QueueRes<T2>;
      
      res.ev := self.ev;
      if self.res_f<>nil then
      begin
        var f0 := self.res_f;
        res.res_f := ()->f(f0());
      end else
      if self.ev.count=0 then
        res.res := f(self.res) else
      begin
        var r0 := self.res;
        res.res_f := ()->f(r0);
      end;
      
      Result := res;
    end;
    
    function AttachCallback(cb: Event_Callback; c: Context; var cq: cl_command_queue): __QueueRes<T>;
    begin
      Result.res    := self.res;
      Result.res_f  := self.res_f;
      Result.ev     := self.ev.AttachCallback(cb, c, cq);
    end;
    function AttachCallbackBase(cb: Event_Callback; c: Context; var cq: cl_command_queue): __IQueueRes := AttachCallback(cb, c, cq);
    
  end;
  
  {$endregion hidden utils}
  
  {$region Exception's}
  
  {$endregion Exception's}
  
  {$region CommandQueue}
  
  CommandQueueBase = abstract class
    
    protected mw_lock: object; // nil, пока не будет создана Wait очередь с ожиданием данной очереди
    protected mw_ev: cl_event;
    
    {$region Queue converters}
    
    {$region ConstQueue}
    
    public static function operator implicit(o: object): CommandQueueBase;
    
    {$endregion ConstQueue}
    
    {$region Cast}
    
    public function Cast<T>: CommandQueue<T>; //ToDo в справку
    
    {$endregion Cast}
    
    {$region ThenConvert}
    
    //ToDo #2118
//    ///Создаёт очередь, которая выполнит данную
//    ///А затем выполнит на CPU функцию f, используя результат данной очереди
//    public function ThenConvert<T>(f: object->T): CommandQueue<T>;
//    ///Создаёт очередь, которая выполнит данную
//    ///А затем выполнит на CPU функцию f, используя результат данной очереди и контекст на котором её выполнили
//    public function ThenConvert<T>(f: (object,Context)->T): CommandQueue<T>;
    
    {$endregion ThenConvert}
    
    {$region [A]SyncQueue}
    
    public static function operator+(q1, q2: CommandQueueBase): CommandQueueBase;
    public static function operator+<T>(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    public static procedure operator+=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1+q2;
    
    public static function operator*(q1, q2: CommandQueueBase): CommandQueueBase;
    public static function operator*<T>(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T>;
    public static procedure operator*=(var q1: CommandQueueBase; q2: CommandQueueBase) := q1 := q1*q2;
    
    {$endregion [A]SyncQueue}
    
    {$region Mutiusable}
    
    //ToDo #2120
//    ///Создаёт массив из n очередей, каждая из которых возвращает результат данной очереди
//    ///Каждую полученную очередь можно использовать одновременно с другими, но только в общей очереди
//    public function Multiusable(n: integer): array of CommandQueueBase;
//    
//    ///Создаёт функцию, создающую очередь, которая возвращает результат данной очереди
//    ///Каждую очередь, созданную полученной функцией, можно использовать одновременно с другими, но только в общей очереди
//    public function Multiusable: ()->CommandQueueBase;
    
    {$endregion Mutiusable}
    
    {$region ThenWait}
    
    public function ThenWaitFor(q: CommandQueueBase): CommandQueueBase := ThenWaitForAll(q);
    
    public function ThenWaitForAll(qs: sequence of CommandQueueBase): CommandQueueBase := CreateWaitWrapperBase(qs, true);
    public function ThenWaitForAll(params qs: array of CommandQueueBase) := ThenWaitForAll(qs.AsEnumerable);
    
    public function ThenWaitForAny(qs: sequence of CommandQueueBase): CommandQueueBase := CreateWaitWrapperBase(qs, false);
    public function ThenWaitForAny(params qs: array of CommandQueueBase) := ThenWaitForAny(qs.AsEnumerable);
    
    {$endregion ThenWait}
    
    {$endregion Queue converters}
    
    {$region Invoke}
    
    protected function InvokeBase(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __IQueueRes; abstract;
    
    protected function InvokeNewQBase(cont: __QueueExecContainer; c: Context): __IQueueRes;
    begin
      var cq := cl_command_queue.Zero;
      Result := InvokeBase(cont, c, cq, new __EventList);
      
      var CQFree: Action := ()->
      begin
        if cq<>cl_command_queue.Zero then cl.ReleaseCommandQueue(cq); //ToDo cont.AddErr
      end;
      
      if Result.GetEv.count=0 then
        Task.Run(CQFree) else
        Result := Result.AttachCallbackBase((ev,st,data)->
        begin
          //ToDo cont.AddErr( st );
          Task.Run(CQFree);
          __NativUtils.GCHndFree(data);
        end, c, cq);
    end;
    
    {$endregion Invoke}
    
    {$region Utils}
    
    {$region Misc}
    
    protected procedure MakeWaitable :=
    if mw_lock=nil then // чтоб лишний раз "lock self" не делать
      lock self do
        if mw_lock=nil then // ещё раз если изменилось пока ждали lock
          mw_lock := new Object;
    
    protected static function CreateUserEvent(c: Context): cl_event;
    
    {$endregion Misc}
    
    {$region Event's}
    
    protected function GetMWEvent(c: cl_context): cl_event;
    begin
      
      lock mw_lock do
      begin
        
        if self.mw_ev=cl_event.Zero then
        begin
          var ec: ErrorCode;
          self.mw_ev := cl.CreateUserEvent(c, ec);
          ec.RaiseIfError;
        end else
          cl.RetainEvent(self.mw_ev).RaiseIfError;
        
        Result := self.mw_ev;
      end;
      
    end;
    
    protected procedure SignalMWEvent :=
    if mw_lock<>nil then lock mw_lock do
    begin
      if self.mw_ev=cl_event.Zero then exit;
      cl.SetUserEventStatus(self.mw_ev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      self.mw_ev := cl_event.Zero;
    end;
    
    {$endregion Event's}
    
    {$region ThenWait}
    
    protected function CreateWaitWrapperBase(qs: sequence of CommandQueueBase; all: boolean): CommandQueueBase; abstract;
    
    {$endregion ThenWait}
    
    {$endregion Utils}
    
  end;
  CommandQueue<T> = abstract class(CommandQueueBase)
    
    {$region Queue converters}
    
    {$region ConstQueue}
    
    public static function operator implicit(o: T): CommandQueue<T>;
    
    {$endregion ConstQueue}
    
    {$region ThenConvert}
    
    public function ThenConvert<T2>(f: T->T2): CommandQueue<T2>;
    public function ThenConvert<T2>(f: (T,Context)->T2): CommandQueue<T2>;
    
    {$endregion ThenConvert}
    
    {$region [A]SyncQueue}
    
    public static procedure operator+=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1+q2;
    public static procedure operator*=(var q1: CommandQueue<T>; q2: CommandQueue<T>) := q1 := q1*q2;
    
    {$endregion [A]SyncQueue}
    
    {$region Mutiusable}
    
    public function Multiusable(n: integer): array of CommandQueue<T>;
    
    public function Multiusable: ()->CommandQueue<T>;
    
    {$endregion Mutiusable}
    
    {$region ThenWait}
    
    public function ThenWaitFor(q: CommandQueueBase): CommandQueue<T> := ThenWaitForAll(q);
    
    public function ThenWaitForAll(qs: sequence of CommandQueueBase): CommandQueue<T> := CreateWaitWrapper(qs, true);
    public function ThenWaitForAll(params qs: array of CommandQueueBase) := ThenWaitForAll(qs.AsEnumerable);
    
    public function ThenWaitForAny(qs: sequence of CommandQueueBase): CommandQueue<T> := CreateWaitWrapper(qs, false);
    public function ThenWaitForAny(params qs: array of CommandQueueBase) := ThenWaitForAny(qs.AsEnumerable);
    
    protected function CreateWaitWrapper(qs: sequence of CommandQueueBase; all: boolean): CommandQueue<T>;
    protected function CreateWaitWrapperBase(qs: sequence of CommandQueueBase; all: boolean): CommandQueueBase; override :=
    CreateWaitWrapper(qs, all);
    
    {$endregion ThenWait}
    
    {$endregion Queue converters}
    
    {$region Invoke}
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; abstract;
    protected function InvokeBase(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __IQueueRes; override :=
    Invoke(cont, c, cq, prev_ev);
    
    protected function InvokeNewQ(cont: __QueueExecContainer; c: Context): __QueueRes<T>;
    begin
      var cq := cl_command_queue.Zero;
      Result := Invoke(cont, c, cq, new __EventList);
      
      var CQFree: Action := ()->
      begin
        if cq<>cl_command_queue.Zero then cl.ReleaseCommandQueue(cq); //ToDo cont.AddErr
      end;
      
      if Result.GetEv.count=0 then
        Task.Run(CQFree) else
        Result := Result.AttachCallback((ev,st,data)->
        begin
          //ToDo cont.AddErr( st );
          Task.Run(CQFree);
          __NativUtils.GCHndFree(data);
        end, c, cq);
    end;
    
    {$endregion Invoke}
    
  end;
  
  // очередь, выполняющая незначитальный объём своей работы, но запускающая под-очереди
  __ContainerQueue<T> = abstract class(CommandQueue<T>)
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; abstract;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      Result := InvokeSubQs(cont, c, cq, prev_ev);
      
      if mw_lock<>nil then
        Result := Result.AttachCallback((ev,st,data)->
        begin
          if st.IS_ERROR then cont.AddErr(new OpenCLException( st.ToString ));
          self.SignalMWEvent;
          __NativUtils.GCHndFree(data);
        end, c, cq);
      
    end;
    
  end;
  
  // очередь, выполняющая какую то работу на CPU, всегда в отдельном потоке
  __HostQueue<TInp,TRes> = abstract class(CommandQueue<TRes>)
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<TInp>; abstract;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; abstract;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<TRes>; override;
    begin
      var prev_res := InvokeSubQs(cont, c, cq, prev_ev);
      
      var uev := CreateUserEvent(c);
      Result.ev := uev;
      
      var res: TRes;
      Result.res_f := ()->res;
      
      Thread.Create(()->
      try
        res := ExecFunc(prev_res.WaitAndGet(), c);
        cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        self.SignalMWEvent;
      except
        on e: Exception do
        begin
          cont.AddErr(e);
          cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        end;
      end).Start;
      
    end;
    
  end;
  
  {$endregion CommandQueue}
  
  {$region Misc}
  
  DeviceTypeFlags = OpenCL.DeviceTypeFlags;
  
  CLTask<T> = sealed class(__QueueExecContainer)
    private q: CommandQueue<T>;
    private wh := new ManualResetEvent(false);
    private q_res: T;
    
    public event Finished: (CommandQueue<T>, T)->();
    public event Error: Action<CommandQueue<T>, array of Exception>;
    
    protected constructor(q: CommandQueue<T>; c: Context);
    begin
      self.q := q;
      
      var cq := cl_command_queue.Zero;
      var res := q.Invoke(self, c, cq, new __EventList);
      
      // mu выполняют лишний .Retain, чтоб ивент не удалился пока очередь ещё запускается
      foreach var qr in mu_res.Values do
        qr.GetEv.Release;
      mu_res := nil;
      
      var ev := res.GetEv;
      
      if ev.count=0 then
      begin
        if cq<>cl_command_queue.Zero then raise new NotImplementedException; // не должно произойти никогда
        OnQDone( res.Get() );
      end else
        cl.ReleaseEvent(
          ev.AttachCallback((ev,st,data)->
          begin
            if st.IS_ERROR then err_lst.Add( new OpenCLException(st.GetError.ToString) );
            
            Task.Run(()->
            begin
              if cq<>cl_command_queue.Zero then cl.ReleaseCommandQueue(cq).RaiseIfError;
            end);
            
            OnQDone( res.Get() );
            wh.Set;
            
            __NativUtils.GCHndFree(data);
          end, c, cq)
        ).RaiseIfError;
      
    end;
    
    private procedure OnQDone(res: T) :=
    try
      self.q_res := res;
      
      if err_lst.Count=0 then
      begin
        var lFinished := Finished;
        if lFinished<>nil then lFinished(q, res);
      end else
      begin
        var lError := Error;
        if lError<>nil then lError(q, err_lst.ToArray);
      end;
      
      wh.Set;
    except
      on e: Exception do
      begin
        err_lst += e;
        wh.Set;
      end;
    end;
    
    public procedure Wait;
    begin
      wh.WaitOne;
      if err_lst.Count<>0 then raise new AggregateException(
        $'При выполнении очереди было вызвано ({err_lst.Count}) исключений. Используйте try чтоб получить больше информации',
        err_lst
      );
    end;
    
    public function GetRes: T;
    begin
      Wait;
      Result := self.q_res;
    end;
    
  end;
  
  {$endregion Misc}
  
  {$region GPUCommand}
  
  __GPUCommand<T> = abstract class
    
    protected function InvokeObj(o: T; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; abstract;
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; abstract;
    
  end;
  
  __GPUCommandContainer<T> = class;
  __GPUCommandContainerBody<T> = abstract class
    private cc: __GPUCommandContainer<T>;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; abstract;
    
  end;
  
  __GPUCommandContainer<T> = abstract class(__ContainerQueue<T>)
    protected body: __GPUCommandContainerBody<T>;
    protected commands := new List<__GPUCommand<T>>;
    
    {$region def}
    
    protected procedure OnEarlyInit(c: Context); virtual := exit;
    
    {$endregion def}
    
    {$region Common}
    
    protected constructor(o: T);
    protected constructor(q: CommandQueue<T>);
    
    protected procedure InternalAddQueue(q: CommandQueueBase);
    
    protected procedure InternalAddProc(p: T->());
    protected procedure InternalAddProc(p: (T,Context)->());
    
    protected procedure InternalAddWaitAll(qs: sequence of CommandQueueBase);
    protected procedure InternalAddWaitAny(qs: sequence of CommandQueueBase);
    
    {$endregion Common}
    
    {$region sub implementation}
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override :=
    body.Invoke(cont, c, cq, prev_ev);
    
    {$endregion sub implementation}
    
    {$region reintroduce методы}
    
    public function Equals(obj: object): boolean; reintroduce := inherited Equals(obj);
    public function ToString: string; reintroduce := inherited ToString();
    public function GetType: System.Type; reintroduce := inherited GetType();
    public function GetHashCode: integer; reintroduce := inherited GetHashCode();
    
    {$endregion reintroduce методы}
    
  end;
  
  {$endregion GPUCommand}
  
  {$region Buffer}
  
  BufferCommandQueue = sealed class(__GPUCommandContainer<Buffer>)
    
    {$region constructor's}
    
    public constructor(b: Buffer) := inherited Create(b);
    public constructor(q: CommandQueue<Buffer>);
    
    {$endregion constructor's}
    
    {$region Utils}
    
    protected function AddCommand(comm: __GPUCommand<Buffer>): BufferCommandQueue;
    begin
      self.commands += comm;
      Result := self;
    end;
    
    protected function GetSizeQ: CommandQueue<integer>;
    
    {$endregion Utils}
    
    {$region Write}
    
    public function AddWriteData(ptr: CommandQueue<IntPtr>): BufferCommandQueue := AddWriteData(ptr, 0,GetSizeQ);
    public function AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddWriteData(ptr: pointer) := AddWriteData(IntPtr(ptr));
    public function AddWriteData(ptr: pointer; offset, len: CommandQueue<integer>) := AddWriteData(IntPtr(ptr), offset, len);
    
    
    public function AddWriteArray(a: CommandQueue<&Array>): BufferCommandQueue := AddWriteArray(a, 0,GetSizeQ);
    public function AddWriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddWriteArray(a: &Array) := AddWriteArray(CommandQueue&<&Array>(a));
    public function AddWriteArray(a: &Array; offset, len: CommandQueue<integer>) := AddWriteArray(CommandQueue&<&Array>(a), offset, len);
    
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    
    public function AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    
    {$endregion Write}
    
    {$region Read}
    
    public function AddReadData(ptr: CommandQueue<IntPtr>): BufferCommandQueue := AddReadData(ptr, 0,GetSizeQ);
    public function AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddReadData(ptr: pointer) := AddReadData(IntPtr(ptr));
    public function AddReadData(ptr: pointer; offset, len: CommandQueue<integer>) := AddReadData(IntPtr(ptr), offset, len);
    
    public function AddReadArray(a: CommandQueue<&Array>): BufferCommandQueue := AddReadArray(a, 0,GetSizeQ);
    public function AddReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddReadArray(a: &Array) := AddReadArray(CommandQueue&<&Array>(a));
    public function AddReadArray(a: &Array; offset, len: CommandQueue<integer>) := AddReadArray(CommandQueue&<&Array>(a), offset, len);
    
    public function AddReadValue<TRecord>(var val: TRecord; offset: CommandQueue<integer> := 0): BufferCommandQueue; where TRecord: record;
    begin
      Result := AddReadData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Read}
    
    {$region Fill}
    
    public function AddFillData(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>): BufferCommandQueue := AddFillData(ptr,pattern_len, 0,GetSizeQ);
    public function AddFillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddFillData(ptr: pointer; pattern_len: CommandQueue<integer>) := AddFillData(IntPtr(ptr), pattern_len);
    public function AddFillData(ptr: pointer; pattern_len, offset, len: CommandQueue<integer>) := AddFillData(IntPtr(ptr), pattern_len, offset, len);
    
    public function AddFillArray(a: CommandQueue<&Array>): BufferCommandQueue := AddFillArray(a, 0,GetSizeQ);
    public function AddFillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddFillArray(a: &Array) := AddFillArray(CommandQueue&<&Array>(a));
    public function AddFillArray(a: &Array; offset, len: CommandQueue<integer>) := AddFillArray(CommandQueue&<&Array>(a), offset, len);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function AddFillValue<TRecord>(val: TRecord): BufferCommandQueue; where TRecord: record;
    begin Result := AddFillValue(val, 0,GetSizeQ); end;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function AddFillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): BufferCommandQueue; where TRecord: record;
    
    public function AddFillValue<TRecord>(val: CommandQueue<TRecord>): BufferCommandQueue; where TRecord: record;
    begin Result := AddFillValue(val, 0,GetSizeQ); end;
    public function AddFillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>): BufferCommandQueue; where TRecord: record;
    
    {$endregion Fill}
    
    {$region Copy}
    
    public function AddCopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): BufferCommandQueue;
    public function AddCopyTo  (b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): BufferCommandQueue;
    
    public function AddCopyFrom(b: CommandQueue<Buffer>) := AddCopyFrom(b, 0,0, GetSizeQ);
    public function AddCopyTo  (b: CommandQueue<Buffer>) := AddCopyTo  (b, 0,0, GetSizeQ);
    
    {$endregion Copy}
    
    {$region Non-command add's}
    
    public function AddQueue(q: CommandQueueBase): BufferCommandQueue;
    begin
      InternalAddQueue(q);
      Result := self;
    end;
    
    public function AddProc(p: (Buffer,Context)->()): BufferCommandQueue;
    begin
      InternalAddProc(p);
      Result := self;
    end;
    public function AddProc(p: Buffer->()): BufferCommandQueue;
    begin
      InternalAddProc(p);
      Result := self;
    end;
    
    public function AddWaitAll(qs: sequence of CommandQueueBase): BufferCommandQueue;
    begin
      InternalAddWaitAll(qs);
      Result := self;
    end;
    public function AddWaitAny(qs: sequence of CommandQueueBase): BufferCommandQueue;
    begin
      InternalAddWaitAny(qs);
      Result := self;
    end;
    public function AddWaitAll(params qs: array of CommandQueueBase) := AddWaitAll(qs.AsEnumerable);
    public function AddWaitAny(params qs: array of CommandQueueBase) := AddWaitAny(qs.AsEnumerable);
    public function AddWait(q: CommandQueueBase) := AddWaitAll(q);
    
    {$endregion Non-command add's}
    
  end;
  
  Buffer = sealed class(IDisposable)
    private memobj: cl_mem;
    private sz: UIntPtr;
    private _parent: Buffer;
    
    {$region constructor's}
    
    private constructor := raise new System.NotSupportedException;
    
    public constructor(size: UIntPtr) := self.sz := size;
    public constructor(size: integer) := Create(new UIntPtr(size));
    public constructor(size: int64)   := Create(new UIntPtr(size));
    
    public constructor(size: UIntPtr; c: Context);
    begin
      Create(size);
      Init(c);
    end;
    public constructor(size: integer; c: Context) := Create(new UIntPtr(size), c);
    public constructor(size: int64; c: Context)   := Create(new UIntPtr(size), c);
    
    public function SubBuff(offset, size: integer): Buffer; 
    
    public procedure Init(c: Context);
    
    public procedure Dispose :=
    if self.memobj<>cl_mem.Zero then
    begin
      GC.RemoveMemoryPressure(Size64);
      cl.ReleaseMemObject(memobj).RaiseIfError;
      memobj := cl_mem.Zero;
    end;
    
    protected procedure Finalize; override :=
    self.Dispose;
    
    {$endregion constructor's}
    
    {$region property's}
    
    public property Size: UIntPtr read sz;
    public property Size32: UInt32 read sz.ToUInt32;
    public property Size64: UInt64 read sz.ToUInt64;
    
    public property Parent: Buffer read _parent;
    
    {$endregion property's}
    
    {$region Queue's}
    
    public function NewQueue :=
    new BufferCommandQueue(self);
    
    {$endregion Queue's}
    
    {$region Write}
    
    public function WriteData(ptr: CommandQueue<IntPtr>): Buffer;
    public function WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    public function WriteData(ptr: pointer) := WriteData(IntPtr(ptr));
    public function WriteData(ptr: pointer; offset, len: CommandQueue<integer>) := WriteData(IntPtr(ptr), offset, len);
    
    
    public function WriteArray(a: CommandQueue<&Array>): Buffer;
    public function WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    public function WriteArray(a: &Array) := WriteArray(CommandQueue&<&Array>(a));
    public function WriteArray(a: &Array; offset, len: CommandQueue<integer>) := WriteArray(CommandQueue&<&Array>(a), offset, len);
    
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function WriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    begin Result := WriteData(@val, offset, Marshal.SizeOf&<TRecord>); end;
    
    public function WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    
    {$endregion Write}
    
    {$region Read}
    
    public function ReadData(ptr: CommandQueue<IntPtr>): Buffer;
    public function ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>): Buffer;
    
    public function ReadData(ptr: pointer) := ReadData(IntPtr(ptr));
    public function ReadData(ptr: pointer; offset, len: CommandQueue<integer>) := ReadData(IntPtr(ptr), offset, len);
    
    public function ReadArray(a: CommandQueue<&Array>): Buffer;
    public function ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    public function ReadArray(a: &Array) := ReadArray(CommandQueue&<&Array>(a));
    public function ReadArray(a: &Array; offset, len: CommandQueue<integer>) := ReadArray(CommandQueue&<&Array>(a), offset, len);
    
    public function ReadValue<TRecord>(var val: TRecord; offset: CommandQueue<integer> := 0): Buffer; where TRecord: record;
    begin
      Result := ReadData(@val, offset, Marshal.SizeOf&<TRecord>);
    end;
    
    {$endregion Read}
    
    {$region Fill}
    
    public function FillData(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>): Buffer;
    public function FillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>): Buffer;
    
    public function FillData(ptr: pointer; pattern_len: CommandQueue<integer>) := FillData(IntPtr(ptr), pattern_len);
    public function FillData(ptr: pointer; pattern_len, offset, len: CommandQueue<integer>) := FillData(IntPtr(ptr), pattern_len, offset, len);
    
    public function FillArray(a: CommandQueue<&Array>): Buffer;
    public function FillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>): Buffer;
    
    public function FillArray(a: &Array) := FillArray(CommandQueue&<&Array>(a));
    public function FillArray(a: &Array; offset, len: CommandQueue<integer>) := FillArray(CommandQueue&<&Array>(a), offset, len);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function FillValue<TRecord>(val: TRecord): Buffer; where TRecord: record;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function FillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>): Buffer; where TRecord: record;
    
    public function FillValue<TRecord>(val: CommandQueue<TRecord>): Buffer; where TRecord: record;
    public function FillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>): Buffer; where TRecord: record;
    
    {$endregion Fill}
    
    {$region Copy}
    
    public function CopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): Buffer;
    public function CopyTo  (b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>): Buffer;
    
    public function CopyFrom(b: CommandQueue<Buffer>): Buffer;
    public function CopyTo  (b: CommandQueue<Buffer>): Buffer;
    
    {$endregion Copy}
    
    {$region Get}
    
    public function GetData(offset, len: CommandQueue<integer>): IntPtr;
    public function GetData := GetData(0,integer(self.Size32));
    
    
    
    public function GetArrayAt<TArray>(offset: CommandQueue<integer>; szs: CommandQueue<array of integer>): TArray; where TArray: &Array;
    public function GetArray<TArray>(szs: CommandQueue<array of integer>): TArray; where TArray: &Array;
    begin Result := GetArrayAt&<TArray>(0, szs); end;
    
    public function GetArrayAt<TArray>(offset: CommandQueue<integer>; params szs: array of CommandQueue<integer>): TArray; where TArray: &Array;
    public function GetArray<TArray>(params szs: array of integer): TArray; where TArray: &Array;
    begin Result := GetArrayAt&<TArray>(0, CommandQueue&<array of integer>(szs)); end;
    
    
    public function GetArray1At<TRecord>(offset, length: CommandQueue<integer>): array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(offset, length); end;
    public function GetArray1<TRecord>(length: CommandQueue<integer>): array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(0,length); end;
    
    public function GetArray1<TRecord>: array of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array of TRecord>(0, integer(sz.ToUInt32) div Marshal.SizeOf&<TRecord>); end;
    
    
    public function GetArray2At<TRecord>(offset, length1, length2: CommandQueue<integer>): array[,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,] of TRecord>(offset, length1, length2); end;
    public function GetArray2<TRecord>(length1, length2: CommandQueue<integer>): array[,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,] of TRecord>(0, length1, length2); end;
    
    
    public function GetArray3At<TRecord>(offset, length1, length2, length3: CommandQueue<integer>): array[,,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,,] of TRecord>(offset, length1, length2, length3); end;
    public function GetArray3<TRecord>(length1, length2, length3: CommandQueue<integer>): array[,,] of TRecord; where TRecord: record;
    begin Result := GetArrayAt&<array[,,] of TRecord>(0, length1, length2, length3); end;
    
    
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function GetValueAt<TRecord>(offset: CommandQueue<integer>): TRecord; where TRecord: record;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)] function GetValue<TRecord>: TRecord; where TRecord: record;
    begin Result := GetValueAt&<TRecord>(0); end;
    
    {$endregion Get}
    
  end;
  
  {$endregion Buffer}
  
  {$region Kernel}
  
  KernelCommandQueue = sealed class(__GPUCommandContainer<Kernel>)
    
    {$region constructor's}
    
    public constructor(k: Kernel) := inherited Create(k);
    public constructor(q: CommandQueue<Kernel>) := inherited Create(q);
    
    {$endregion constructor's}
    
    {$region Utils}
    
    protected function AddCommand(comm: __GPUCommand<Kernel>): KernelCommandQueue;
    begin
      self.commands += comm;
      Result := self;
    end;
    
    {$endregion Utils}
    
    {$region Exec}
    
    public function AddExec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function AddExec(work_szs: array of integer; params args: array of CommandQueue<Buffer>) :=
    AddExec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function AddExec1(work_sz1: UIntPtr; params args: array of CommandQueue<Buffer>) := AddExec(new UIntPtr[](work_sz1), args);
    public function AddExec1(work_sz1: integer; params args: array of CommandQueue<Buffer>) := AddExec1(new UIntPtr(work_sz1), args);
    
    public function AddExec2(work_sz1, work_sz2: UIntPtr; params args: array of CommandQueue<Buffer>) := AddExec(new UIntPtr[](work_sz1, work_sz2), args);
    public function AddExec2(work_sz1, work_sz2: integer; params args: array of CommandQueue<Buffer>) := AddExec2(new UIntPtr(work_sz1), new UIntPtr(work_sz2), args);
    
    public function AddExec3(work_sz1, work_sz2, work_sz3: UIntPtr; params args: array of CommandQueue<Buffer>) := AddExec(new UIntPtr[](work_sz1, work_sz2, work_sz3), args);
    public function AddExec3(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<Buffer>) := AddExec3(new UIntPtr(work_sz1), new UIntPtr(work_sz2), new UIntPtr(work_sz3), args);
    
    
    public function AddExec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function AddExec(work_szs: array of CommandQueue<integer>; params args: array of CommandQueue<Buffer>) :=
    AddExec(work_szs.ConvertAll(sz_q->sz_q.ThenConvert(sz->new UIntPtr(sz))), args);
    
    public function AddExec1(work_sz1: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := AddExec(new CommandQueue<UIntPtr>[](work_sz1), args);
    public function AddExec1(work_sz1: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := AddExec1(work_sz1.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function AddExec2(work_sz1, work_sz2: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := AddExec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2), args);
    public function AddExec2(work_sz1, work_sz2: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := AddExec2(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function AddExec3(work_sz1, work_sz2, work_sz3: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := AddExec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2, work_sz3), args);
    public function AddExec3(work_sz1, work_sz2, work_sz3: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := AddExec3(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), work_sz3.ThenConvert(sz->new UIntPtr(sz)), args);
    
    
    public function AddExec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    public function AddExec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>): KernelCommandQueue;
    
    {$endregion Exec}
    
    {$region Non-command add's}
    
    public function AddQueue(q: CommandQueueBase): KernelCommandQueue;
    begin
      InternalAddQueue(q);
      Result := self;
    end;
    
    public function AddProc(p: (Kernel,Context)->()): KernelCommandQueue;
    begin
      InternalAddProc(p);
      Result := self;
    end;
    public function AddProc(p: Kernel->()): KernelCommandQueue;
    begin
      InternalAddProc(p);
      Result := self;
    end;
    
    public function AddWaitAll(qs: sequence of CommandQueueBase): KernelCommandQueue;
    begin
      InternalAddWaitAll(qs);
      Result := self;
    end;
    public function AddWaitAny(qs: sequence of CommandQueueBase): KernelCommandQueue;
    begin
      InternalAddWaitAny(qs);
      Result := self;
    end;
    public function AddWaitAll(params qs: array of CommandQueueBase) := AddWaitAll(qs.AsEnumerable);
    public function AddWaitAny(params qs: array of CommandQueueBase) := AddWaitAny(qs.AsEnumerable);
    public function AddWait(q: CommandQueueBase) := AddWaitAll(q);
    
    {$endregion Non-command add's}
    
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
    
    {$endregion Queue's}
    
    {$region Exec}
    
    public function Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>): Kernel;
    public function Exec(work_szs: array of integer; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz->new UIntPtr(sz)), args);
    
    public function Exec1(work_sz1: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1), args);
    public function Exec1(work_sz1: integer; params args: array of CommandQueue<Buffer>) := Exec1(new UIntPtr(work_sz1), args);
    
    public function Exec2(work_sz1, work_sz2: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1, work_sz2), args);
    public function Exec2(work_sz1, work_sz2: integer; params args: array of CommandQueue<Buffer>) := Exec2(new UIntPtr(work_sz1), new UIntPtr(work_sz2), args);
    
    public function Exec3(work_sz1, work_sz2, work_sz3: UIntPtr; params args: array of CommandQueue<Buffer>) := Exec(new UIntPtr[](work_sz1, work_sz2, work_sz3), args);
    public function Exec3(work_sz1, work_sz2, work_sz3: integer; params args: array of CommandQueue<Buffer>) := Exec3(new UIntPtr(work_sz1), new UIntPtr(work_sz2), new UIntPtr(work_sz3), args);
    
    
    public function Exec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>): Kernel;
    public function Exec(work_szs: array of CommandQueue<integer>; params args: array of CommandQueue<Buffer>) :=
    Exec(work_szs.ConvertAll(sz_q->sz_q.ThenConvert(sz->new UIntPtr(sz))), args);
    
    public function Exec1(work_sz1: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1), args);
    public function Exec1(work_sz1: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec1(work_sz1.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function Exec2(work_sz1, work_sz2: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2), args);
    public function Exec2(work_sz1, work_sz2: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec2(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), args);
    
    public function Exec3(work_sz1, work_sz2, work_sz3: CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) := Exec(new CommandQueue<UIntPtr>[](work_sz1, work_sz2, work_sz3), args);
    public function Exec3(work_sz1, work_sz2, work_sz3: CommandQueue<integer>; params args: array of CommandQueue<Buffer>) := Exec3(work_sz1.ThenConvert(sz->new UIntPtr(sz)), work_sz2.ThenConvert(sz->new UIntPtr(sz)), work_sz3.ThenConvert(sz->new UIntPtr(sz)), args);
    
    
    public function Exec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>): Kernel;
    public function Exec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>): Kernel;
    
    {$endregion Exec}
    
    protected procedure Finalize; override :=
    cl.ReleaseKernel(self._kernel).RaiseIfError;
    
  end;
  
  {$endregion Kernel}
  
  {$region Context}
  
  Context = sealed class
    private static _def_cont: Context;
    
    private _device: cl_device_id;
    private _context: cl_context;
    private need_finnalize := false;
    
    public static property &Default: Context read _def_cont write _def_cont;
    
    static constructor :=
    try
      _def_cont := new Context;
    except
      try
        _def_cont := new Context(DeviceTypeFlags.All); // если нету GPU - попытаться хотя бы для чего то инициализировать
      except
        _def_cont := nil;
      end;
    end;
    
    public constructor := Create(DeviceTypeFlags.GPU);
    
    public constructor(dt: DeviceTypeFlags);
    begin
      var ec: ErrorCode;
      
      var _platform: cl_platform_id;
      cl.GetPlatformIDs(1, @_platform, nil).RaiseIfError;
      
      cl.GetDeviceIDs(_platform, dt, 1, @_device, nil).RaiseIfError;
      
      _context := cl.CreateContext(nil, 1, @_device, nil, nil, @ec);
      ec.RaiseIfError;
      
      need_finnalize := true;
    end;
    
    public constructor(context: cl_context);
    begin
      
      cl.GetContextInfo(context, ContextInfoType.CL_CONTEXT_DEVICES, new UIntPtr(IntPtr.Size), @_device, nil).RaiseIfError;
      
      _context := context;
    end;
    
    public constructor(context: cl_context; device: cl_device_id);
    begin
      _device := device;
      _context := context;
    end;
    
    public function BeginInvoke<T>(q: CommandQueue<T>) := new CLTask<T>(q, self);
    public function BeginInvoke(q: CommandQueueBase): object := BeginInvoke(q.Cast&<object>());
    
    public function SyncInvoke<T>(q: CommandQueue<T>) := BeginInvoke(q).GetRes();
    public function SyncInvoke(q: CommandQueueBase): object := SyncInvoke(q.Cast&<object>());
    
    protected procedure Finalize; override :=
    if need_finnalize then // если было исключение при инициализации или инициализация произошла из дескриптора
      cl.ReleaseContext(_context).RaiseIfError;
    
  end;
  
  {$endregion Context}
  
  {$region ProgramCode}
  
  ProgramCode = sealed class
    private _program: cl_program;
    
    {$region constructor's}
    
    private constructor := exit;
    
    public constructor(c: Context; params files_texts: array of string);
    begin
      var ec: ErrorCode;
      
      self._program := cl.CreateProgramWithSource(c._context, files_texts.Length, files_texts, files_texts.ConvertAll(s->new UIntPtr(s.Length)), ec);
      ec.RaiseIfError;
      
      cl.BuildProgram(self._program, 1, @c._device, nil,nil,nil).RaiseIfError;
      
    end;
    
    public constructor(params files_texts: array of string) :=
    Create(Context.Default, files_texts);
    
    {$endregion constructor's}
    
    {$region GetKernel}
    
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
    
    {$endregion GetKernel}
    
    {$region Serialize}
    
    public function Serialize: array of byte;
    begin
      var bytes_count: UIntPtr;
      cl.GetProgramInfo(_program, ProgramInfoType.BINARY_SIZES, new UIntPtr(UIntPtr.Size), @bytes_count, nil).RaiseIfError;
      
      var bytes_mem := Marshal.AllocHGlobal(IntPtr(pointer(bytes_count)));
      cl.GetProgramInfo(_program, ProgramInfoType.BINARIES, new UIntPtr(UIntPtr.Size), @bytes_mem, nil).RaiseIfError;
      
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
    
    {$endregion Serialize}
    
    {$region Deserialize}
    
    public static function Deserialize(c: Context; bin: array of byte): ProgramCode;
    begin
      var ec: ErrorCode;
      
      Result := new ProgramCode;
      
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
    
    {$endregion Deserialize}
    
    protected procedure Finalize; override :=
    cl.ReleaseProgram(_program).RaiseIfError;
    
  end;
  
  {$endregion ProgramCode}
  
  {$region ConstQueue}
  
  ConstQueue<T> = sealed class(CommandQueue<T>, IConstQueue)
    private res: T;
    
    public constructor(o: T) :=
    self.res := o;
    
    public function GetConstVal: object := self.res;
    public property Val: T read self.res;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      
      if mw_lock<>nil then
      begin
        
        if prev_ev.count=0 then
          SignalMWEvent else
          prev_ev := prev_ev.AttachCallback((ev,st,data)->
          begin
            if st.IS_ERROR then cont.AddErr(new OpenCLException( st.GetError.ToString ));
            
            self.SignalMWEvent;
            
            __NativUtils.GCHndFree(data);
          end, c, cq);
        
      end;
      
      Result.ev := prev_ev;
      Result.res := self.res;
    end;
    
  end;
  
  {$endregion ConstQueue}
  
{$region Сахарные подпрограммы}

{$region HostExec}

function HFQ<T>(f: ()->T): CommandQueue<T>;
function HFQ<T>(f: Context->T): CommandQueue<T>;

function HPQ(p: ()->()): CommandQueueBase;
function HPQ(p: Context->()): CommandQueueBase;

{$endregion HostExec}

{$region CombineQueues}

{$region Sync}

{$region NonConv}

function CombineSyncQueueBase(qs: sequence of CommandQueueBase): CommandQueueBase;
function CombineSyncQueueBase(params qs: array of CommandQueueBase): CommandQueueBase;

function CombineSyncQueue<T>(qs: sequence of CommandQueueBase): CommandQueue<T>;
function CombineSyncQueue<T>(params qs: array of CommandQueueBase): CommandQueue<T>;

function CombineSyncQueue<T>(qs: sequence of CommandQueue<T>): CommandQueue<T>;
function CombineSyncQueue<T>(params qs: array of CommandQueue<T>): CommandQueue<T>;

{$endregion NonConv}

{$region Conv}

{$region NonContext}

function CombineSyncQueue<TRes>(conv: Func<array of object, TRes>; qs: sequence of CommandQueueBase): CommandQueue<TRes>;
function CombineSyncQueue<TRes>(conv: Func<array of object, TRes>; params qs: array of CommandQueueBase): CommandQueue<TRes>;

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; qs: sequence of CommandQueue<TInp>): CommandQueue<TRes>;
function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; params qs: array of CommandQueue<TInp>): CommandQueue<TRes>;

{$endregion NonContext}

{$region Context}

function CombineSyncQueue<TRes>(conv: Func<array of object, Context, TRes>; qs: sequence of CommandQueueBase): CommandQueue<TRes>;
function CombineSyncQueue<TRes>(conv: Func<array of object, Context, TRes>; params qs: array of CommandQueueBase): CommandQueue<TRes>;

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; qs: sequence of CommandQueue<TInp>): CommandQueue<TRes>;
function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; params qs: array of CommandQueue<TInp>): CommandQueue<TRes>;

{$endregion Context}

{$endregion Conv}

{$endregion Sync}

{$region Async}

{$region NonConv}

function CombineAsyncQueueBase(qs: sequence of CommandQueueBase): CommandQueueBase;
function CombineAsyncQueueBase(params qs: array of CommandQueueBase): CommandQueueBase;

function CombineAsyncQueue<T>(qs: sequence of CommandQueueBase): CommandQueue<T>;
function CombineAsyncQueue<T>(params qs: array of CommandQueueBase): CommandQueue<T>;

function CombineAsyncQueue<T>(qs: sequence of CommandQueue<T>): CommandQueue<T>;
function CombineAsyncQueue<T>(params qs: array of CommandQueue<T>): CommandQueue<T>;

{$endregion NonConv}

{$region Conv}

{$region NonContext}

function CombineAsyncQueue<TRes>(conv: Func<array of object, TRes>; qs: sequence of CommandQueueBase): CommandQueue<TRes>;
function CombineAsyncQueue<TRes>(conv: Func<array of object, TRes>; params qs: array of CommandQueueBase): CommandQueue<TRes>;

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; qs: sequence of CommandQueue<TInp>): CommandQueue<TRes>;
function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; params qs: array of CommandQueue<TInp>): CommandQueue<TRes>;

{$endregion NonContext}

{$region Context}

function CombineAsyncQueue<TRes>(conv: Func<array of object, Context, TRes>; qs: sequence of CommandQueueBase): CommandQueue<TRes>;
function CombineAsyncQueue<TRes>(conv: Func<array of object, Context, TRes>; params qs: array of CommandQueueBase): CommandQueue<TRes>;

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; qs: sequence of CommandQueue<TInp>): CommandQueue<TRes>;
function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; params qs: array of CommandQueue<TInp>): CommandQueue<TRes>;

{$endregion Context}

{$endregion Conv}

{$endregion Async}

{$endregion CombineQueues}

{$region Wait}

function WaitFor(q: CommandQueueBase): CommandQueueBase;

function WaitForAll(qs: sequence of CommandQueueBase): CommandQueueBase;
function WaitForAll(params qs: array of CommandQueueBase): CommandQueueBase;

function WaitForAny(qs: sequence of CommandQueueBase): CommandQueueBase;
function WaitForAny(params qs: array of CommandQueueBase): CommandQueueBase;

{$endregion Wait}

{$endregion Сахарные подпрограммы}

implementation

{$region Misc}

function __EventList.AttachCallback(cb: Event_Callback; c: Context; var cq: cl_command_queue): cl_event;
begin
  
  var ev: cl_event;
  if self.count>1 then
  begin
    
    if cq=cl_command_queue.Zero then
    begin
      var ec: ErrorCode;
      cq := cl.CreateCommandQueue(c._context, c._device, CommandQueuePropertyFlags.NONE, ec);
      ec.RaiseIfError;
    end;
    
    cl.EnqueueMarkerWithWaitList(cq, self.count, self.evs, ev).RaiseIfError;
    self.Release;
  end else
    ev := self[0];
  
  cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, __NativUtils.GCHndAlloc(cb)).RaiseIfError;
  Result := ev;
end;

static function CommandQueueBase.CreateUserEvent(c: Context): cl_event;
begin
  var ec: ErrorCode;
  Result := cl.CreateUserEvent(c._context, ec);
  ec.RaiseIfError;
end;

{$endregion Misc}

{$region CommandQueue}

{$region ConstQueue}

static function CommandQueueBase.operator implicit(o: object): CommandQueueBase :=
new ConstQueue<object>(o);

static function CommandQueue<T>.operator implicit(o: T): CommandQueue<T> :=
new ConstQueue<T>(o);

{$endregion ConstQueue}

{$region Cast}

type
  CastQueue<T> = sealed class(__ContainerQueue<T>)
    private q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) := self.q := q;
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override :=
    __QueueRes&<T>( q.InvokeBase(cont, c, cq, prev_ev).LazyQuickTransformBase(o->T(o)) );
    
  end;
  
function CommandQueueBase.Cast<T>: CommandQueue<T>;
begin
  Result := self as CommandQueue<T>;
  if Result=nil then Result := new CastQueue<T>(self);
end;

{$endregion Cast}

{$region HostFunc}

type
  CommandQueueHostFuncBase<T> = abstract class(__HostQueue<object,T>)
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<object>; override;
    begin
      Result.ev := prev_ev;
    end;
    
  end;
  
  CommandQueueHostFunc<T> = sealed class(CommandQueueHostFuncBase<T>)
    private f: ()->T;
    
    public constructor(f: ()->T) :=
    self.f := f;
    
    protected function ExecFunc(o: object; c: Context): T; override := f();
    
  end;
  CommandQueueHostFuncC<T> = sealed class(CommandQueueHostFuncBase<T>)
    private f: Context->T;
    
    public constructor(f: Context->T) :=
    self.f := f;
    
    protected function ExecFunc(o: object; c: Context): T; override := f(c);
    
  end;
  
  CommandQueueHostProc = sealed class(CommandQueueHostFuncBase<object>)
    private p: ()->();
    
    public constructor(p: ()->()) :=
    self.p := p;
    
    protected function ExecFunc(o: object; c: Context): object; override;
    begin
      p();
      Result := nil;
    end;
    
  end;
  CommandQueueHostProcС = sealed class(CommandQueueHostFuncBase<object>)
    private p: Context->();
    
    public constructor(p: Context->()) :=
    self.p := p;
    
    protected function ExecFunc(o: object; c: Context): object; override;
    begin
      p(c);
      Result := nil;
    end;
    
  end;
  
function HFQ<T>(f: ()->T) :=
new CommandQueueHostFunc<T>(f);
function HFQ<T>(f: Context->T) :=
new CommandQueueHostFuncC<T>(f);

function HPQ(p: ()->()) :=
new CommandQueueHostProc(p);
function HPQ(p: Context->()) :=
new CommandQueueHostProcС(p);

{$endregion HostFunc}

{$region ThenConvert}

type
  CommandQueueThenConvertBase<TInp,TRes> = abstract class(__HostQueue<TInp, TRes>)
    q: CommandQueue<TInp>;
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<TInp>; override :=
    q.Invoke(cont, c, cq, prev_ev);
    
  end;
  
  CommandQueueThenConvert<TInp,TRes> = sealed class(CommandQueueThenConvertBase<TInp,TRes>)
    private f: TInp->TRes;
    
    constructor(q: CommandQueue<TInp>; f: TInp->TRes);
    begin
      self.q := q;
      self.f := f;
    end;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o);
    
  end;
  CommandQueueThenConvertC<TInp,TRes> = sealed class(CommandQueueThenConvertBase<TInp,TRes>)
    private f: (TInp,Context)->TRes;
    
    constructor(q: CommandQueue<TInp>; f: (TInp,Context)->TRes);
    begin
      self.q := q;
      self.f := f;
    end;
    
    protected function ExecFunc(o: TInp; c: Context): TRes; override := f(o, c);
    
  end;
  
//function CommandQueueBase.ThenConvert<T>(f: object->T) :=
//self.Cast&<object>.ThenConvert(f);

//function CommandQueueBase.ThenConvert<T>(f: (object,Context)->T) :=
//self.Cast&<object>.ThenConvert(f);

function CommandQueue<T>.ThenConvert<T2>(f: T->T2): CommandQueue<T2>;
begin
  var scq := self as ConstQueue<T>;
  if scq=nil then
    Result := new CommandQueueThenConvert<T,T2>(self, f) else
    Result := new CommandQueueHostFunc<T2>(()->f(scq.res));
end;

function CommandQueue<T>.ThenConvert<T2>(f: (T,Context)->T2): CommandQueue<T2>;
begin
  var scq := self as ConstQueue<T>;
  if scq=nil then
    Result := new CommandQueueThenConvertC<T,T2>(self, f) else
    Result := new CommandQueueHostFuncC<T2>(c->f(scq.res, c));
end;

{$endregion ThenConvert}

{$region Multiusable}

type
  MultiusableCommandQueueHub<T> = sealed class
    public q: CommandQueue<T>;
    public constructor(q: CommandQueue<T>) := self.q := q;
    
    public function OnNodeInvoked(cont: __QueueExecContainer; c: Context): __QueueRes<T>;
    begin
      
      var res_o: __IQueueRes;
      if cont.mu_res.TryGetValue(self, res_o) then
        Result := __QueueRes&<T>( res_o ) else
      begin
        Result := self.q.InvokeNewQ(cont, c);
        cont.mu_res.Add(self, Result);
      end;
      
      Result.ev.Retain;
    end;
    
    public function MakeNode: CommandQueue<T>;
    
  end;
  
  MultiusableCommandQueueNode<T> = sealed class(__ContainerQueue<T>)
    public hub: MultiusableCommandQueueHub<T>;
    public constructor(hub: MultiusableCommandQueueHub<T>) := self.hub := hub;
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      Result := hub.OnNodeInvoked(cont, c);
      Result.ev := prev_ev + Result.ev;
    end;
    
  end;
  
function MultiusableCommandQueueHub<T>.MakeNode :=
new MultiusableCommandQueueNode<T>(self);

function CommandQueue<T>.Multiusable(n: integer): array of CommandQueue<T>;
begin
  if self is ConstQueue<T> then
    Result := ArrFill(n, self) else
  begin
    var hub := new MultiusableCommandQueueHub<T>(self);
    Result := ArrGen(n, i->hub.MakeNode());
  end;
end;

function CommandQueue<T>.Multiusable: ()->CommandQueue<T>;
begin
  if self is ConstQueue<T> then
    Result := ()->self else
  begin
    var hub := new MultiusableCommandQueueHub<T>(self);
    Result := hub.MakeNode;
  end;
end;

{$endregion Multiusable}

{$region Sync/Async Base}

type
  IQueueArray = interface
    function GetQS: sequence of CommandQueueBase;
  end;
  
  {$region Sync}
  
  SimpleQueueArray<T> = abstract class(__ContainerQueue<T>, IQueueArray)
    private qs: array of CommandQueueBase;
    
    public function GetQS: sequence of CommandQueueBase := qs;
    
    public constructor(qs: array of CommandQueueBase) := self.qs := qs;
    
  end;
  
  {$endregion Sync}
  
  {$region Async}
  
  HQAExecutor<T> = abstract class //ToDo #issue не дающая сделать __QueueRes<T> в результате
    
    /// синхронно или асинхронно запускает очереди qs и возвращает общий для них ивент в _prev_ev
    protected function WorkOn(qs: array of CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var _prev_ev: __EventList): array of __QueueRes<T>; abstract;
    
  end;
  
  HQAExecutorSync<T> = sealed class(HQAExecutor<T>)
    
    protected function WorkOn(qs: array of CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var _prev_ev: __EventList): array of __QueueRes<T>; override;
    begin
      var prev_ev := _prev_ev;
      Result := new __QueueRes<T>[qs.Length];
      
      for var i := 0 to qs.Length-1 do
      begin
        var r := qs[i].Invoke(cont, c, cq, prev_ev);
        prev_ev := r.ev;
        Result[i] := r;
      end;
      
      _prev_ev := prev_ev;
    end;
    
  end;
  HQAExecutorAsync<T> = sealed class(HQAExecutor<T>)
    
    protected function WorkOn(qs: array of CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var _prev_ev: __EventList): array of __QueueRes<T>; override;
    begin
      var prev_ev := _prev_ev;
      Result := new __QueueRes<T>[qs.Length];
      
      var evs := new __EventList[qs.Length];
      var count := 0;
      
      for var i := 0 to qs.Length-1 do
      begin
        var ncq := cl_command_queue.Zero;
        prev_ev.Retain;
        var res := qs[i].Invoke(cont, c, ncq, prev_ev);
        Result[i].res := res.res;
        Result[i].res_f := res.res_f;
        
        var CQFree: Action := ()->
        begin
          if ncq<>cl_command_queue.Zero then cl.ReleaseCommandQueue(ncq); //ToDo cont.AddErr
        end;
        
        if res.ev.count=0 then
          Task.Run(CQFree) else
          res.ev := res.ev.AttachCallback((_ev,_st,_data)->
          begin
            //ToDo cont.AddErr( _st );
            Task.Run(CQFree);
            __NativUtils.GCHndFree(_data);
          end, c, ncq);
        
        evs[i] := res.ev;
        count += res.ev.count;
      end;
      prev_ev.Release;
      
      prev_ev := new __EventList(count);
      foreach var ev in evs do
        prev_ev += ev;
      
      _prev_ev := prev_ev;
    end;
    
  end;
  
  HostQueueArrayBase<TInp,TRes> = abstract class(__HostQueue<array of TInp, TRes>, IQueueArray)
    private qs: array of CommandQueue<TInp>;
    private executor: HQAExecutor<TInp>;
    
    protected procedure InitExecutor(is_sync: boolean) :=
    self.executor := is_sync ? new HQAExecutorSync<TInp> as HQAExecutor<TInp> : new HQAExecutorAsync<TInp>; //ToDo #issue лишний as
    
    public function GetQS: sequence of CommandQueueBase := qs.Cast&<CommandQueueBase>;
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<array of TInp>; override;
    begin
      var res := executor.WorkOn(qs, cont, c, cq, prev_ev);
      
      if res.Any(qr->qr.res_f<>nil) then
      begin
        var res_ref := res;
        
        Result.res_f := ()->
        begin
          var res := new TInp[res_ref.Length];
          for var i := 0 to res_ref.Length-1 do
            res[i] := res_ref[i].Get();
          Result := res;
        end;
        
      end else
      begin
        Result.res := new TInp[res.Length];
        for var i := 0 to res.Length-1 do
          Result.res[i] := res[i].res;
      end;
      
      Result.ev := prev_ev;
    end;
    
  end;
  
  HostQueueArray<TInp,TRes> = sealed class(HostQueueArrayBase<TInp,TRes>)
    private conv: Func<array of TInp, TRes>;
    
    protected constructor(qs: array of CommandQueue<TInp>; conv: Func<array of TInp, TRes>; is_sync: boolean);
    begin
      self.qs := qs;
      self.conv := conv;
      InitExecutor(is_sync);
    end;
    
    protected function ExecFunc(a: array of TInp; c: Context): TRes; override := conv(a);
    
  end;
  HostQueueArrayC<TInp,TRes> = sealed class(HostQueueArrayBase<TInp,TRes>)
    private conv: Func<array of TInp, Context, TRes>;
    
    protected constructor(qs: array of CommandQueue<TInp>; conv: Func<array of TInp, Context, TRes>; is_sync: boolean);
    begin
      self.qs := qs;
      self.conv := conv;
      InitExecutor(is_sync);
    end;
    
    protected function ExecFunc(a: array of TInp; c: Context): TRes; override := conv(a, c);
    
  end;
  
  {$endregion Async}
  
function FlattenQueueArray<T>(inp: sequence of CommandQueueBase): array of CommandQueueBase; where T: IQueueArray;
begin
  var enmr := inp.GetEnumerator;
  if not enmr.MoveNext then raise new InvalidOperationException('inp Empty');
  
  var res := new List<CommandQueueBase>;
  while true do
  begin
    var curr := enmr.Current;
    var next := enmr.MoveNext;
    
    if not (curr is IConstQueue) or not next then
      if curr as object is T(var sqa) then //ToDo #2146
        res.AddRange(sqa.GetQS) else
        res += curr;
    
    if not next then break;
  end;
  
  Result := res.ToArray;
end;

{$endregion Sync/Async Base}

{$region SyncArray}

type
  CommandQueueSyncArray<T> = sealed class(SimpleQueueArray<T>)
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      
      for var i := 0 to qs.Length-2 do
        prev_ev := qs[i].InvokeBase(cont, c, cq, prev_ev).GetEv;
      
      Result := (qs[qs.Length-1] as CommandQueue<T>).Invoke(cont, c, cq, prev_ev);
    end;
    
  end;
  
static function CommandQueueBase.operator+(q1, q2: CommandQueueBase): CommandQueueBase :=
CombineSyncQueueBase(q1,q2);
static function CommandQueueBase.operator+<T>(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T> :=
CombineSyncQueue&<T>(q1,q2);

{$region NonConv}

function __CombineSyncQueue<T>(qss: sequence of CommandQueueBase): CommandQueue<T>;
begin
  var qs := FlattenQueueArray&<CommandQueueSyncArray<T>>(qss);
  qs[qs.Length-1] := qs[qs.Length-1].Cast&<T>;
  
  if qs.Length=1 then
    Result := qs[0] else
    Result := new CommandQueueSyncArray<T>(qs);
  
end;

function CombineSyncQueueBase(qs: sequence of CommandQueueBase) :=
__CombineSyncQueue&<object>(qs);

function CombineSyncQueueBase(params qs: array of CommandQueueBase) :=
__CombineSyncQueue&<object>(qs);

function CombineSyncQueue<T>(qs: sequence of CommandQueueBase) :=
__CombineSyncQueue&<T>(qs);

function CombineSyncQueue<T>(params qs: array of CommandQueueBase) :=
__CombineSyncQueue&<T>(qs);

function CombineSyncQueue<T>(qs: sequence of CommandQueue<T>) :=
__CombineSyncQueue&<T>(qs.Cast&<CommandQueueBase>);

function CombineSyncQueue<T>(params qs: array of CommandQueue<T>) :=
__CombineSyncQueue&<T>(qs.Cast&<CommandQueueBase>);

{$endregion NonConv}

{$region Conv}

{$region NoContext}

function CombineSyncQueue<TRes>(conv: Func<array of object, TRes>; qs: sequence of CommandQueueBase) :=
new HostQueueArray<object,TRes>(qs.Select(q->q.Cast&<object>).ToArray, conv, true);

function CombineSyncQueue<TRes>(conv: Func<array of object, TRes>; params qs: array of CommandQueueBase) :=
new HostQueueArray<object,TRes>(qs.ConvertAll(q->q.Cast&<object>), conv, true);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; qs: sequence of CommandQueue<TInp>) :=
new HostQueueArray<TInp,TRes>(qs.ToArray, conv, true);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; params qs: array of CommandQueue<TInp>) :=
new HostQueueArray<TInp,TRes>(qs.ToArray, conv, true);

{$endregion NoContext}

{$region Context}

function CombineSyncQueue<TRes>(conv: Func<array of object, Context, TRes>; qs: sequence of CommandQueueBase) :=
new HostQueueArrayC<object,TRes>(qs.Select(q->q.Cast&<object>).ToArray, conv, true);

function CombineSyncQueue<TRes>(conv: Func<array of object, Context, TRes>; params qs: array of CommandQueueBase) :=
new HostQueueArrayC<object,TRes>(qs.ConvertAll(q->q.Cast&<object>), conv, true);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; qs: sequence of CommandQueue<TInp>) :=
new HostQueueArrayC<TInp,TRes>(qs.ToArray, conv, true);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; params qs: array of CommandQueue<TInp>) :=
new HostQueueArrayC<TInp,TRes>(qs.ToArray, conv, true);

{$endregion Context}

{$endregion Conv}

{$endregion SyncArray}

{$region AsyncArray}

type
  CommandQueueAsyncArray<T> = sealed class(SimpleQueueArray<T>)
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      
      var evs := new __EventList[qs.Length-1];
      var count := 0;
      
      for var i := 0 to qs.Length-2 do
      begin
        var ncq := cl_command_queue.Zero;
        prev_ev.Retain;
        var ev := qs[i].InvokeBase(cont, c, ncq, prev_ev).GetEv;
        
        var CQFree: Action := ()->
        begin
          if ncq<>cl_command_queue.Zero then cl.ReleaseCommandQueue(ncq); //ToDo cont.AddErr
        end;
        
        if ev.count=0 then
          Task.Run(CQFree) else
          ev := ev.AttachCallback((_ev,_st,_data)->
          begin
            //ToDo cont.AddErr( _st );
            Task.Run(CQFree);
            __NativUtils.GCHndFree(_data);
          end, c, ncq);
        
        evs[i] := ev;
        count += ev.count;
      end;
      
      // ничего страшного что 1 из веток использует внешний cq, пока только 1. Так даже эффективнее
      prev_ev.Retain;
      Result := (qs[qs.Length-1] as CommandQueue<T>).Invoke(cont, c, cq, prev_ev);
      var res_ev := Result.ev;
      prev_ev.Release;
      
      Result.ev := new __EventList(count+res_ev.count);
      foreach var ev in evs do Result.ev += ev;
      Result.ev += res_ev;
      
    end;
    
  end;
  
static function CommandQueueBase.operator*(q1, q2: CommandQueueBase): CommandQueueBase :=
CombineAsyncQueueBase(q1,q2);
static function CommandQueueBase.operator*<T>(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T> :=
CombineAsyncQueue&<T>(q1,q2);

{$region NonConv}

function __CombineAsyncQueue<T>(qss: sequence of CommandQueueBase): CommandQueue<T>;
begin
  var qs := FlattenQueueArray&<CommandQueueAsyncArray<T>>(qss);
  qs[qs.Length-1] := qs[qs.Length-1].Cast&<T>;
  
  if qs.Length=1 then
    Result := qs[0] else
    Result := new CommandQueueAsyncArray<T>(qs);
  
end;

function CombineAsyncQueueBase(qs: sequence of CommandQueueBase) :=
__CombineAsyncQueue&<object>(qs);

function CombineAsyncQueueBase(params qs: array of CommandQueueBase) :=
__CombineAsyncQueue&<object>(qs);

function CombineAsyncQueue<T>(qs: sequence of CommandQueueBase) :=
__CombineAsyncQueue&<T>(qs);

function CombineAsyncQueue<T>(params qs: array of CommandQueueBase) :=
__CombineAsyncQueue&<T>(qs);

function CombineAsyncQueue<T>(qs: sequence of CommandQueue<T>) :=
__CombineAsyncQueue&<T>(qs.Cast&<CommandQueueBase>);

function CombineAsyncQueue<T>(params qs: array of CommandQueue<T>) :=
__CombineAsyncQueue&<T>(qs.Cast&<CommandQueueBase>);

{$endregion NonConv}

{$region Conv}

{$region NoContext}

function CombineAsyncQueue<TRes>(conv: Func<array of object, TRes>; qs: sequence of CommandQueueBase) :=
new HostQueueArray<object,TRes>(qs.Select(q->q.Cast&<object>).ToArray, conv, false);

function CombineAsyncQueue<TRes>(conv: Func<array of object, TRes>; params qs: array of CommandQueueBase) :=
new HostQueueArray<object,TRes>(qs.ConvertAll(q->q.Cast&<object>), conv, false);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; qs: sequence of CommandQueue<TInp>) :=
new HostQueueArray<TInp,TRes>(qs.ToArray, conv, false);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; params qs: array of CommandQueue<TInp>) :=
new HostQueueArray<TInp,TRes>(qs.ToArray, conv, false);

{$endregion NoContext}

{$region Context}

function CombineAsyncQueue<TRes>(conv: Func<array of object, Context, TRes>; qs: sequence of CommandQueueBase) :=
new HostQueueArrayC<object,TRes>(qs.Select(q->q.Cast&<object>).ToArray, conv, false);

function CombineAsyncQueue<TRes>(conv: Func<array of object, Context, TRes>; params qs: array of CommandQueueBase) :=
new HostQueueArrayC<object,TRes>(qs.ConvertAll(q->q.Cast&<object>), conv, false);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; qs: sequence of CommandQueue<TInp>) :=
new HostQueueArrayC<TInp,TRes>(qs.ToArray, conv, false);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; params qs: array of CommandQueue<TInp>) :=
new HostQueueArrayC<TInp,TRes>(qs.ToArray, conv, false);

{$endregion Context}

{$endregion Conv}

{$endregion AsyncArray}

{$region Wait}

type
  WCQWaiter = abstract class
    waitables: array of CommandQueueBase;
    
    constructor(waitables: array of CommandQueueBase);
    begin
      foreach var q in waitables do q.MakeWaitable;
      self.waitables := waitables;
    end;
    
    function GetWaitEv(cont: __QueueExecContainer; c: Context): __EventList; abstract;
    
  end;
  
  WCQWaiterAll = sealed class(WCQWaiter)
    
    function GetWaitEv(cont: __QueueExecContainer; c: Context): __EventList; override;
    begin
      Result := new __EventList(waitables.Length);
      foreach var q in waitables do
        Result += q.GetMWEvent(c._context);
    end;
    
  end;
  WCQWaiterAny = sealed class(WCQWaiter)
    
    function GetWaitEv(cont: __QueueExecContainer; c: Context): __EventList; override;
    begin
      var uev := CommandQueueBase.CreateUserEvent(c);
      
      foreach var q in waitables do
      begin
        var ev := q.GetMWEvent(c._context);
        
        var done := false;
        var lo := new object;
        var cb: Event_Callback := (ev,st,data)->
        begin
          
          lock lo do if not done then
          begin
            var ec := cl.SetUserEventStatus(uev,CommandExecutionStatus.COMPLETE);
            if ec.val<0 then cont.AddErr(new OpenCLException( ec.ToString ));
            done := true;
          end;
          
          __NativUtils.GCHndFree(data);
        end;
        
        cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, __NativUtils.GCHndAlloc(cb));
        cl.ReleaseEvent(ev).RaiseIfError;
      end;
      
      Result := uev;
    end;
    
  end;
  
  CommandQueueWaitFor = sealed class(__ContainerQueue<object>)
    public waiter: WCQWaiter;
    
    public constructor(waiter: WCQWaiter) :=
    self.waiter := waiter;
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<object>; override;
    begin
      Result.ev := waiter.GetWaitEv(cont, c);
    end;
    
  end;
  CommandQueueThenWaitFor<T> = sealed class(__ContainerQueue<T>)
    public waiter: WCQWaiter;
    public q: CommandQueue<T>;
    
    public constructor(waiter: WCQWaiter; q: CommandQueue<T>);
    begin
      self.waiter := waiter;
      self.q := q;
    end;
    
    protected function InvokeSubQs(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      Result := q.Invoke(cont, c, cq, prev_ev);
      Result.ev := waiter.GetWaitEv(cont, c) + Result.ev;
    end;
    
  end;
  
function WaitFor(q: CommandQueueBase) := WaitForAll(q);

function WaitForAll(params qs: array of CommandQueueBase) := WaitForAll(qs.AsEnumerable);
function WaitForAll(qs: sequence of CommandQueueBase) :=
new CommandQueueWaitFor(
  new WCQWaiterAll(
    qs.ToArray
  )
);

function WaitForAny(params qs: array of CommandQueueBase) := WaitForAny(qs.AsEnumerable);
function WaitForAny(qs: sequence of CommandQueueBase) :=
new CommandQueueWaitFor(
  new WCQWaiterAny(
    qs.ToArray
  )
);

function CommandQueue<T>.CreateWaitWrapper(qs: sequence of CommandQueueBase; all: boolean): CommandQueue<T> :=
new CommandQueueThenWaitFor<T>(
  all?
    new WCQWaiterAll(qs.ToArray) as WCQWaiter :
    new WCQWaiterAny(qs.ToArray),
  self
);

{$endregion Wait}

{$region GPUCommand}

{$region GPUCommandContainerBody}

type
  __CCBObj<T> = sealed class(__GPUCommandContainerBody<T>)
    public o: T;
    
    public constructor(o: T; cc: __GPUCommandContainer<T>);
    begin
      self.o := o;
      self.cc := cc;
    end;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      var res := self.o;
      
      if res as object is Buffer(var b) then
        if b.memobj=cl_mem.Zero then
          b.Init(c);
      
      foreach var comm in cc.commands do
        prev_ev := comm.InvokeObj(res, cont, c, cq, prev_ev);
      
      Result.ev := prev_ev;
      Result.res := res;
    end;
    
  end;
  
  __CCBQueue<T> = sealed class(__GPUCommandContainerBody<T>)
    public hub: MultiusableCommandQueueHub<T>;
    
    public constructor(q: CommandQueue<T>; cc: __GPUCommandContainer<T>);
    begin
      self.hub := new MultiusableCommandQueueHub<T>(q);
      self.cc := cc;
    end;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __QueueRes<T>; override;
    begin
      var new_plug: ()->CommandQueue<T> := hub.MakeNode;
      
      foreach var comm in cc.commands do
        prev_ev := comm.InvokeQueue(new_plug, cont, c, cq, prev_ev);
      
      Result := new_plug().Invoke(cont, c, cq, prev_ev);
    end;
    
  end;
  
constructor __GPUCommandContainer<T>.Create(o: T) :=
self.body := new __CCBObj<T>(o, self);

constructor __GPUCommandContainer<T>.Create(q: CommandQueue<T>) :=
if q is ConstQueue<T>(var cq) then
  self.body := new __CCBObj<T>(cq.Val, self) else
  self.body := new __CCBQueue<T>(q, self);

function BufferCommandQueue.GetSizeQ: CommandQueue<integer>;
begin
  var ob := self.body as __CCBObj<Buffer>;
  if ob<>nil then
    Result := integer(ob.o.Size32) else
    Result := (self.body as __CCBQueue<Buffer>).hub.MakeNode.ThenConvert(b->integer(b.Size32));
end;

{$endregion GPUCommandContainerBody}

{$region QueueCommand}

type
  QueueCommand<T> = sealed class(__GPUCommand<T>)
    public q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) :=
    self.q := q;
    
    protected function InvokeObj(o: T; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    q.InvokeBase(cont, c, cq, prev_ev).GetEv;
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    q.InvokeBase(cont, c, cq, prev_ev).GetEv;
    
  end;
  
procedure __GPUCommandContainer<T>.InternalAddQueue(q: CommandQueueBase) :=
commands.Add( new QueueCommand<T>(q) );

{$endregion QueueCommand}

{$region ProcCommand}

type
  ProcCommandBase<T> = abstract class(__GPUCommand<T>)
    
    protected procedure ExecProc(c: Context; o: T); abstract;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_res: __QueueRes<T>): cl_event;
    begin
      var uev := CommandQueueBase.CreateUserEvent(c);
      
      Thread.Create(()->
      try
        self.ExecProc(c, prev_res.WaitAndGet);
        cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      except
        on e: Exception do
        begin
          cont.AddErr(e);
          cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        end;
      end).Start;
      
      Result := uev;
    end;
    
    protected function InvokeObj(o: T; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      var prev_res: __QueueRes<T>;
      prev_res.res := o;
      prev_res.ev := prev_ev;
      Result := Invoke(cont, c, cq, prev_res);
    end;
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    Invoke(cont, c, cq, o_q().Invoke(cont, c, cq, prev_ev));
    
  end;
  
  ProcCommand<T> = sealed class(ProcCommandBase<T>)
    public p: T->();
    
    public constructor(p: T->()) := self.p := p;
    
    protected procedure ExecProc(c: Context; o: T); override := p(o);
    
  end;
  ProcCommandC<T> = sealed class(ProcCommandBase<T>)
    public p: (T,Context)->();
    
    public constructor(p: (T,Context)->()) := self.p := p;
    
    protected procedure ExecProc(c: Context; o: T); override := p(o, c);
    
  end;
  
procedure __GPUCommandContainer<T>.InternalAddProc(p: T->()) :=
commands.Add( new ProcCommand<T>(p) );

procedure __GPUCommandContainer<T>.InternalAddProc(p: (T,Context)->()) :=
commands.Add( new ProcCommandC<T>(p) );

{$endregion ProcCommand}

{$region WaitCommand}

type
  WaitCommand<T> = sealed class(__GPUCommand<T>)
    public waiter: WCQWaiter;
    
    public constructor(waiter: WCQWaiter) :=
    self.waiter := waiter;
    
    protected function InvokeObj(o: T; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    waiter.GetWaitEv(cont, c) + prev_ev;
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    waiter.GetWaitEv(cont, c) + prev_ev;
    
  end;
  
procedure __GPUCommandContainer<T>.InternalAddWaitAll(qs: sequence of CommandQueueBase) :=
commands.Add(new WaitCommand<T>( new WCQWaiterAll(qs.ToArray) ));

procedure __GPUCommandContainer<T>.InternalAddWaitAny(qs: sequence of CommandQueueBase) :=
commands.Add(new WaitCommand<T>( new WCQWaiterAny(qs.ToArray) ));

{$endregion WaitCommand}

{$region EnqueueableGPUCommand}

type
  EnqueueableGPUCommand<T> = abstract class(__GPUCommand<T>)
    protected allow_sync_enq := true;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (T, Context, cl_command_queue, __EventList)->cl_event; abstract;
    
    protected procedure FixCQ(c: Context; var cq: cl_command_queue) :=
    if cq=cl_command_queue.Zero then
    begin
      var ec: ErrorCode;
      cq := cl.CreateCommandQueue(c._context, c._device, CommandQueuePropertyFlags.NONE, ec);
      ec.RaiseIfError;
    end;
    
    protected function Invoke(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList; o_res: __QueueRes<T>): __EventList;
    begin
      var enq_f := InvokeParams(cont, c, cq, o_res.ev);
      
      if allow_sync_enq and (o_res.ev.count=0) then
        Result := enq_f(o_res.Get, c, cq, prev_ev) else
      begin
        var uev := CommandQueueBase.CreateUserEvent(c);
        
        // Асинхронное Enqueue, придётся пересоздать cq
        var lcq := cq;
        cq := cl_command_queue.Zero;
        
        if not allow_sync_enq then
          Thread.Create(()->
          begin
            
            try
              
              if prev_ev.count<>0 then
              begin
                cl.WaitForEvents(prev_ev.count,prev_ev.evs).RaiseIfError;
                prev_ev.Release;
              end;
              
              enq_f(o_res.WaitAndGet, c, lcq, nil);
              cl.ReleaseCommandQueue(lcq).RaiseIfError;
            except
              on e: Exception do cont.AddErr(e);
            end;
            
            cl.SetUserEventStatus(uev,CommandExecutionStatus.COMPLETE).RaiseIfError;
          end).Start else
        begin
          
          var set_complete: Event_Callback := (ev,st,data)->
          begin
            if st.IS_ERROR then cont.AddErr( new OpenCLException(st.GetError.ToString) );
            
            Task.Run(()->
            begin
              cl.ReleaseCommandQueue(lcq).RaiseIfError; //ToDo cont.AddErr
            end);
            
            cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE);
            
            __NativUtils.GCHndFree(data);
          end;
          
          cl.ReleaseEvent(o_res.ev.AttachCallback((ev,st,data)->
          begin
            if st.IS_ERROR then cont.AddErr( new OpenCLException(st.GetError.ToString) );
            
            cl.SetEventCallback(
              enq_f(o_res.Get, c, lcq, prev_ev),
              CommandExecutionStatus.COMPLETE,
              set_complete,
              __NativUtils.GCHndAlloc(set_complete)
            );
            
            __NativUtils.GCHndFree(data);
          end, c, lcq)).RaiseIfError;
          
        end;
        
        Result := uev;
      end;
      
    end;
    
    protected function InvokeObj(o: T; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      var o_res: __QueueRes<T>;
      o_res.res := o;
      o_res.ev := new __EventList;
      Result := Invoke(cont, c, cq, prev_ev, o_res);
    end;
    
    protected function InvokeQueue(o_q: ()->CommandQueue<T>; cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    Invoke(cont, c, cq, new __EventList, o_q().Invoke(cont, c, cq, prev_ev));
    
  end;
  
{$endregion DirectGPUCommandBase}

{$endregion GPUCommand}

{$region Buffer}

{$region BufferCommandQueue}

//ToDo попробовать исправить нормально
function костыль_BufferCommandQueue_Create(b: Buffer; c: Context): Buffer;
begin
  if b.memobj=cl_mem.Zero then b.Init(c);
  Result := b;
end;

constructor BufferCommandQueue.Create(q: CommandQueue<Buffer>) :=
inherited Create(q.ThenConvert(костыль_BufferCommandQueue_Create));

{$endregion BufferCommandQueue}

{$region Write}

type
  BufferCommandWriteData = sealed class(EnqueueableGPUCommand<Buffer>)
    public ptr_q: CommandQueue<IntPtr>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(ptr_q: CommandQueue<IntPtr>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.ptr_q    := ptr_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var ptr     := ptr_q    .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, ptr.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, 0,
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          ptr.Get,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
  BufferCommandWriteArray = sealed class(EnqueueableGPUCommand<Buffer>)
    public a_q: CommandQueue<&Array>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(a_q: CommandQueue<&Array>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.allow_sync_enq := false;
      self.a_q      := a_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var a       := a_q      .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, a.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, 1,
          new UIntPtr(offset.WaitAndGet), new UIntPtr(len.WaitAndGet),
          Marshal.UnsafeAddrOfPinnedArrayElement(a.WaitAndGet,0),
          0,nil,nil
        ).RaiseIfError;
        
        Result := cl_event.Zero;
      end;
      
    end;
    
  end;
  
  BufferCommandWriteValue<T> = sealed class(EnqueueableGPUCommand<Buffer>) where T: record;
    public val: IntPtr;
    public offset_q: CommandQueue<integer>;
    
    public constructor(val: T; offset_q: CommandQueue<integer>);
    begin
      self.val      := new IntPtr(__NativUtils.CopyToUnm(val)); //ToDo так же остальным BufferCommand*Value
      self.offset_q := offset_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, offset.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, 0,
          new UIntPtr(offset.Get), new UIntPtr(Marshal.SizeOf&<T>),
          self.val,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
    protected procedure Finalize; override :=
    Marshal.FreeHGlobal(self.val);
    
  end;
  BufferCommandWriteValueQ<T> = sealed class(EnqueueableGPUCommand<Buffer>) where T: record;
    public val_q: CommandQueue<T>;
    public offset_q: CommandQueue<integer>;
    
    public constructor(val_q: CommandQueue<T>; offset_q: CommandQueue<integer>);
    begin
      self.val_q    := val_q;
      self.offset_q := offset_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var val     := val_q    .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, val.ev, offset.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var l_val := val.Get; //ToDo плохо, надо копировать в неуправляемую область памяти
        
        cl.EnqueueWriteBuffer(
          l_cq, b.memobj, 0,
          new UIntPtr(offset.Get), new UIntPtr(Marshal.SizeOf&<T>),
          new IntPtr(@l_val),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
  
function BufferCommandQueue.AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteData(ptr, offset, len));


function BufferCommandQueue.AddWriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteArray(a, offset, len));


function BufferCommandQueue.AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValue<TRecord>(val, offset));

function BufferCommandQueue.AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValueQ<TRecord>(val, offset));

{$endregion Write}

{$region Read}

type
  BufferCommandReadData = sealed class(EnqueueableGPUCommand<Buffer>)
    public ptr_q: CommandQueue<IntPtr>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(ptr_q: CommandQueue<IntPtr>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.ptr_q    := ptr_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var ptr     := ptr_q    .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, ptr.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueReadBuffer(
          l_cq, b.memobj, 0,
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          ptr.Get,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
  BufferCommandReadArray = sealed class(EnqueueableGPUCommand<Buffer>)
    public a_q: CommandQueue<&Array>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(a_q: CommandQueue<&Array>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.allow_sync_enq := false;
      self.a_q      := a_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var a       := a_q      .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, a.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        
        cl.EnqueueReadBuffer(
          l_cq, b.memobj, 1,
          new UIntPtr(offset.WaitAndGet), new UIntPtr(len.WaitAndGet),
          Marshal.UnsafeAddrOfPinnedArrayElement(a.WaitAndGet,0),
          0,nil,nil
        ).RaiseIfError;
        
        Result := cl_event.Zero;
      end;
      
    end;
    
  end;
  
  
function BufferCommandQueue.AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadData(ptr, offset, len));


function BufferCommandQueue.AddReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadArray(a, offset, len));

{$endregion Read}

{$region Fill}

type
  BufferCommandDataFill = sealed class(EnqueueableGPUCommand<Buffer>)
    public ptr_q: CommandQueue<IntPtr>;
    public pattern_len_q, offset_q, len_q: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; pattern_len_q, offset_q, len_q: CommandQueue<integer>);
    begin
      self.ptr_q          := ptr_q;
      self.pattern_len_q  := pattern_len_q;
      self.offset_q       := offset_q;
      self.len_q          := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var ptr         := ptr_q        .Invoke(cont, c, cq, new __EventList);
      var pattern_len := pattern_len_q.Invoke(cont, c, cq, new __EventList);
      var offset      := offset_q     .Invoke(cont, c, cq, new __EventList);
      var len         := len_q        .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, ptr.ev, pattern_len.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          ptr.Get, new UIntPtr(pattern_len.Get),
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          prev_ev.count, prev_ev.evs, res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
  BufferCommandArrayFill = sealed class(EnqueueableGPUCommand<Buffer>)
    public a_q: CommandQueue<&Array>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(a_q: CommandQueue<&Array>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.allow_sync_enq := false;
      self.a_q      := a_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var a       := a_q      .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, a.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var la := a.WaitAndGet;
        
        // Синхронного Fill нету, поэтому между cl.Enqueue и cl.WaitForEvents сборщик мусора может сломать указатель
        // Остаётся только закреплять, хоть так и не любой тип массива пропустит
        var a_hnd := GCHandle.Alloc(la, GCHandleType.Pinned);
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          a_hnd.AddrOfPinnedObject, new UIntPtr(System.Buffer.ByteLength(la)),
          new UIntPtr(offset.WaitAndGet), new UIntPtr(len.WaitAndGet),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        cl.WaitForEvents(1,@res_ev);
        cl.ReleaseEvent(res_ev);
        
        a_hnd.Free; // можно и в callback засунуть, но от этого не сильно лучше
        Result := cl_event.Zero;
      end;
      
    end;
    
  end;
  
  BufferCommandValueFill<T> = sealed class(EnqueueableGPUCommand<Buffer>)
    public val: object;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(val: T; offset_q, len_q: CommandQueue<integer>);
    begin
      self.val      := val;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var l_val := T(val);
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          new IntPtr(@l_val), new UIntPtr(Marshal.SizeOf&<T>),
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  BufferCommandValueFillQ<T> = sealed class(EnqueueableGPUCommand<Buffer>)
    public val_q: CommandQueue<T>;
    public offset_q, len_q: CommandQueue<integer>;
    
    public constructor(val_q: CommandQueue<T>; offset_q, len_q: CommandQueue<integer>);
    begin
      self.val_q    := val_q;
      self.offset_q := offset_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var val     := val_q    .Invoke(cont, c, cq, new __EventList);
      var offset  := offset_q .Invoke(cont, c, cq, new __EventList);
      var len     := len_q    .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, val.ev, offset.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var l_val := val.Get;
        
        cl.EnqueueFillBuffer(
          l_cq, b.memobj,
          new IntPtr(@l_val), new UIntPtr(Marshal.SizeOf&<T>),
          new UIntPtr(offset.Get), new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
  
function BufferCommandQueue.AddFillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandDataFill(ptr,pattern_len, offset,len));


function BufferCommandQueue.AddFillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandArrayFill(a, offset,len));


function BufferCommandQueue.AddFillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFill<TRecord>(val, offset, len));

function BufferCommandQueue.AddFillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFillQ<TRecord>(val, offset, len));

{$endregion Fill}

{$region Copy}

type
  BufferCommandCopyFrom = sealed class(EnqueueableGPUCommand<Buffer>)
    public buf_q: CommandQueue<Buffer>;
    public f_pos_q, t_pos_q, len_q: CommandQueue<integer>;
    
    public constructor(buf_q: CommandQueue<Buffer>; f_pos_q, t_pos_q, len_q: CommandQueue<integer>);
    begin
      self.buf_q    := buf_q;
      self.f_pos_q  := f_pos_q;
      self.t_pos_q  := t_pos_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var buf   := buf_q  .Invoke(cont, c, cq, new __EventList);
      var f_pos := f_pos_q.Invoke(cont, c, cq, new __EventList);
      var t_pos := t_pos_q.Invoke(cont, c, cq, new __EventList);
      var len   := len_q  .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, buf.ev, f_pos.ev, t_pos.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        var b2 := buf.Get;
        if b2.memobj=cl_mem.Zero then b2.Init(l_c);
        
        cl.EnqueueCopyBuffer(
          l_cq, b2.memobj,b.memobj,
          new UIntPtr(f_pos.Get), new UIntPtr(t_pos.Get),
          new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs, res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  BufferCommandCopyTo = sealed class(EnqueueableGPUCommand<Buffer>)
    public buf_q: CommandQueue<Buffer>;
    public f_pos_q, t_pos_q, len_q: CommandQueue<integer>;
    
    public constructor(buf_q: CommandQueue<Buffer>; f_pos_q, t_pos_q, len_q: CommandQueue<integer>);
    begin
      self.buf_q    := buf_q;
      self.f_pos_q  := f_pos_q;
      self.t_pos_q  := t_pos_q;
      self.len_q    := len_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Buffer, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var buf   := buf_q  .Invoke(cont, c, cq, new __EventList);
      var f_pos := f_pos_q.Invoke(cont, c, cq, new __EventList);
      var t_pos := t_pos_q.Invoke(cont, c, cq, new __EventList);
      var len   := len_q  .Invoke(cont, c, cq, new __EventList);
      ev_res := __EventList.Combine(ev_res, buf.ev, f_pos.ev, t_pos.ev, len.ev);
      
      FixCQ(c, cq);
      
      Result := (b, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        
        var b2 := buf.Get;
        if b2.memobj=cl_mem.Zero then b2.Init(l_c);
        
        cl.EnqueueCopyBuffer(
          l_cq, b.memobj,b2.memobj,
          new UIntPtr(f_pos.Get), new UIntPtr(t_pos.Get),
          new UIntPtr(len.Get),
          prev_ev.count,prev_ev.evs, res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
function BufferCommandQueue.AddCopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopyFrom(b, from,&to, len));

function BufferCommandQueue.AddCopyTo(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopyTo(b, &to,from, len));

{$endregion Copy}

{$endregion Buffer}

{$region Kernel}

{$region Exec}

type
  KernelCommandExec = sealed class(EnqueueableGPUCommand<Kernel>)
    public work_szs_q: CommandQueue<array of UIntPtr>;
    public args_q: array of CommandQueue<Buffer>;
    
    public constructor(work_szs_q: CommandQueue<array of UIntPtr>; args_q: array of CommandQueue<Buffer>);
    begin
      self.work_szs_q := work_szs_q;
      self.args_q     := args_q;
    end;
    
    protected function InvokeParams(cont: __QueueExecContainer; c: Context; var cq: cl_command_queue; var ev_res: __EventList): (Kernel, Context, cl_command_queue, __EventList)->cl_event; override;
    begin
      var work_szs  := work_szs_q.Invoke(cont, c, cq, new __EventList);
      var count := ev_res.count + work_szs.ev.count;
      
      var args := new __QueueRes<Buffer>[args_q.Length];
      for var i := 0 to args.Length-1 do
      begin
        var arg := args_q[i].Invoke(cont, c, cq, new __EventList);
        count += arg.ev.count;
        args[i] := arg;
      end;
      
      var ev := new __EventList(count);
      ev += ev_res;
      ev += work_szs.ev;
      for var i := 0 to args.Length-1 do
        ev += args[i].ev;
      ev_res := ev;
      
      FixCQ(c, cq);
      
      Result := (k, l_c, l_cq, prev_ev)->
      begin
        var res_ev: cl_event;
        var work_szs_res := work_szs.Get;
        
        for var i := 0 to args.Length-1 do
        begin
          var b := args[i].Get;
          if b.memobj=cl_mem.Zero then b.Init(l_c);
          cl.SetKernelArg(k._kernel, i, new UIntPtr(UIntPtr.Size), b.memobj).RaiseIfError;
        end;
        
        cl.EnqueueNDRangeKernel(
          l_cq,k._kernel,
          work_szs_res.Length,
          nil,work_szs_res,nil,
          prev_ev.count,prev_ev.evs,res_ev
        ).RaiseIfError;
        
        Result := res_ev;
      end;
      
    end;
    
  end;
  
function KernelCommandQueue.AddExec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>) :=
AddCommand(new KernelCommandExec(work_szs, args));

function KernelCommandQueue.AddExec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) :=
AddCommand(new KernelCommandExec(
  CombineAsyncQueue(a->a,work_szs),
  args
));

function KernelCommandQueue.AddExec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>) :=
AddCommand(new KernelCommandExec(
  work_szs,
  args
));

function KernelCommandQueue.AddExec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>) :=
AddCommand(new KernelCommandExec(
  work_szs.ThenConvert(a->a.ConvertAll(sz->new UIntPtr(sz))),
  args
));

{$endregion Exec}

{$endregion Kernel}

{$endregion CommandQueue}

{$region Неявные CommandQueue}

{$region Buffer}

{$region constructor's}

procedure Buffer.Init(c: Context) :=
lock self do
begin
  if self.memobj<>cl_mem.Zero then Dispose;
  GC.AddMemoryPressure(Size64);
  var ec: ErrorCode;
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
Context.Default.SyncInvoke(NewQueue.AddWriteData(ptr) as CommandQueue<Buffer>);
function Buffer.WriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddWriteData(ptr, offset, len) as CommandQueue<Buffer>);

function Buffer.WriteArray(a: CommandQueue<&Array>) :=
Context.Default.SyncInvoke(NewQueue.AddWriteArray(a) as CommandQueue<Buffer>);
function Buffer.WriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddWriteArray(a, offset, len) as CommandQueue<Buffer>);

function Buffer.WriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddWriteValue(val, offset) as CommandQueue<Buffer>);

{$endregion Write}

{$region Read}

function Buffer.ReadData(ptr: CommandQueue<IntPtr>) :=
Context.Default.SyncInvoke(NewQueue.AddReadData(ptr) as CommandQueue<Buffer>);
function Buffer.ReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddReadData(ptr, offset, len) as CommandQueue<Buffer>);

function Buffer.ReadArray(a: CommandQueue<&Array>) :=
Context.Default.SyncInvoke(NewQueue.AddReadArray(a) as CommandQueue<Buffer>);
function Buffer.ReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddReadArray(a, offset, len) as CommandQueue<Buffer>);

{$endregion Read}

{$region PatternFill}

function Buffer.FillData(ptr: CommandQueue<IntPtr>; pattern_len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddFillData(ptr, pattern_len) as CommandQueue<Buffer>);
function Buffer.FillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddFillData(ptr, pattern_len, offset, len) as CommandQueue<Buffer>);

function Buffer.FillArray(a: CommandQueue<&Array>) :=
Context.Default.SyncInvoke(NewQueue.AddFillArray(a) as CommandQueue<Buffer>);
function Buffer.FillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddFillArray(a, offset, len) as CommandQueue<Buffer>);

function Buffer.FillValue<TRecord>(val: TRecord) :=
Context.Default.SyncInvoke(NewQueue.AddFillValue(val) as CommandQueue<Buffer>);
function Buffer.FillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddFillValue(val, offset, len) as CommandQueue<Buffer>);
function Buffer.FillValue<TRecord>(val: CommandQueue<TRecord>) :=
Context.Default.SyncInvoke(NewQueue.AddFillValue(val) as CommandQueue<Buffer>);
function Buffer.FillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddFillValue(val, offset, len) as CommandQueue<Buffer>);

{$endregion PatternFill}

{$region Copy}

function Buffer.CopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddCopyFrom(b, from, &to, len) as CommandQueue<Buffer>);
function Buffer.CopyFrom(b: CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(NewQueue.AddCopyFrom(b) as CommandQueue<Buffer>);

function Buffer.CopyTo(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
Context.Default.SyncInvoke(NewQueue.AddCopyTo(b, from, &to, len) as CommandQueue<Buffer>);
function Buffer.CopyTo(b: CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(NewQueue.AddCopyTo(b) as CommandQueue<Buffer>);

{$endregion Copy}

{$region Get}

function Buffer.GetData(offset, len: CommandQueue<integer>): IntPtr;
begin
  var res: IntPtr;
  
  var Qs_len := len.Multiusable(2);
  
  var Q_res := Qs_len[0].ThenConvert(len_val->
  begin
    Result := Marshal.AllocHGlobal(len_val);
    res := Result;
  end);
  
  Context.Default.SyncInvoke(
    self.NewQueue.AddReadData(Q_res, offset,Qs_len[1]) as CommandQueue<Buffer>
  );
  
  Result := res;
end;

function Buffer.GetArrayAt<TArray>(offset: CommandQueue<integer>; szs: CommandQueue<array of integer>): TArray;
begin
  var el_t := typeof(TArray).GetElementType;
  
  if szs is ConstQueue<array of integer>(var const_szs) then
  begin
    var res := System.Array.CreateInstance(
      el_t,
      const_szs.res
    );
    
    self.ReadArray(res, 0,Marshal.SizeOf(el_t)*res.Length);
    
    Result := TArray(res);
  end else
  begin
    var Qs_szs := szs.Multiusable(2);
    
    var Qs_a_base := Qs_szs[0].ThenConvert(szs_val->
    System.Array.CreateInstance(
      el_t,
      szs_val
    )).Multiusable(2);
    
    var Q_a := Qs_a_base[0];
    var Q_a_len := Qs_szs[1].ThenConvert( szs_val -> Marshal.SizeOf(el_t)*szs_val.Aggregate((i1,i2)->i1*i2) );
    var Q_res := Qs_a_base[1];
    
    Result := TArray(
      Context.Default.SyncInvoke(
        self.NewQueue
        .AddReadArray(Q_a, offset, Q_a_len) as CommandQueue<Buffer>
      *
        Q_res
      )
    );
  end;
  
end;

function Buffer.GetArrayAt<TArray>(offset: CommandQueue<integer>; params szs: array of CommandQueue<integer>) :=
szs.All(q->q is ConstQueue<integer>) ?
GetArrayAt&<TArray>(offset, CommandQueue&<array of integer>( szs.ConvertAll(q->ConstQueue&<integer>(q).res) )) :
GetArrayAt&<TArray>(offset, CombineAsyncQueue(a->a, szs));

function Buffer.GetValueAt<TRecord>(offset: CommandQueue<integer>): TRecord;
begin
  Context.Default.SyncInvoke(
    self.NewQueue
    .AddReadValue(Result, offset) as CommandQueue<Buffer>
  );
end;

{$endregion Get}

{$endregion Buffer}

{$region Kernel}

{$region constructor's}

constructor Kernel.Create(prog: ProgramCode; name: string);
begin
  var ec: ErrorCode;
  
  self._kernel := cl.CreateKernel(prog._program, name, ec);
  ec.RaiseIfError;
  
end;

{$endregion constructor's}

{$region Exec}

function Kernel.Exec(work_szs: array of UIntPtr; params args: array of CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(NewQueue.AddExec(work_szs, args) as CommandQueue<Kernel>);
function Kernel.Exec(work_szs: array of CommandQueue<UIntPtr>; params args: array of CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(NewQueue.AddExec(work_szs, args) as CommandQueue<Kernel>);
function Kernel.Exec(work_szs: CommandQueue<array of UIntPtr>; params args: array of CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(NewQueue.AddExec(work_szs, args) as CommandQueue<Kernel>);
function Kernel.Exec(work_szs: CommandQueue<array of integer>; params args: array of CommandQueue<Buffer>) :=
Context.Default.SyncInvoke(NewQueue.AddExec(work_szs, args) as CommandQueue<Kernel>);

{$endregion Exec}

{$endregion Kernel}

{$endregion Неявные CommandQueue}

end.