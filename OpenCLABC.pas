
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

//ToDo методы BufferCommand*Value всегда удаляют своё сохранённое значение
// - надо разделить на алгоритм для CommandQueue<record> и просто значения:
// - просто значение - сохранять в object, как раз боксинг с проверками сборщика мусора и нужен
// - значение очереди вообще не удалять, но и .ThenConvert не использовать. Можно же на лету это значение считать

//ToDo синхронные (с припиской Fast) варианты всего работающего по принципу HostQueue

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
  
  {$endregion hidden utils}
  
  {$region Exception's}
  
  QueueDoubleInvokeException = class(Exception)
    
    public constructor :=
    inherited Create('Нельзя выполнять одну и ту же очередь в 2 местах одновременно. Используйте .Clone или .Multiusable');
    
  end;
  
  {$endregion Exception's}
  
  {$region CommandQueue}
  
  CommandQueueBase = abstract class
    protected is_busy: boolean; //ToDo может таки сделать Invoke через контейнер и так избавится .Clone ?
    protected err: Exception; //ToDo надо все коллбеки обернуть в tryo
    
    protected mw_lock: Object; // nil, пока не будет вызвано Wait с ожиданием этой очереди
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
    
    {$endregion Queue converters}
    
    {$region def}
    
    protected procedure UnInvoke(err_lst: List<Exception>); virtual;
    begin
      
      if self.is_busy then
        is_busy := false else
        raise new InvalidOperationException('Ошибка внутри модуля OpenCLABC: совершена попыта завершить не запущенную очередь. Сообщите, пожалуйста, разработчику OpenCLABC');
      
      if self.err<>nil then
      begin
        err_lst += self.err;
        self.err := nil;
      end;
      
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; abstract;
    
    {$endregion def}
    
    {$region Invoke}
    
    protected function Invoke(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; abstract;
    
    protected function InvokeNewQ(c: Context): __EventList;
    begin
      var cq := cl_command_queue.Zero;
      Result := Invoke(c, cq, new __EventList);
    end;
    
    {$endregion Invoke}
    
    {$region Utils}
    
    {$region Misc}
    
    protected procedure MakeBusy := lock self do
    if not self.is_busy then is_busy := true else
      raise new QueueDoubleInvokeException;
    
    //ToDo #2149 - переименовать T2 в T
    protected procedure CopyLazyResTo<T2>(q: CommandQueue<T2>; var ev: __EventList); abstract;
    //ToDo #2150
    protected procedure FinishResCalc<T2>(var res: T2); abstract;
    
    protected procedure MakeWaitable :=
    if mw_lock=nil then // чтоб лишний раз "lock self" не делать
      lock self do
        if mw_lock=nil then // ещё раз если изменилось пока ждали lock
          mw_lock := new Object;
    
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
    
    {$region Clone}
    
    protected function InternalCloneCached(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase;
    begin
      if cache.TryGetValue(self, Result) then exit;
      Result := InternalClone(muhs, cache);
      cache.Add(self, Result);
    end;
    
    {$endregion Clone}
    
    {$endregion Utils}
    
  end;
  CommandQueue<T> = abstract class(CommandQueueBase)
    // когда это поле заполняется - ивент пустой,
    // а ивент под-очереди используется и отпускается в этом делегате
    // в таком случае делегат обязательно должно вызвать
    protected res_f: ()->T;
    
    protected res: T;
    
    {$region Misc}
    
    {$region GetRes}
    
    /// Используется только в наследниках __ContainerQueue
    protected procedure CopyLazyResTo<T2>(q: CommandQueue<T2>; var ev: __EventList); override;
    begin
      var tq := q as object as CommandQueue<T>;
      if tq<>nil then
      begin
        
        if self.res_f<>nil then
          tq.res_f := self.res_f else
        if ev.count=0 then
          tq.res := self.res else
        begin
          var wait_ev := ev;
          ev := new __EventList;
          
          tq.res_f := ()->
          begin
            cl.WaitForEvents(wait_ev.count,wait_ev.evs).RaiseIfError;
            wait_ev.Release;
            Result := self.res;
          end;
          
        end;
        
      end else
      begin
        
        if self.res_f<>nil then
          q.res_f := ()-> T2( self.res_f() as object ) else
        if ev.count=0 then
          q.res := T2( self.res as object ) else
        begin
          var wait_ev := ev;
          ev := new __EventList;
          
          q.res_f := ()->
          begin
            cl.WaitForEvents(wait_ev.count,wait_ev.evs).RaiseIfError;
            wait_ev.Release;
            Result := T2( self.res as object );
          end;
          
        end;
        
      end;
    end;
    
    /// Используется только в наследниках __HostQueue
    protected function FinishTResCalc :=
    res_f=nil ? res : res_f();
    
    /// Используется только в CLTask
    protected procedure FinishResCalc<T2>(var res: T2); override;
//    protected function FinishResCalc<T2>: T2; override;
    begin
      var tq := self as object as CommandQueue<T2>;
      if tq<>nil then
        res := tq.res_f=nil ? tq.res : tq.res_f() else
        res := T2(( self.res_f=nil ? self.res : self.res_f() ) as object);
    end;
    
    {$endregion GetRes}
    
    public function Clone := self.InternalClone(new Dictionary<object,object>, new Dictionary<CommandQueueBase,CommandQueueBase>) as CommandQueue<T>;
    
    {$endregion Misc}
    
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
    
    {$endregion Queue converters}
    
  end;
  
  // очередь, выполняющая незначитальный объём своей работы, но запускающая под-очереди
  // обязательно использует CopyLazyResTo, чтоб ничего не ждать
  __ContainerQueue<T> = abstract class(CommandQueue<T>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; abstract;
    
    protected function Invoke(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      MakeBusy;
      
      Result := InvokeSubQs(c, cq, prev_ev);
      
      if mw_lock<>nil then
        Result := Result.AttachCallback((ev,st,data)->
        begin
          try
            st.RaiseIfError;
            self.SignalMWEvent;
          except
            on e: Exception do if self.err<>nil then self.err := e;
          end;
          __NativUtils.GCHndFree(data);
        end, c, cq);
      
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      res := default(T);
      res_f := nil;
      inherited;
    end;
    
  end;
  
  // очередь, выполняющая какую то работу на CPU, всегда в отдельном потоке
  // обязательно использует FinishTResCalc, потому что всё равно ждёт завершения под-очередей
  __HostQueue<T> = abstract class(CommandQueue<T>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; virtual := prev_ev;
    
    protected function ExecFunc(c: Context): T; abstract;
    
    protected function Invoke(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      res := default(T);
      inherited;
    end;
    
  end;
  
  {$endregion CommandQueue}
  
  {$region Misc}
  
  DeviceTypeFlags = OpenCL.DeviceTypeFlags;
  
  CLTask<T> = sealed class
    private q: CommandQueueBase;
    private prev_evs_left: integer;
    private err_lst := new List<Exception>;
    private wh := new ManualResetEvent(false);
    private res: T;
    
    protected constructor(q: CommandQueueBase; c: Context);
    begin
      self.q := q;
      
      var cq: cl_command_queue;
      var ev := q.Invoke(c, cq, new __EventList);
      
      if ev.count=0 then
        OnQDone else
        cl.ReleaseEvent(
          ev.AttachCallback((ev,st,data)->
          begin
            
            try
              st.RaiseIfError;
              OnQDone;
            except
              on e: Exception do
              begin
                err_lst += e;
                wh.Set;
              end;
            end;
            
            __NativUtils.GCHndFree(data);
          end, c, cq)
        ).RaiseIfError;
    end;
    
    private procedure OnQDone :=
    try
      q.FinishResCalc&<T>(self.res);
      q.UnInvoke(err_lst);
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
      Result := self.res;
    end;
    
  end;
  
  {$endregion Misc}
  
  {$region GPUCommand}
  
  __GPUCommand<T> = abstract class
    protected err: Exception;
    
    {$region Command def}
    
    protected function InvokeSubQs(o_q: ()->CommandQueue<T>; o: T; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; abstract;
    
    protected procedure UnInvoke(err_lst: List<Exception>); virtual :=
    if self.err<>nil then
    begin
      err_lst += self.err;
      self.err := nil;
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<T>; abstract;
    
    {$endregion Command def}
    
  end;
  
  __GPUCommandContainer<T> = abstract class(__ContainerQueue<T>)
    protected res_q_hub: object;
    protected last_center_plug: CommandQueueBase;
    protected commands := new List<__GPUCommand<T>>;
    
    {$region def}
    
    protected procedure OnEarlyInit(c: Context); virtual := exit;
    
    {$endregion def}
    
    {$region Common}
    
    protected constructor(o: T) := self.res := o;
    protected constructor(q: CommandQueue<T>);
    
    protected function GetNewResPlug: CommandQueue<T>;
    
    protected procedure InternalAddQueue(q: CommandQueueBase);
    
    protected procedure InternalAddProc(p: T->());
    protected procedure InternalAddProc(p: (T,Context)->());
    
    protected procedure InternalAddWait(q: CommandQueueBase; allow_q_cloning: boolean);
    
    {$endregion Common}
    
    {$region sub implementation}
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      
      if res_q_hub<>nil then
      begin
        last_center_plug.UnInvoke(err_lst);
        last_center_plug := nil;
        self.res := default(T);
      end;
      
      foreach var comm in commands do
        comm.UnInvoke(err_lst);
      
      //ToDo костыль, но при убирании .Clone всё равно придётся переделать
      var b := self.res;
      inherited;
      self.res := b;
    end;
    
    {$endregion sub implementation}
    
    {$region reintroduce методы}
    
    private function Equals(obj: object): boolean; reintroduce := false;
    
    private function ToString: string; reintroduce := nil;
    
    private function GetType: System.Type; reintroduce := nil;
    
    private function GetHashCode: integer; reintroduce := 0;
    
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
    
    public function Clone: BufferCommandQueue := inherited Clone as BufferCommandQueue;
    
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
    
    public function AddWait(q: CommandQueueBase; allow_q_cloning: boolean := true): BufferCommandQueue;
    begin
      InternalAddWait(q, allow_q_cloning);
      Result := self;
    end;
    
    {$endregion Non-command add's}
    
    {$region override методы}
    
    protected procedure OnEarlyInit(c: Context); override;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override;
    
    {$endregion override методы}
    
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
    
    public procedure Dispose :=
    if self.memobj<>cl_mem.Zero then
    begin
      cl.ReleaseMemObject(memobj).RaiseIfError;
      memobj := cl_mem.Zero;
    end;
    
    protected procedure Finalize; override :=
    self.Dispose;
    
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
    
    public function Clone: KernelCommandQueue := inherited Clone as KernelCommandQueue;
    
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
    
    public function AddWait(q: CommandQueueBase; allow_q_cloning: boolean := true): KernelCommandQueue;
    begin
      InternalAddWait(q, allow_q_cloning);
      Result := self;
    end;
    
    {$endregion Non-command add's}
    
    {$region override методы}
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override;
    
    {$endregion override методы}
    
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
    
    public function BeginInvokeBase<T>(q: CommandQueueBase) := new CLTask<T>(q, self);
    
    public function BeginInvoke<T>(q: CommandQueue<T>) := BeginInvokeBase&<T>(q);
    public function BeginInvoke(q: CommandQueueBase) := BeginInvokeBase&<object>(q);
    
    public function SyncInvoke<T>(q: CommandQueue<T>): T := BeginInvoke(q).GetRes();
    public function SyncInvoke(q: CommandQueueBase): object := BeginInvoke(q).GetRes();
    
    protected procedure Finalize; override :=
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
  
  {$region ConstQueue}
  
  ConstQueue<T> = sealed class(CommandQueue<T>, IConstQueue)
    
    public constructor(o: T) :=
    self.res := o;
    
    public function GetConstVal: object := self.res;
    public property Val: T read self.res;
    
    protected function Invoke(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      if mw_lock<>nil then
        if prev_ev.count=0 then
          SignalMWEvent else
          prev_ev := prev_ev.AttachCallback((ev,st,data)->
          begin
            
            try
              st.RaiseIfError;
              SignalMWEvent;
            except
              on e: Exception do if self.err=nil then self.err := e;
            end;
            
            __NativUtils.GCHndFree(data);
          end, c, cq);
      Result := prev_ev;
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override := exit;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override := self;
    
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

//ToDo

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
  
  cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, __NativUtils.GCHndAlloc(cb));
  Result := ev;
end;

{$endregion Misc}

{$region CommandQueue}

{$region Misc implementation}

function __HostQueue<T>.Invoke(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList;
begin
  MakeBusy;
  
  var ec: ErrorCode;
  var uev := cl.CreateUserEvent(c._context, ec);
  ec.RaiseIfError;
  
  prev_ev := InvokeSubQs(c, cq, prev_ev);
  
  Thread.Create(()->
  try
    if prev_ev.count<>0 then cl.WaitForEvents(prev_ev.count, prev_ev.evs).RaiseIfError;
    prev_ev.Release;
    self.res := ExecFunc(c);
    cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
    self.SignalMWEvent;
  except
    on e: Exception do
    begin
      if self.err=nil then self.err := e;
      cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
    end;
  end).Start;
  
  Result := uev;
end;

{$endregion Misc implementation}

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
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      Result := q.Invoke(c, cq, prev_ev);
      q.CopyLazyResTo(self, Result);
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      q.UnInvoke(err_lst);
      inherited;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CastQueue<T>(
      q.InternalCloneCached(muhs, cache)
    );
    
  end;
  
function CommandQueueBase.Cast<T>: CommandQueue<T>;
begin
  Result := self as CommandQueue<T>;
  if Result=nil then Result := new CastQueue<T>(self);
end;

{$endregion Cast}

{$region HostFunc}

type
  CommandQueueHostFunc<T> = sealed class(__HostQueue<T>)
    private f: ()->T;
    
    public constructor(f: ()->T) :=
    self.f := f;
    
    protected function ExecFunc(c: Context): T; override := f();
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueHostFunc<T>(self.f);
    
  end;
  CommandQueueHostFuncC<T> = sealed class(__HostQueue<T>)
    private f: Context->T;
    
    public constructor(f: Context->T) :=
    self.f := f;
    
    protected function ExecFunc(c: Context): T; override := f(c);
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueHostFuncC<T>(self.f);
    
  end;
  
  CommandQueueHostProc = sealed class(__HostQueue<object>)
    private p: ()->();
    
    public constructor(p: ()->()) :=
    self.p := p;
    
    protected function ExecFunc(c: Context): object; override;
    begin
      p();
      Result := nil;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueHostProc(self.p);
    
  end;
  CommandQueueHostProcС = sealed class(__HostQueue<object>)
    private p: Context->();
    
    public constructor(p: Context->()) :=
    self.p := p;
    
    protected function ExecFunc(c: Context): object; override;
    begin
      p(c);
      Result := nil;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueHostProcС(self.p);
    
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
  CommandQueueThenConvertBase<TInp,TRes> = abstract class(__HostQueue<TRes>)
    q: CommandQueue<TInp>;
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    q.Invoke(c, cq, prev_ev);
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      q.UnInvoke(err_lst);
      inherited;
    end;
    
  end;
  
  CommandQueueThenConvert<TInp,TRes> = sealed class(CommandQueueThenConvertBase<TInp,TRes>)
    private f: TInp->TRes;
    
    constructor(q: CommandQueue<TInp>; f: TInp->TRes);
    begin
      self.q := q;
      self.f := f;
    end;
    
    protected function ExecFunc(c: Context): TRes; override := f( q.FinishTResCalc );
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueThenConvert<TInp,TRes>(self.q.InternalCloneCached(muhs, cache), self.f);
    
  end;
  CommandQueueThenConvertC<TInp,TRes> = sealed class(CommandQueueThenConvertBase<TInp,TRes>)
    private f: (TInp,Context)->TRes;
    
    constructor(q: CommandQueue<TInp>; f: (TInp,Context)->TRes);
    begin
      self.q := q;
      self.f := f;
    end;
    
    protected function ExecFunc(c: Context): TRes; override := f( q.FinishTResCalc, c);
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueThenConvertC<TInp,TRes>(self.q.InternalCloneCached(muhs, cache), self.f);
    
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
  MultiusableCommandQueueNode<T>=class;
  
  // invoke_status:
  // 0 - выполнение не начато
  // 1 - выполнение начинается
  // 3 - выполнение прекращается
  
  MultiusableCommandQueueHub<T> = sealed class
    public q: CommandQueueBase;
    public ev: __EventList;
    
    public invoke_status := 0;
    public invoked_count := 0;
    
    public constructor(q: CommandQueueBase) :=
    self.q := q;
    
    public function OnNodeInvoked(c: Context): __EventList;
    public procedure OnNodeUnInvoked(err_lst: List<Exception>);
    
    public function MakeNode: CommandQueue<T>;
    
  end;
  
  MultiusableCommandQueueNode<T> = sealed class(__ContainerQueue<T>)
    public hub: MultiusableCommandQueueHub<T>;
    
    public constructor(hub: MultiusableCommandQueueHub<T>) := self.hub := hub;
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      Result := hub.OnNodeInvoked(c);
      hub.q.CopyLazyResTo(self, Result);
      Result := prev_ev+Result;
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      hub.OnNodeUnInvoked(err_lst);
      inherited;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override;
    begin
      var res_hub: MultiusableCommandQueueHub<T>;
      
      var res_hub_o: object;
      if muhs.TryGetValue(self.hub, res_hub_o) then
        res_hub := MultiusableCommandQueueHub&<T>(res_hub_o) else
      begin
        res_hub := new MultiusableCommandQueueHub<T>(self.hub.q.InternalCloneCached(muhs, cache));
        muhs.Add(self.hub, res_hub);
      end;
      
      Result := new MultiusableCommandQueueNode<T>(res_hub);
    end;
    
  end;
  
function MultiusableCommandQueueHub<T>.OnNodeInvoked(c: Context):__EventList;
begin
  case invoke_status of
    0: invoke_status := 1;
    2: raise new QueueDoubleInvokeException;
  end;
  
  if invoked_count=0 then
  begin
    Result := q.InvokeNewQ(c);
    ev := Result;
  end else
    Result := ev;
  
  Result.Retain;
  invoked_count += 1;
  
end;

procedure MultiusableCommandQueueHub<T>.OnNodeUnInvoked(err_lst: List<Exception>);
begin
  case invoke_status of
    0: raise new InvalidOperationException('Ошибка внутри модуля OpenCLABC: совершена попыта завершить не запущенную очередь. Сообщите, пожалуйста, разработчику OpenCLABC');
    1: invoke_status := 2;
  end;
  
  invoked_count -= 1;
  
  if invoked_count=0 then
  begin
    q.UnInvoke(err_lst);
    ev.Release;
    ev := nil;
    invoke_status := 0;
  end;
  
end;

function MultiusableCommandQueueHub<T>.MakeNode :=
new MultiusableCommandQueueNode<T>(self);

function CommandQueue<T>.Multiusable(n: integer): array of CommandQueue<T>;
begin
  if self is ConstQueue<T> then
    Result := ArrFill(n, self) else
  if self is MultiusableCommandQueueNode<T>(var mcqn) then
  begin
    Result := new CommandQueue&<T>[n];
    if n=0 then exit;
    var hub := mcqn.hub;
    Result[0] := self;
    for var i := 1 to n-1 do
      Result[i] := hub.MakeNode;
  end else
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
    var hub := self is MultiusableCommandQueueNode<T>(var mcqn) ?
      mcqn.hub : new MultiusableCommandQueueHub<T>(self);
    Result := hub.MakeNode;
  end;
end;

{$endregion Multiusable}

{$region Sync/Async Base}

type
  IQueueArray = interface
    function GetQS: array of CommandQueueBase;
  end;
  
  SimpleQueueArray<T> = abstract class(__ContainerQueue<T>, IQueueArray)
    private qs: array of CommandQueueBase;
    
    public function GetQS: array of CommandQueueBase := qs;
    
    public constructor(qs: array of CommandQueueBase) := self.qs := qs;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      foreach var q in qs do
        q.UnInvoke(err_lst);
      inherited;
    end;
    
  end;
  
  HostQueueArrayBase<TInp,TRes> = abstract class(__HostQueue<TRes>, IQueueArray)
    private qs: array of CommandQueueBase;
    
    public function GetQS: array of CommandQueueBase := qs;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      foreach var q in qs do
        q.UnInvoke(err_lst);
      inherited;
    end;
    
  end;
  HostQueueArray<TInp,TRes> = abstract class(HostQueueArrayBase<TInp,TRes>)
    private conv: Func<array of TInp, TRes>;
    
    protected constructor(qs: array of CommandQueueBase; conv: Func<array of TInp, TRes>);
    begin
      self.qs := qs;
      self.conv := conv;
    end;
    
    protected function ExecFunc(c: Context): TRes; override;
    begin
      var a := new TInp[qs.Length];
      for var i := 0 to a.Length-1 do
        qs[i].FinishResCalc(a[i]);
      Result := conv(a);
    end;
    
  end;
  HostQueueArrayC<TInp,TRes> = abstract class(HostQueueArrayBase<TInp,TRes>)
    private conv: Func<array of TInp, Context, TRes>;
    
    protected constructor(qs: array of CommandQueueBase; conv: Func<array of TInp, Context, TRes>);
    begin
      self.qs := qs;
      self.conv := conv;
    end;
    
    protected function ExecFunc(c: Context): TRes; override;
    begin
      var a := new TInp[qs.Length];
      for var i := 0 to a.Length-1 do
        qs[i].FinishResCalc(a[i]);
      Result := conv(a, c);
    end;
    
  end;
  
function FlattenQueueArray<T>(inp: sequence of CommandQueueBase): array of CommandQueueBase; where T: IQueueArray;
begin
  var enmr := inp.GetEnumerator;
  if not enmr.MoveNext then raise new InvalidOperationException('inp Empty');
  
  var res := new List<CommandQueueBase>;
  while true do
  begin
    var curr := enmr.Current;
    var next := enmr.MoveNext;
    
    if not (curr is IConstQueue) then
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
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      
      foreach var q in qs do
        prev_ev := q.Invoke(c, cq, prev_ev);
      
      qs[qs.Length-1].CopyLazyResTo(self,prev_ev);
      Result := prev_ev;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueSyncArray<T>(
      self.qs.ConvertAll(q->q.InternalCloneCached(muhs, cache))
    );
    
  end;
  
  CommandQueueSyncConvArray<TInp,TRes> = sealed class(HostQueueArray<TInp,TRes>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      
      foreach var q in qs do
        prev_ev := q.Invoke(c, cq, prev_ev);
      
      Result := prev_ev;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueSyncConvArray<TInp,TRes>(
      self.qs.ConvertAll(q->q.InternalCloneCached(muhs, cache)),
      self.conv
    );
    
  end;
  CommandQueueSyncConvArrayC<TInp,TRes> = sealed class(HostQueueArrayC<TInp,TRes>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      
      foreach var q in qs do
        prev_ev := q.Invoke(c, cq, prev_ev);
      
      Result := prev_ev;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueSyncConvArrayC<TInp,TRes>(
      self.qs.ConvertAll(q->q.InternalCloneCached(muhs, cache)),
      self.conv
    );
    
  end;
  
static function CommandQueueBase.operator+(q1, q2: CommandQueueBase): CommandQueueBase :=
CombineSyncQueueBase(q1,q2);

static function CommandQueueBase.operator+<T>(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T> :=
CombineSyncQueue&<T>(q1,q2);

{$region NonConv}

function __CombineSyncQueue<T>(qss: sequence of CommandQueueBase): CommandQueue<T>;
begin
  var qs := FlattenQueueArray&<CommandQueueSyncArray<T>>(qss);
  if qs.Length=1 then
    Result := qs[0].Cast&<T> else
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
new CommandQueueSyncConvArray<object,TRes>(qs.ToArray, conv);

function CombineSyncQueue<TRes>(conv: Func<array of object, TRes>; params qs: array of CommandQueueBase) :=
new CommandQueueSyncConvArray<object,TRes>(qs.ToArray, conv);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; qs: sequence of CommandQueue<TInp>) :=
new CommandQueueSyncConvArray<TInp,TRes>(qs.Cast&<CommandQueueBase>.ToArray, conv);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; params qs: array of CommandQueue<TInp>) :=
new CommandQueueSyncConvArray<TInp,TRes>(qs.ConvertAll(q->q as CommandQueueBase), conv);

{$endregion NoContext}

{$region Context}

function CombineSyncQueue<TRes>(conv: Func<array of object, Context, TRes>; qs: sequence of CommandQueueBase) :=
new CommandQueueSyncConvArrayC<object,TRes>(qs.ToArray, conv);

function CombineSyncQueue<TRes>(conv: Func<array of object, Context, TRes>; params qs: array of CommandQueueBase) :=
new CommandQueueSyncConvArrayC<object,TRes>(qs.ToArray, conv);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; qs: sequence of CommandQueue<TInp>) :=
new CommandQueueSyncConvArrayC<TInp,TRes>(qs.Cast&<CommandQueueBase>.ToArray, conv);

function CombineSyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; params qs: array of CommandQueue<TInp>) :=
new CommandQueueSyncConvArrayC<TInp,TRes>(qs.ConvertAll(q->q as CommandQueueBase), conv);

{$endregion Context}

{$endregion Conv}

{$endregion SyncArray}

{$region AsyncArray}

type
  CommandQueueAsyncArray<T> = sealed class(SimpleQueueArray<T>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      loop qs.Length-1 do prev_ev.Retain;
      
      var evs := new __EventList[qs.Length];
      var count := 0;
      for var i := 0 to qs.Length-1 do
      begin
        var ncq := cl_command_queue.Zero;
        var ev := qs[i].Invoke(c, ncq, prev_ev);
        evs[i] := ev;
        count += ev.count;
      end;
      
      Result := new __EventList(count);
      foreach var ev in evs do Result += ev;
      qs[qs.Length-1].CopyLazyResTo(self,Result);
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueAsyncArray<T>(
      self.qs.ConvertAll(q->q.InternalCloneCached(muhs, cache))
    );
    
  end;
  
  CommandQueueAsyncConvArray<TInp,TRes> = sealed class(HostQueueArray<TInp,TRes>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      loop qs.Length-1 do prev_ev.Retain;
      
      var evs := new __EventList[qs.Length];
      var count := 0;
      for var i := 0 to qs.Length-1 do
      begin
        var ncq := cl_command_queue.Zero;
        var ev := qs[i].Invoke(c, ncq, prev_ev);
        evs[i] := ev;
        count += ev.count;
      end;
      
      Result := new __EventList(count);
      foreach var ev in evs do Result += ev;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueAsyncConvArray<TInp,TRes>(
      self.qs.ConvertAll(q->q.InternalCloneCached(muhs, cache)),
      self.conv
    );
    
  end;
  CommandQueueAsyncConvArrayC<TInp,TRes> = sealed class(HostQueueArrayC<TInp,TRes>)
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      loop qs.Length-1 do prev_ev.Retain;
      
      var evs := new __EventList[qs.Length];
      var count := 0;
      for var i := 0 to qs.Length-1 do
      begin
        var ncq := cl_command_queue.Zero;
        var ev := qs[i].Invoke(c, ncq, prev_ev);
        evs[i] := ev;
        count += ev.count;
      end;
      
      Result := new __EventList(count);
      foreach var ev in evs do Result += ev;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueAsyncConvArrayC<TInp,TRes>(
      self.qs.ConvertAll(q->q.InternalCloneCached(muhs, cache)),
      self.conv
    );
    
  end;
  
static function CommandQueueBase.operator*(q1, q2: CommandQueueBase): CommandQueueBase :=
CombineAsyncQueueBase(q1,q2);

static function CommandQueueBase.operator*<T>(q1: CommandQueueBase; q2: CommandQueue<T>): CommandQueue<T> :=
CombineAsyncQueue&<T>(q1,q2);

{$region NonConv}

function __CombineAsyncQueue<T>(qss: sequence of CommandQueueBase): CommandQueue<T>;
begin
  var qs := FlattenQueueArray&<CommandQueueAsyncArray<T>>(qss);
  if qs.Length=1 then
    Result := qs[0].Cast&<T> else
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
new CommandQueueAsyncConvArray<object,TRes>(qs.ToArray, conv);

function CombineAsyncQueue<TRes>(conv: Func<array of object, TRes>; params qs: array of CommandQueueBase) :=
new CommandQueueAsyncConvArray<object,TRes>(qs.ToArray, conv);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; qs: sequence of CommandQueue<TInp>) :=
new CommandQueueAsyncConvArray<TInp,TRes>(qs.Cast&<CommandQueueBase>.ToArray, conv);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, TRes>; params qs: array of CommandQueue<TInp>) :=
new CommandQueueAsyncConvArray<TInp,TRes>(qs.ConvertAll(q->q as CommandQueueBase), conv);

{$endregion NoContext}

{$region Context}

function CombineAsyncQueue<TRes>(conv: Func<array of object, Context, TRes>; qs: sequence of CommandQueueBase) :=
new CommandQueueAsyncConvArrayC<object,TRes>(qs.ToArray, conv);

function CombineAsyncQueue<TRes>(conv: Func<array of object, Context, TRes>; params qs: array of CommandQueueBase) :=
new CommandQueueAsyncConvArrayC<object,TRes>(qs.ToArray, conv);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; qs: sequence of CommandQueue<TInp>) :=
new CommandQueueAsyncConvArrayC<TInp,TRes>(qs.Cast&<CommandQueueBase>.ToArray, conv);

function CombineAsyncQueue<TInp,TRes>(conv: Func<array of TInp, Context, TRes>; params qs: array of CommandQueue<TInp>) :=
new CommandQueueAsyncConvArrayC<TInp,TRes>(qs.ConvertAll(q->q as CommandQueueBase), conv);

{$endregion Context}

{$endregion Conv}

{$endregion AsyncArray}

{$region Wait}

type
  CommandQueueThenWaitFor<T> = sealed class(__ContainerQueue<T>)
    public wait_source, q: CommandQueueBase;
    public allow_source_cloning: boolean;
    
    public constructor(wait_source, q: CommandQueueBase; allow_source_cloning: boolean);
    begin
      wait_source.MakeWaitable;
      self.wait_source := wait_source;
      self.q := q;
      self.allow_source_cloning := allow_source_cloning;
    end;
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      prev_ev := q.Invoke(c, cq, prev_ev);
      q.CopyLazyResTo(self, prev_ev);
      Result := wait_source.GetMWEvent(c._context) + prev_ev;
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      q.UnInvoke(err_lst);
      inherited;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueThenWaitFor<T>(
      self.q.InternalCloneCached(muhs, cache),
      allow_source_cloning?
        self.wait_source.InternalCloneCached(muhs, cache) :
        self.wait_source,
      self.allow_source_cloning
    );
    
  end;
  
  CommandQueueWaitForMany<T> = sealed class(__ContainerQueue<T>)
    public wait_sources: array of (CommandQueueBase, boolean);
    public q: CommandQueueBase;
    
    public constructor(wait_sources: array of (CommandQueueBase, boolean); q: CommandQueueBase);
    begin
      foreach var t in wait_sources do t[0].MakeWaitable;
      self.wait_sources := wait_sources;
      self.q := q;
    end;
    
    protected function InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      prev_ev := q.Invoke(c, cq, prev_ev);
      q.CopyLazyResTo(self, prev_ev);
      Result := new __EventList(wait_sources.Length + prev_ev.count);
      for var i := 0 to wait_sources.Length-1 do
        Result += wait_sources[i][0].GetMWEvent(c._context);
      Result += prev_ev;
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      q.UnInvoke(err_lst);
      inherited;
    end;
    
    protected function InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase; override :=
    new CommandQueueWaitForMany<T>(
      wait_sources.Any(p->p[1]) ?
        wait_sources.ConvertAll(p->(
          p[0].InternalCloneCached(muhs, cache),
          p[1]
        )) :
        wait_sources,
      self.q.InternalCloneCached(muhs, cache)
    );
    
  end;
  
{$endregion Wait}

{$region GPUCommand}

{$region GPUCommandContainer}

constructor __GPUCommandContainer<T>.Create(q: CommandQueue<T>) :=
self.res_q_hub := new MultiusableCommandQueueHub<T>(q);

function __GPUCommandContainer<T>.GetNewResPlug: CommandQueue<T> :=
new MultiusableCommandQueueNode<T>( MultiusableCommandQueueHub&<T>(res_q_hub) );

function __GPUCommandContainer<T>.InvokeSubQs(c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList;
begin
  
  var new_plug: ()->CommandQueue<T>;
  if res_q_hub=nil then
    OnEarlyInit(c) else
  begin
    var plug := GetNewResPlug();
    prev_ev := plug.Invoke(c, cq, prev_ev);
    last_center_plug := plug;
    new_plug := GetNewResPlug;
  end;
  
  foreach var comm in commands do
    prev_ev := comm.InvokeSubQs(new_plug, res, c, cq, prev_ev);
  
  if last_center_plug<>nil then
    last_center_plug.CopyLazyResTo(self, prev_ev);
  
  Result := prev_ev;
end;

{$endregion GPUCommandContainer}

{$region QueueCommand}

type
  QueueCommand<T> = sealed class(__GPUCommand<T>)
    public q: CommandQueueBase;
    
    public constructor(q: CommandQueueBase) :=
    self.q := q;
    
    protected function InvokeSubQs(o_q: ()->CommandQueue<T>; o: T; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    q.Invoke(c, cq, prev_ev);
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      q.UnInvoke(err_lst);
      inherited;
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<T>; override :=
    new QueueCommand<T>(self.q.InternalCloneCached(muhs, cache) as CommandQueue<T>);
    
  end;
  
procedure __GPUCommandContainer<T>.InternalAddQueue(q: CommandQueueBase) :=
commands.Add( new QueueCommand<T>(q) );

{$endregion QueueCommand}

{$region ProcCommand}

type
  ProcCommandBase<T> = abstract class(__GPUCommand<T>)
    private last_o_q: CommandQueue<T>;
    
    protected procedure ExecProc(c: Context; o: T); abstract;
    
    protected function InvokeSubQs(o_q: ()->CommandQueue<T>; o: T; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      
      var ec: ErrorCode;
      var uev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      if o_q<>nil then
      begin
        var plug := o_q();
        last_o_q := plug;
        prev_ev := plug.Invoke(c, cq, prev_ev);
      end;
      
      Thread.Create(()->
      try
        if prev_ev.count<>0 then cl.WaitForEvents(prev_ev.count, prev_ev.evs).RaiseIfError;
        prev_ev.Release;
        var lo := last_o_q=nil ? o : last_o_q.FinishTResCalc;
        self.ExecProc(c, lo);
        cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      except
        on e: Exception do
        begin
          if self.err=nil then self.err := e;
          cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        end;
      end).Start;
      
      Result := uev;
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      
      if last_o_q<>nil then
      begin
        last_o_q.UnInvoke(err_lst);
        last_o_q := nil;
      end;
      
      inherited;
    end;
    
  end;
  
  ProcCommand<T> = sealed class(ProcCommandBase<T>)
    public p: T->();
    
    public constructor(p: T->()) := self.p := p;
    
    protected procedure ExecProc(c: Context; o: T); override := p(o);
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<T>; override :=
    new ProcCommand<T>(self.p);
    
  end;
  ProcCommandC<T> = sealed class(ProcCommandBase<T>)
    public p: (T,Context)->();
    
    public constructor(p: (T,Context)->()) := self.p := p;
    
    protected procedure ExecProc(c: Context; o: T); override := p(o, c);
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<T>; override :=
    new ProcCommandC<T>(self.p);
    
  end;
  
procedure __GPUCommandContainer<T>.InternalAddProc(p: T->()) :=
commands.Add( new ProcCommand<T>(p) );

procedure __GPUCommandContainer<T>.InternalAddProc(p: (T,Context)->()) :=
commands.Add( new ProcCommandC<T>(p) );

{$endregion ProcCommand}

{$region WaitCommand}

type
  WaitCommand<T> = sealed class(__GPUCommand<T>)
    public wait_source: CommandQueueBase;
    public allow_source_cloning: boolean;
    
    public constructor(wait_source: CommandQueueBase; allow_source_cloning: boolean);
    begin
      wait_source.MakeWaitable;
      self.wait_source := wait_source;
      self.allow_source_cloning := allow_source_cloning;
    end;
    
    protected function InvokeSubQs(o_q: ()->CommandQueue<T>; o: T; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override :=
    prev_ev + wait_source.GetMWEvent(c._context);
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<T>; override :=
    new WaitCommand<T>(
      allow_source_cloning?
        wait_source.InternalCloneCached(muhs, cache) :
        wait_source,
      allow_source_cloning
    );
    
  end;
  
procedure __GPUCommandContainer<T>.InternalAddWait(q: CommandQueueBase; allow_q_cloning: boolean) :=
commands.Add( new WaitCommand<T>(q, allow_q_cloning) );

{$endregion WaitCommand}

{$region EnqueueableGPUCommand}

type
  
  EnqueueableGPUCommand<T> = abstract class(__GPUCommand<T>)
    public sqs: array of CommandQueueBase;
    public last_o_q: CommandQueue<T>;
    
    constructor(params sqs: array of CommandQueueBase) := self.sqs := sqs;
    
    protected procedure CommonInvoke(c: Context; var cq: cl_command_queue; var prev_ev: __EventList);
    begin
      
      begin
        var evs := new __EventList[sqs.Length];
        var count := 0;
        
        for var i := 0 to evs.Length-1 do
        begin
          var ev := sqs[i].Invoke(c, cq, new __EventList);
          count += ev.count;
          evs[i] := ev;
        end;
        
        if count<>0 then
        begin
          var n_prev_ev := new __EventList(count+prev_ev.count);
          for var i := 0 to evs.Length-1 do n_prev_ev += evs[i];
          n_prev_ev += prev_ev;
          prev_ev := n_prev_ev;
        end;
      end;
      
      if cq=cl_command_queue.Zero then
      begin
        var ec: ErrorCode;
        cq := cl.CreateCommandQueue(c._context, c._device, CommandQueuePropertyFlags.NONE, ec);
        ec.RaiseIfError;
      end;
      
    end;
    
    protected procedure UnInvoke(err_lst: List<Exception>); override;
    begin
      
      if last_o_q<>nil then
      begin
        last_o_q.UnInvoke(err_lst);
        last_o_q := nil;
      end;
      
      foreach var sq in sqs do
        sq.UnInvoke(err_lst);
      
      inherited;
    end;
    
  end;
  
  SyncGPUCommand<T> = abstract class(EnqueueableGPUCommand<T>)
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; o: T; prev_ev: __EventList; var res_ev: cl_event); abstract;
    
    protected function InvokeSubQs(o_q: ()->CommandQueue<T>; o: T; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      CommonInvoke(c, cq, prev_ev);
      
      var plug_ev: __EventList;
      if o_q<>nil then
      begin
        var plug := o_q();
        last_o_q := plug;
        plug_ev := plug.Invoke(c, cq, new __EventList);
        if plug_ev.count=0 then
        begin
          plug_ev := nil;
          o := plug.FinishTResCalc;
        end;
      end;
      
      if plug_ev=nil then
      begin
        var res_ev: cl_event;
        EnqueueSelf(c, cq, o, prev_ev, res_ev);
        Result := res_ev;
        prev_ev.Release;
      end else
      begin
        var lcq := cq;
        cq := cl_command_queue.Zero; // асинхронное EnqueueSelf, далее придётся создать новую очередь
        
        var ec: ErrorCode;
        var uev := cl.CreateUserEvent(c._context, ec);
        ec.RaiseIfError;
        
        cl.ReleaseEvent(
          plug_ev.AttachCallback((ev,st,data)->
          begin
            
            try
              st.RaiseIfError;
              var lo := last_o_q=nil ? o : last_o_q.FinishTResCalc;
              var res_ev: cl_event;
              EnqueueSelf(c, lcq, lo, prev_ev, res_ev);
              prev_ev.Release;
              
              cl.ReleaseEvent(
                __EventList.Create(res_ev).AttachCallback((ev2,st2,data2)->
                begin
                  
                  if st2.IS_ERROR and (self.err=nil) then
                    self.err := new OpenCLException(st2.val);
                  
                  cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
                  __NativUtils.GCHndFree(data2);
                end, c, lcq)
              ).RaiseIfError;
              
            except
              on e: Exception do
              begin
                if self.err=nil then self.err := e;
                cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
              end;
            end;
            
            __NativUtils.GCHndFree(data);
          end, c, lcq)
        ).RaiseIfError;
        
      end;
      
    end;
    
  end;
  
  AsyncGPUCommand<T> = abstract class(EnqueueableGPUCommand<T>)
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; o: T); abstract;
    
    protected function InvokeSubQs(o_q: ()->CommandQueue<T>; o: T; c: Context; var cq: cl_command_queue; prev_ev: __EventList): __EventList; override;
    begin
      CommonInvoke(c, cq, prev_ev);
      
      if o_q<>nil then
      begin
        var plug := o_q();
        last_o_q := plug;
        prev_ev := plug.Invoke(c, cq, prev_ev);
      end;
      
      var ec: ErrorCode;
      var uev := cl.CreateUserEvent(c._context, ec);
      ec.RaiseIfError;
      
      var lcq := cq;
      cq := cl_command_queue.Zero; // асинхронное EnqueueSelf, далее придётся создать новую очередь
      
      Thread.Create(()->
      try
        if prev_ev.count<>0 then
        begin
          cl.WaitForEvents(prev_ev.count,prev_ev.evs).RaiseIfError;
          prev_ev.Release;
        end;
        var lo := last_o_q=nil ? o : last_o_q.FinishTResCalc;
        EnqueueSelf(c, lcq, lo);
        cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
      except
        on e: Exception do
        begin
          if self.err=nil then self.err := e;
          cl.SetUserEventStatus(uev, CommandExecutionStatus.COMPLETE).RaiseIfError;
        end;
      end).Start;
      
      Result := uev;
    end;
    
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

function BufferCommandQueue.GetSizeQ: CommandQueue<integer> :=
self.res_q_hub=nil ? integer(res.sz.ToUInt32) :
self.GetNewResPlug().ThenConvert(b->integer(b.sz.ToUInt32));

procedure BufferCommandQueue.OnEarlyInit(c: Context) :=
if res.memobj=cl_mem.Zero then res.Init(c);

function BufferCommandQueue.InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase;
begin
  var res := new BufferCommandQueue(self.res);
  
  if self.res_q_hub<>nil then
  begin
    var hub := MultiusableCommandQueueHub&<Buffer>(self.res_q_hub);
    
    res.res_q_hub := new MultiusableCommandQueueHub<Buffer>(CommandQueue&<Buffer>(
      hub.q.InternalCloneCached(muhs, cache)
    ));
    
    muhs.Add(self.res_q_hub, res.res_q_hub);
  end;
  
  res.commands.Capacity := self.commands.Capacity;
  foreach var comm in self.commands do res.commands += comm.Clone(muhs, cache);
  
  Result := res;
end;

{$endregion BufferCommandQueue}

{$region Write}

type
  BufferCommandWriteData = sealed class(SyncGPUCommand<Buffer>)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(ptr, offset, len);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override :=
    cl.EnqueueWriteBuffer(
      cq, b.memobj, 0,
      new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
      ptr.FinishTResCalc,
      prev_ev.count,prev_ev.evs,res_ev
    ).RaiseIfError;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandWriteData(
      CommandQueue&<IntPtr> (self.ptr   .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset.InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len   .InternalCloneCached(muhs, cache))
    );
    
  end;
  BufferCommandWriteArray = sealed class(AsyncGPUCommand<Buffer>)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(a, offset, len);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer); override :=
    cl.EnqueueWriteBuffer(
      cq, b.memobj, 1,
      new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
      Marshal.UnsafeAddrOfPinnedArrayElement(a.FinishTResCalc,0),
      0,nil,nil
    ).RaiseIfError;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandWriteArray(
      CommandQueue&<&Array> (self.a     .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset.InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len   .InternalCloneCached(muhs, cache))
    );
    
  end;
  BufferCommandWriteValue = sealed class(SyncGPUCommand<Buffer>)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(ptr, offset, len);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override;
    begin
      var res_ptr := ptr.FinishTResCalc;
      
      cl.EnqueueWriteBuffer(
        cq, b.memobj, 0,
        new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
        res_ptr,
        prev_ev.count,prev_ev.evs,res_ev
      ).RaiseIfError;
      
      var cb: Event_Callback := (ev,st,data)->
      begin
        if st.IS_ERROR and (self.err=nil) then self.err := new OpenCLException(st.val);
        Marshal.FreeHGlobal(res_ptr);
        __NativUtils.GCHndFree(data);
      end;
      
      cl.SetEventCallback(res_ev, CommandExecutionStatus.COMPLETE, cb, __NativUtils.GCHndAlloc(cb)).RaiseIfError;
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandWriteValue(
      CommandQueue&<IntPtr> (self.ptr   .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset.InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len   .InternalCloneCached(muhs, cache))
    );
    
  end;
  
  
function BufferCommandQueue.AddWriteData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteData(ptr, offset, len));

function BufferCommandQueue.AddWriteArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteArray(a, offset, len));


function BufferCommandQueue.AddWriteValue<TRecord>(val: TRecord; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValue(new IntPtr(__NativUtils.CopyToUnm(val)), offset,Marshal.SizeOf&<TRecord>));

function BufferCommandQueue.AddWriteValue<TRecord>(val: CommandQueue<TRecord>; offset: CommandQueue<integer>) :=
AddCommand(new BufferCommandWriteValue(
  val.ThenConvert&<IntPtr>(vval-> //ToDo #2067
  begin
    var костыль_ptr: ^TRecord := pointer(@vval); //ToDo #2068
    Result := new IntPtr(__NativUtils.CopyToUnm(костыль_ptr^)); // вместо костыля - vval
  end),
  offset,
  Marshal.SizeOf&<TRecord>
));

{$endregion Write}

{$region Read}

type
  BufferCommandReadData = sealed class(SyncGPUCommand<Buffer>)
    public ptr: CommandQueue<IntPtr>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(ptr, offset, len);
      self.ptr := ptr;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override :=
    cl.EnqueueReadBuffer(
      cq, b.memobj, 0,
      new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
      ptr.FinishTResCalc,
      prev_ev.count,prev_ev.evs,res_ev
    ).RaiseIfError;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandReadData(
      CommandQueue&<IntPtr> (self.ptr   .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset.InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len   .InternalCloneCached(muhs, cache))
    );
    
  end;
  BufferCommandReadArray = sealed class(AsyncGPUCommand<Buffer>)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(a, offset, len);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer); override :=
    cl.EnqueueReadBuffer(
      cq, b.memobj, 1,
      new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
      Marshal.UnsafeAddrOfPinnedArrayElement(a.FinishTResCalc,0),
      0,nil,nil
    ).RaiseIfError;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandReadArray(
      CommandQueue&<&Array> (self.a     .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset.InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len   .InternalCloneCached(muhs, cache))
    );
    
  end;
  
function BufferCommandQueue.AddReadData(ptr: CommandQueue<IntPtr>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadData(ptr, offset, len));

function BufferCommandQueue.AddReadArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandReadArray(a, offset, len));

{$endregion Read}

{$region Fill}

type
  BufferCommandDataFill = sealed class(SyncGPUCommand<Buffer>)
    public ptr: CommandQueue<IntPtr>;
    public pattern_len, offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>);
    begin
      inherited Create(ptr, pattern_len, offset, len);
      self.ptr := ptr;
      self.pattern_len := pattern_len;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override :=
    cl.EnqueueFillBuffer(
      cq, b.memobj,
      ptr.FinishTResCalc, new UIntPtr(pattern_len.FinishTResCalc),
      new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
      prev_ev.count, prev_ev.evs, res_ev
    ).RaiseIfError;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandDataFill(
      CommandQueue&<IntPtr> (self.ptr         .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.pattern_len .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset      .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len         .InternalCloneCached(muhs, cache))
    );
    
  end;
  BufferCommandArrayFill = sealed class(SyncGPUCommand<Buffer>)
    public a: CommandQueue<&Array>;
    public offset, len: CommandQueue<integer>;
    
    public constructor(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>);
    begin
      inherited Create(a, offset, len);
      self.a := a;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override;
    begin
      // Синхронного Fill нету, поэтому между cl.Enqueue и cl.WaitForEvents сборщик мусора может сломать указатель
      // Остаётся только закреплять, хоть так и не любой тип массива пропустит
      var la := a.FinishTResCalc;
      var a_hnd := GCHandle.Alloc(la, GCHandleType.Pinned);
      var cb_hnd: GCHandle;
      
      var cb: Event_Callback := (ev,st,data)->
      begin
        if st.IS_ERROR and (self.err=nil) then self.err := new OpenCLException(st.val); //ToDo вообще говнокод, .val не должно быть. Добавить метод CES создаюший но не вызывающий исключение
        a_hnd.Free;
        cb_hnd.Free;
      end;
      cb_hnd := GCHandle.Alloc(cb);
      
      cl.EnqueueFillBuffer(cq, b.memobj,
        a_hnd.AddrOfPinnedObject,
        new UIntPtr(Marshal.SizeOf(la.GetType.GetElementType) * la.Length),
        new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
        prev_ev.count,prev_ev.evs,res_ev
      ).RaiseIfError;
      
      cl.SetEventCallback(res_ev, CommandExecutionStatus.COMPLETE, cb, nil).RaiseIfError;
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandArrayFill(
      CommandQueue&<&Array> (self.a           .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset      .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len         .InternalCloneCached(muhs, cache))
    );
    
  end;
  BufferCommandValueFill = sealed class(SyncGPUCommand<Buffer>)
    public ptr: CommandQueue<IntPtr>;
    public pattern_len, offset, len: CommandQueue<integer>;
    
    public constructor(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>);
    begin
      inherited Create(ptr, pattern_len, offset, len);
      self.ptr := ptr;
      self.pattern_len := pattern_len;
      self.offset := offset;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override;
    begin
      var res_ptr := ptr.FinishTResCalc;
      
      cl.EnqueueFillBuffer(
        cq, b.memobj,
        res_ptr, new UIntPtr(pattern_len.FinishTResCalc),
        new UIntPtr(offset.FinishTResCalc), new UIntPtr(len.FinishTResCalc),
        prev_ev.count,prev_ev.evs,res_ev
      ).RaiseIfError;
      
      var cb: Event_Callback := (ev,st,data)->
      begin
        if st.IS_ERROR and (self.err=nil) then self.err := new OpenCLException(st.val);
        Marshal.FreeHGlobal(res_ptr);
        __NativUtils.GCHndFree(data);
      end;
      
      cl.SetEventCallback(res_ev, CommandExecutionStatus.COMPLETE, cb, __NativUtils.GCHndAlloc(cb)).RaiseIfError;
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandValueFill(
      CommandQueue&<IntPtr> (self.ptr         .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.pattern_len .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.offset      .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len         .InternalCloneCached(muhs, cache))
    );
    
  end;
  
  
function BufferCommandQueue.AddFillData(ptr: CommandQueue<IntPtr>; pattern_len, offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandDataFill(ptr,pattern_len, offset,len));

function BufferCommandQueue.AddFillArray(a: CommandQueue<&Array>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandArrayFill(a, offset,len));


function BufferCommandQueue.AddFillValue<TRecord>(val: TRecord; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFill(new IntPtr(__NativUtils.CopyToUnm(val)),Marshal.SizeOf&<TRecord>, offset,len));

function BufferCommandQueue.AddFillValue<TRecord>(val: CommandQueue<TRecord>; offset, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandValueFill(
  val.ThenConvert&<IntPtr>(vval-> //ToDo #2067
  begin
    var костыль_ptr: ^TRecord := pointer(@vval); //ToDo #2068
    Result := new IntPtr(__NativUtils.CopyToUnm(костыль_ptr^)); // вместо костыля - vval
  end), Marshal.SizeOf&<TRecord>,
  offset, len
));

{$endregion Fill}

{$region Copy}

type
  BufferCommandCopy = sealed class(SyncGPUCommand<Buffer>)
    public f_buf, t_buf: CommandQueue<Buffer>;
    public f_pos, t_pos, len: CommandQueue<integer>;
    
    public constructor(f_buf, t_buf: CommandQueue<Buffer>; f_pos, t_pos, len: CommandQueue<integer>);
    begin
      inherited Create(
        f_buf,t_buf,
        f_pos,t_pos,
        len
      );
      self.f_buf := f_buf;
      self.t_buf := t_buf;
      self.f_pos := f_pos;
      self.t_pos := t_pos;
      self.len := len;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; b: Buffer; prev_ev: __EventList; var res_ev: cl_event); override;
    begin
      var fb := f_buf.FinishTResCalc;
      var tb := t_buf.FinishTResCalc;
      if fb.memobj=cl_mem.Zero then fb.Init(c);
      if tb.memobj=cl_mem.Zero then tb.Init(c);
      
      cl.EnqueueCopyBuffer(
        cq, fb.memobj, tb.memobj,
        new UIntPtr(f_pos.FinishTResCalc), new UIntPtr(t_pos.FinishTResCalc),
        new UIntPtr(len.FinishTResCalc),
        prev_ev.count,prev_ev.evs, res_ev
      ).RaiseIfError;
      
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Buffer>; override :=
    new BufferCommandCopy(
      CommandQueue&<Buffer> (self.f_buf .InternalCloneCached(muhs, cache)),
      CommandQueue&<Buffer> (self.t_buf .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.f_pos .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.t_pos .InternalCloneCached(muhs, cache)),
      CommandQueue&<integer>(self.len   .InternalCloneCached(muhs, cache))
    );
    
  end;

function BufferCommandQueue.AddCopyFrom(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopy(b,res_q_hub=nil?res:self.GetNewResPlug, from,&to, len));

function BufferCommandQueue.AddCopyTo(b: CommandQueue<Buffer>; from, &to, len: CommandQueue<integer>) :=
AddCommand(new BufferCommandCopy(res_q_hub=nil?res:self.GetNewResPlug,b, &to,from, len));

{$endregion Copy}

{$endregion Buffer}

{$region Kernel}

{$region KernelCommandQueue}

function KernelCommandQueue.InternalClone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): CommandQueueBase;
begin
  var res := new KernelCommandQueue(self.res);
  
  if self.res_q_hub<>nil then
  begin
    var hub := MultiusableCommandQueueHub&<Kernel>(self.res_q_hub);
    
    res.res_q_hub := new MultiusableCommandQueueHub<Kernel>(CommandQueue&<Kernel>(
      hub.q.InternalCloneCached(muhs, cache)
    ));
    
    muhs.Add(self.res_q_hub, res.res_q_hub);
  end;
  
  res.commands.Capacity := self.commands.Capacity;
  foreach var comm in self.commands do res.commands += comm.Clone(muhs, cache);
  
  Result := res;
end;

{$endregion KernelCommandQueue}

{$region Exec}

type
  KernelCommandExec = sealed class(SyncGPUCommand<Kernel>)
    public work_szs_q: CommandQueue<array of UIntPtr>;
    public args_q: array of CommandQueue<Buffer>;
    
    static function GetSubQArr(work_szs_q: CommandQueue<array of UIntPtr>; args_q: array of CommandQueue<Buffer>): array of CommandQueueBase;
    begin
      Result := new CommandQueueBase[1+args_q.Length];
      for var i := 0 to args_q.Length-1 do
        Result[i] := args_q[i];
      Result[args_q.Length] := work_szs_q;
    end;
    
    public constructor(work_szs_q: CommandQueue<array of UIntPtr>; args_q: array of CommandQueue<Buffer>);
    begin
      inherited Create(GetSubQArr(work_szs_q,args_q));
      self.work_szs_q := work_szs_q;
      self.args_q := args_q;
    end;
    
    protected procedure EnqueueSelf(c: Context; cq: cl_command_queue; k: Kernel; prev_ev: __EventList; var res_ev: cl_event); override;
    begin
      var work_szs := work_szs_q.FinishTResCalc;
      
      for var i := 0 to args_q.Length-1 do
      begin
        var b := args_q[i].FinishTResCalc;
        if b.memobj=cl_mem.Zero then b.Init(c);
        cl.SetKernelArg(k._kernel, i, new UIntPtr(UIntPtr.Size), b.memobj).RaiseIfError;
      end;
      
      cl.EnqueueNDRangeKernel(
        cq,k._kernel,
        work_szs.Length,
        nil,work_szs,nil,
        prev_ev.count,prev_ev.evs,res_ev
      ).RaiseIfError;
      
    end;
    
    protected function Clone(muhs: Dictionary<object, object>; cache: Dictionary<CommandQueueBase, CommandQueueBase>): __GPUCommand<Kernel>; override :=
    new KernelCommandExec(
      CommandQueue&<array of UIntPtr>(self.work_szs_q.InternalCloneCached(muhs, cache)),
      self.args_q.ConvertAll(q->CommandQueue&<Buffer>(q.InternalCloneCached(muhs, cache)))
    );
    
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
  var ec: ErrorCode;
  if self.memobj<>cl_mem.Zero then cl.ReleaseMemObject(self.memobj).RaiseIfError;
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
