unit MiscUtils;
{$string_nullbased+}

uses System.Diagnostics;
uses System.Threading;
uses System.Threading.Tasks;

{$region Misc}

type
  StrConsts = static class
    const OutputPipeId = 'OutputPipeId';
  end;
  
var sec_thrs := new List<Thread>;
//var sec_procs := new List<Process>;
var sec_proc_halt_strs := new List<System.IO.Stream>;

var in_err_state := false;
var in_err_state_lock := new object;

var pack_timer := Stopwatch.StartNew;

var is_secondary_proc: boolean;
var nfi := new System.Globalization.NumberFormatInfo;
var enc := new System.Text.UTF8Encoding(true);

function TimeToStr(self: int64): string; extensionmethod :=
(self/10/1000/1000).ToString('N7', nfi).PadLeft(11);

procedure ErrOtp(e: Exception); forward;

procedure RegisterThr;
begin
  var thr := Thread.CurrentThread;
  
  lock sec_thrs do sec_thrs += thr;
  if in_err_state then thr.Abort;
  
end;

procedure StartBgThread(p: ()->());
begin
  var thr := new Thread(p);
  thr.IsBackground := true;
  thr.Start;
end;

function GetEXEFileName := System.Reflection.Assembly.GetExecutingAssembly.ManifestModule.FullyQualifiedName;

function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  if System.IO.Path.IsPathRooted(fname) then
  begin
    Result := fname;
    exit;
  end;
  
  var path := GetFullPath(base_folder);
  if path.EndsWith('\') then path := path.Remove(path.Length-1);
  
  while fname.StartsWith('..\') do
  begin
    fname := fname.Substring(3);
    path := System.IO.Path.GetDirectoryName(path);
  end;
  if fname.StartsWith('\') then fname := fname.Substring(1);
  
  Result := $'{path}\{fname}';
end;
function GetFullPathRTE(fname: string) := GetFullPath(fname, System.IO.Path.GetDirectoryName(GetEXEFileName));

function GetRelativePath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  fname := GetFullPath(fname);
  base_folder := GetFullPath(base_folder);
  
  var ind := 0;
  while true do
  begin
    if ind=fname.Length then break;
    if ind=base_folder.Length then break;
    if fname[ind]<>base_folder[ind] then break;
    ind += 1;
  end;
  
  if ind=0 then
  begin
    Result := fname;
    exit;
  end;
  
  var res := new StringBuilder;
  
  if ind <> base_folder.Length then
    loop base_folder.Skip(ind).Count(ch->ch='\') + 1 do
      res += '..\';
  
  if ind <> fname.Length then
  begin
    if fname[ind]='\' then ind += 1;
    res.Append(fname, ind, fname.Length-ind);
  end;
  
  Result := res.ToString;
end;
function GetRelativePathRTE(fname: string) := GetRelativePath(fname, System.IO.Path.GetDirectoryName(GetEXEFileName));

function GetArgs(key: string) := CommandLineArgs
.Where(arg->arg.StartsWith(key+'='))
.Select(arg->arg.SubString(key.Length+1));

{$endregion Misc}

{$region Exception's}

type
  MessageException = class(Exception)
    constructor(text: string) :=
    inherited Create(text);
  end;
  ParentHaltException = class(Exception)
    constructor := exit;
  end;
  
{$endregion Exception's}

{$region Timer's}

type
  ExeTimer = class;
  Timer = abstract class
    private static main: ExeTimer;
    
    protected total_time: int64;
    
    public function MeasureTime<T>(f: ()->T): T;
    begin
      var sw := Stopwatch.StartNew;
      try
        Result := f();
      finally
        sw.Stop;
        total_time += sw.ElapsedTicks;
      end;
    end;
    public procedure MeasureTime(p: ()->());
    begin
      var sw := Stopwatch.StartNew;
      try
        p();
      finally
        sw.Stop;
        total_time += sw.ElapsedTicks;
      end;
    end;
    
    private static TextLogLvlColors := Arr(System.ConsoleColor.Black, System.ConsoleColor.DarkGray);
    protected static property TextLogColor[lvl: integer]: System.ConsoleColor read TextLogLvlColors[lvl mod TextLogLvlColors.Length];
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string)->()); abstract;
    
    public static procedure TextLogAll(otp: (integer, string)->());
    
    public procedure Save(bw: System.IO.BinaryWriter); abstract;
    public procedure MergeLoad(br: System.IO.BinaryReader); abstract;
    
  end;
  
  SimpleTimer = sealed class(Timer)
    
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string)->()); override :=
    otp(lvl, $'{header} : {total_time.TimeToStr}');
    
    public procedure Save(bw: System.IO.BinaryWriter); override :=
    bw.Write(self.total_time);
    public procedure MergeLoad(br: System.IO.BinaryReader); override :=
    lock self do total_time += br.ReadInt64;
    
  end;
  
  ContainerTimer<TTimer> = sealed class(Timer) where TTimer: Timer, constructor;
    
    private sub_timers := new Dictionary<string, TTimer>;
    private function GetSubTimer(name: string): TTimer;
    begin
      lock sub_timers do
        if not sub_timers.TryGetValue(name, Result) then
        begin
          Result := new TTimer;
          sub_timers[name] := Result;
        end;
    end;
    property SubTimer[name: string]: TTimer read GetSubTimer; default;
    property SubTimerNames: sequence of string read sub_timers.Keys;
    property Empty: boolean read sub_timers.Count=0;
    
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string)->()); override;
    begin
      if Empty then exit;
      
      total_time := 0;
      foreach var t in sub_timers.Values do
      begin
        var tt := t as Timer; //ToDo #2247
        total_time += tt.total_time;
      end;
      
      otp(lvl, $'{header} : {total_time.TimeToStr}');
      
      var max_name_len := sub_timers.Keys.Max(name->name.Length);
      foreach var name in sub_timers.Keys do
        sub_timers[name].TextLog(lvl+1, $'♦ {name.PadRight(max_name_len)}', otp);
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter); override;
    begin
      bw.Write(sub_timers.Count);
      foreach var name in sub_timers.Keys do
      begin
        bw.Write(name);
        sub_timers[name].Save(bw);
      end;
    end;
    public procedure MergeLoad(br: System.IO.BinaryReader); override :=
    lock self do
      loop br.ReadInt32 do
        SubTimer[br.ReadString].MergeLoad(br);
    
  end;
  
  ExeTimer = sealed class(Timer)
    public pas_comp := new ContainerTimer<SimpleTimer>;
    public exe_exec := new ContainerTimer<ExeTimer>;
    
    private const total_str     = 'Total';
    private const pas_comp_str  = '.pas compilation';
    private const exe_exec_str  = '.exe execution';
    
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string)->()); override;
    begin
      if header=nil then header := total_str;
      
      otp(lvl, $'{header} : {total_time.TimeToStr}');
      
      var header_lens := new List<integer>;
      if not pas_comp.Empty then header_lens += pas_comp_str.Length;
      if not exe_exec.Empty then header_lens += exe_exec_str.Length;
      if header_lens.Count=0 then exit;
      var max_header_len := header_lens.Max;
      
      if not pas_comp.Empty then pas_comp.TextLog(lvl+1, pas_comp_str.PadRight(max_header_len), otp);
      if not exe_exec.Empty then exe_exec.TextLog(lvl+1, exe_exec_str.PadRight(max_header_len), otp);
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter); override;
    begin
      bw.Write(total_time);
      pas_comp.Save(bw);
      exe_exec.Save(bw);
    end;
    public procedure MergeLoad(br: System.IO.BinaryReader); override :=
    lock self do
    begin
      total_time += br.ReadInt64; // 0 для рута, поэтому не важно
      pas_comp.MergeLoad(br);
      exe_exec.MergeLoad(br);
    end;
    
  end;
  
static procedure Timer.TextLogAll(otp: (integer, string)->());
begin
  main.total_time := pack_timer.ElapsedTicks;
  main.TextLog(0, nil, otp);
end;

{$endregion Timer's}

{$region Otp type's}

type
  __AsyncQueueBase = abstract class(System.Collections.IEnumerable, System.Collections.IEnumerator)
    
    public function GetEnumerator: System.Collections.IEnumerator := self;
    
    protected function GetCurrentBase: object; abstract;
    public property IEnumerator.Current: object read GetCurrentBase;
    
    public function MoveNext: boolean; abstract;
    
    public procedure Reset := raise new System.NotSupportedException;
    
  end;
  AsyncQueue<T> = sealed class(__AsyncQueueBase, IEnumerable<T>, IEnumerator<T>)
    private q := new Queue<T>;
    private done := false;
    private ev := new ManualResetEvent(false);
    
    public procedure Enq(o: T) :=
    lock q do
    begin
      if done then raise new System.InvalidOperationException($'ERROR: Попытка писать в завершенную {self.GetType}');
      q.Enqueue(o);
      ev.Set;
    end;
    public procedure EnqRange(sq: sequence of T) :=
    foreach var o in sq do Enq(o);
    
    public procedure Finish;
    begin
      lock q do
      begin
        if done then raise new MessageException($'ERROR: Двойная попытка завершить {self.GetType}');
        done := true;
        ev.Set;
      end;
    end;
    
    public function GetEnumerator: IEnumerator<T> := self;
    
    private last_item: T;
    public property Current: T read last_item;
    protected function GetCurrentBase: object; override := last_item;
    public function MoveNext: boolean; override;
    begin
      last_item := default(T);
      
      lock q do
        if q.Count=0 then
        begin
          if done then
            exit else
            ev.Reset;
        end else
        begin
          last_item := q.Dequeue;
          Result := true;
          exit;
        end;
      
      ev.WaitOne;
      
      if (q.Count=0) and done then exit;
      
      lock q do last_item := q.Dequeue;
      Result := true;
    end;
    
    public procedure Dispose := exit;
    
  end;
  
  OtpLine = class;
  ThrProcOtp = AsyncQueue<OtpLine>;
  
  OtpLine = sealed class
    s: string;
    t: int64;
    bg_colors := System.Linq.Enumerable.Empty&<(integer,System.ConsoleColor)>;
    
    [System.ThreadStatic] static curr: ThrProcOtp;
    
    constructor(s: string; t: int64);
    begin
      self.s := s;
      self.t := t;
    end;
    constructor(s: string) := Create(s, pack_timer.ElapsedTicks);
    constructor(s: string; bg_colors: sequence of (integer,System.ConsoleColor));
    begin
      Create(s);
      self.bg_colors := bg_colors;
    end;
    
    static function operator implicit(s: string): OtpLine := new OtpLine(s);
    
    function ConvStr(f: string->string) := new OtpLine(f(self.s), self.t);
    
    function GetTimedStr :=
    $'{t.TimeToStr} | {s}';
    
    procedure Print;
    begin
      var i := 0;
      foreach var t in bg_colors do
      begin
        Console.BackgroundColor := t[1];
        Console.Write( s.Substring(i,t[0]) );
        i += t[0];
      end;
      Console.BackgroundColor := System.ConsoleColor.Black;
      Console.WriteLine( s.Substring(i) );
    end;
    
  end;
  
{$endregion Otp type's}

{$region Logging type's}

type
  Logger = abstract class
    public static main_log: Logger;
    
    private sub_loggers := new List<Logger>;
    
    protected static files_only_timed := false;
    
    public static procedure operator+=(log1, log2: Logger) :=
    log1.sub_loggers += log2;
    public static function operator+(log1, log2: Logger): Logger;
    begin
      log1 += log2;
      Result := log1;
    end;
    
    public procedure Otp(l: OtpLine); virtual;
    begin
      
      OtpImpl(l);
      
      foreach var log in sub_loggers do
        log.Otp(l);
    end;
    protected procedure OtpImpl(l: OtpLine); abstract;
    
    public procedure Close; virtual :=
    foreach var log in sub_loggers do
      log.Close;
    
  end;
  
  ConsoleLogger = sealed class(Logger)
    
    private constructor := exit;
    
    public procedure OtpImpl(l: OtpLine); override;
    begin
      if l.s.ToLower.Contains('error') then     Console.ForegroundColor := System.ConsoleColor.Red else
      if l.s.ToLower.Contains('fatal') then     Console.ForegroundColor := System.ConsoleColor.Red else
      if l.s.ToLower.Contains('exception') then Console.ForegroundColor := System.ConsoleColor.Red else
      if l.s.ToLower.Contains('warning') then   Console.ForegroundColor := System.ConsoleColor.Yellow else
        Console.ForegroundColor := System.ConsoleColor.DarkGreen;
      
      l.Print;
      
      Console.ForegroundColor := System.ConsoleColor.DarkGreen;
    end;
    
    public procedure Close; override;
    begin
      files_only_timed := true;
      
      self.Otp('');
      Timer.TextLogAll((lvl, s)->self.Otp(new OtpLine(' '*(lvl*4) + s, SeqGen(lvl, i->(i=0?3:4,Timer.TextLogColor[i])))));
      
      inherited;
    end;
    
  end;
  
  ParentStreamLogger = sealed class(Logger)
    private bw: System.IO.BinaryWriter;
    
    private constructor;
    begin
      var hnd_strs := GetArgs(StrConsts.OutputPipeId).Single.ToWords;
      
      var str := new System.IO.Pipes.AnonymousPipeClientStream(
        System.IO.Pipes.PipeDirection.Out,
        hnd_strs[0]
      );
      self.bw := new System.IO.BinaryWriter(str);
      bw.Write(byte(0)); // подтверждение соединения для другой стороны (так проще ошибку ловить)
      
      var halt_str := new System.IO.Pipes.AnonymousPipeClientStream(
        System.IO.Pipes.PipeDirection.In,
        hnd_strs[1]
      );
      StartBgThread(()->
      begin
        RegisterThr;
        if halt_str.ReadByte = 1 then
          ErrOtp(new ParentHaltException);
      end);
      
    end;
    
    protected procedure OtpImpl(l: OtpLine); override;
    begin
      bw.Write(1);
      bw.Write(l.t);
      bw.Write(l.s);
      bw.Flush;
    end;
    
    public procedure Close; override;
    begin
      
      bw.Write(2);
      Timer.main.Save(bw);
      bw.Close;
      
      inherited;
    end;
    
  end;
  
  FileLogger = sealed class(Logger)
    private bu_fname: string;
    private main_sw: System.IO.StreamWriter;
    private backup_sw: System.IO.StreamWriter;
    private timed: boolean;
    
    public constructor(fname: string; timed: boolean := false);
    begin
      self.bu_fname   := fname+'.backup';
      self.main_sw    := new System.IO.StreamWriter(fname, false, enc);
      self.backup_sw  := new System.IO.StreamWriter(bu_fname, false, enc);
      self.timed      := timed;
    end;
    
    public procedure OtpImpl(l: OtpLine); override;
    begin
      if files_only_timed and not timed then exit;
      var s := timed ? l.GetTimedStr : l.s;
      
      main_sw.WriteLine(s);
      main_sw.Flush;
      
      backup_sw.WriteLine(s);
      backup_sw.Flush;
      
    end;
    
    public procedure Close; override;
    begin
      
      main_sw.Close;
      backup_sw.Close;
      System.IO.File.Delete(bu_fname);
      
      inherited;
    end;
    
  end;
  
{$endregion Logging type's}

{$region Otp}

procedure Otp(line: OtpLine) :=
if OtpLine.curr<>nil then
  OtpLine.curr.Enq(line) else
lock Logger.main_log do
  Logger.main_log.Otp(line);

/// Остановка других потоков и подпроцессов, довывод асинхронного вывода и вывод ошибки
/// На случай ThreadAbortException - после вызова ErrOtp в потоке больше ничего быть не должно
procedure ErrOtp(e: Exception);
begin
  if e is ThreadAbortException then
  begin
    Thread.ResetAbort;
    Thread.CurrentThread.IsBackground := true;
    Thread.CurrentThread.Suspend;
  end;
//  Console.Error.WriteLine($'pre err {e}');
  
  // обычно это из за попытки писать в закрытый пайп, при аварийном завершении родителя
  // даём время родителю убить данный процесс через sec_proc_halt_strs
  if e is System.IO.IOException then Sleep(1000);
  lock in_err_state_lock do
  begin
    if in_err_state then exit;
    in_err_state := true;
  end;
  
  lock sec_thrs do
    foreach var thr in sec_thrs do
      if thr<>Thread.CurrentThread then
        thr.Abort;
  
  foreach var str in sec_proc_halt_strs do
  try
    str.WriteByte(1);
    str.Close;
  except
  end;
  
//  lock sec_procs do
//    foreach var p in sec_procs do
//      try
//        p.Kill;
//      except end;
  
  try
    
    if OtpLine.curr<>nil then
    begin
      var q := OtpLine.curr.q;
      OtpLine.curr := nil;
      lock q do foreach var l in q do Otp(l);
    end;
    
    if e is ParentHaltException then
      else
    if e is MessageException then
      Otp(e.Message) else
      Otp(e.ToString);
    
  except
    on dbl_e: System.IO.IOException do
    begin
      Sleep(1000); // обычно это из за ошибки вообще в другом процессе, лучше сначала дать довывести ту ошибку
      Console.Error.WriteLine($'{GetRelativePath(GetEXEFileName)} failed to output it''s error because: {dbl_e}');
    end;
  end;
  
  if is_secondary_proc then
    Halt(e.HResult) else
  begin
    Readln;
    Halt;
  end;
  
end;

{$endregion Otp}

{$region Process execution}

procedure RunFile(fname, nick: string; l_otp: OtpLine->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then raise new System.IO.FileNotFoundException(nil,fname);
  
  MiscUtils.Otp($'Runing {nick}');
  if l_otp=nil then l_otp := l->MiscUtils.Otp(l.ConvStr(s->$'{nick}: {s}'));
  
  var pipe := new System.IO.Pipes.AnonymousPipeServerStream(System.IO.Pipes.PipeDirection.In, System.IO.HandleInheritability.Inheritable);
  var halt_pipe := new System.IO.Pipes.AnonymousPipeServerStream(System.IO.Pipes.PipeDirection.Out, System.IO.HandleInheritability.Inheritable);
  lock sec_proc_halt_strs do sec_proc_halt_strs.Add( halt_pipe );
  
  var psi := new ProcessStartInfo(fname, pars.Append($'"{StrConsts.OutputPipeId}={pipe.GetClientHandleAsString} {halt_pipe.GetClientHandleAsString}"').JoinToString);
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.WorkingDirectory := System.IO.Path.GetDirectoryName(fname);
  
  var p := new Process;
  p.StartInfo := psi;
  
  var curr_timer: ExeTimer := Timer.main.exe_exec[nick];
  
  {$region otp capture}
  var start_time_mark: int64;
  var pipe_connection_established := false;
  
  var thr_otp := new ThrProcOtp;
  p.OutputDataReceived += (o,e)->
  try
    if e.Data=nil then
    begin
      if not pipe_connection_established then
        thr_otp.Finish;
    end else
      thr_otp.Enq(e.Data);
  except
    on exc: Exception do ErrOtp(exc);
  end;
  
  StartBgThread(()->
  try
    var br := new System.IO.BinaryReader(pipe);
    
    try
      br.ReadByte;
      pipe_connection_established := true;
      
      //ToDo разобраться на сколько это надо и куда сувать
      // - update: таки без него не видит завершение вывода при умирании процесса
      pipe.DisposeLocalCopyOfClientHandle;
      halt_pipe.DisposeLocalCopyOfClientHandle;
      
      while true do
      begin
        var otp_type := br.ReadInt32;
        
        case otp_type of
          
          1:
          begin
            var l := new OtpLine;
            l.t := start_time_mark + br.ReadInt64;
            l.s := br.ReadString;
            thr_otp.Enq(l);
          end;
          
          2:
          begin
            thr_otp.Finish;
            curr_timer.MergeLoad(br);
            br.Close;
            break;
          end;
          
          else raise new MessageException($'ERROR: Invalid bin otp type: [{otp_type}]');
        end;
        
      end;
      
    except
      on e: System.IO.EndOfStreamException do
      begin
        if pipe_connection_established then
          thr_otp.Finish else
          Otp($'WARNING: Pipe connection with "{nick}" wasn''t established');
        exit;
      end;
    end;
  except
    on e: Exception do ErrOtp(e);
  end);
  
  {$endregion otp capture}
  
//  lock sec_procs do sec_procs += p;
  curr_timer.MeasureTime(()->
  begin
    start_time_mark := pack_timer.ElapsedTicks;
    try
      p.Start;
    except
      on e: Exception do
        raise new Exception($'Failed to start [{fname}]', e);
    end;
    
    try
      
      p.BeginOutputReadLine;
      foreach var l in thr_otp do l_otp(l);
      p.WaitForExit;
      
      if p.ExitCode<>0 then
      begin
        var ex := System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode);
        ErrOtp(new MessageException($'Error in {nick}: {ex}'));
      end;
      
      MiscUtils.Otp($'Finished runing {nick}');
    finally
      try
        p.Kill;
      except end;
      lock sec_proc_halt_strs do sec_proc_halt_strs.Remove( halt_pipe );
    end;
    
  end);
  
  if not pipe_connection_established then pipe.Close;
end;

procedure CompilePasFile(fname: string; l_otp: OtpLine->(); err: string->(); params search_paths: array of string);
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then
    raise new System.IO.FileNotFoundException($'Файл "{GetRelativePath(fname)}" не найден');
  
  var nick := System.IO.Path.GetFileNameWithoutExtension(fname);
  
  foreach var p in Process.GetProcessesByName(nick) do
  begin
    Otp($'WARNING: Killed runing process [{nick}] to be able to compile .pas file');
    p.Kill;
  end;
  
  if l_otp=nil then l_otp := MiscUtils.Otp;
  if err=nil then err := s->raise new MessageException($'Error compiling "{GetRelativePath(fname)}": {s}');
  
  l_otp($'Compiling "{GetRelativePath(fname)}"');
  
  var psi := new ProcessStartInfo(
    'C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe',
    search_paths.Select(spath->$'/SearchDir:"{spath}"').Append($'"{fname}"').JoinToString
  );
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.RedirectStandardInput := true;
  
  var p := new Process;
  p.StartInfo := psi;
  
  Timer.main.pas_comp[nick].MeasureTime(()->
  begin
    p.Start;
    p.StandardInput.WriteLine;
    p.WaitForExit;
  end);
  
  var res := p.StandardOutput.ReadToEnd.Remove(#13).Trim(#10' '.ToArray);
  if res.ToLower.Contains('error') then
    err(res) else
    l_otp($'Finished compiling: {res}');
  
end;

procedure ExecuteFile(fname, nick: string; l_otp: OtpLine->(); err: string->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  var ffname := fname.Substring(fname.LastIndexOf('\')+1);
  if ffname.Contains('.') then
    case ffname.Substring(ffname.LastIndexOf('.')) of
      
      '.pas':
      begin
        
        CompilePasFile(fname, l_otp, err);
        
        fname := fname.Remove(fname.LastIndexOf('.'))+'.exe';
        ffname := fname.Substring(fname.LastIndexOf('\')+1);
      end;
      
      '.exe': ;
      
      else raise new MessageException($'ERROR: Unknown file extention: "{fname}"');
    end else
      raise new MessageException($'ERROR: File without extention: "{fname}"');
  
  RunFile(fname, nick, l_otp, pars);
end;



procedure RunFile(fname, nick: string; params pars: array of string) :=
RunFile(fname, nick, nil, pars);

procedure CompilePasFile(fname: string) :=
CompilePasFile(fname, nil, nil);

procedure ExecuteFile(fname, nick: string; params pars: array of string) :=
ExecuteFile(fname, nick, nil, nil, pars);

{$endregion Process execution}

{$region Task operations}

type
  SecThrProc = abstract class
    public own_otp: ThrProcOtp;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); abstract;
    private procedure SyncExecImpl; abstract;
    
    private function CreateThread := new Thread(()->
    try
      RegisterThr;
      OtpLine.curr := self.own_otp;
      SyncExecImpl;
      self.own_otp.Finish;
    except
      on e: Exception do ErrOtp(e);
    end);
    
    private function StartExecImpl: Thread;
    begin
      self.own_otp := new ThrProcOtp;
      Result := CreateThread;
      Result.Start;
    end;
    
    public procedure SyncExec;
    begin
      Prepare(new Dictionary<string, ManualResetEvent>);
      SyncExecImpl;
    end;
    
    public function StartExec: Thread;
    begin
      Prepare(new Dictionary<string, ManualResetEvent>);
      Result := StartExecImpl;
    end;
    
  end;
  
  SecThrProcCustom = sealed class(SecThrProc)
    private p: Action0;
    protected constructor(p: Action0) := self.p := p;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override := exit;
    private procedure SyncExecImpl; override := p;
    
  end;
  
  SecThrProcSum = sealed class(SecThrProc)
    private p1, p2: SecThrProc;
    
    protected constructor(p1, p2: SecThrProc);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override;
    begin
      p1.Prepare(evs);
      p2.Prepare(evs);
    end;
    
    private procedure SyncExecImpl; override;
    begin
      p1.SyncExecImpl;
      p2.SyncExecImpl;
    end;
    
  end;
  
  SecThrProcMlt = sealed class(SecThrProc)
    private p1,p2: SecThrProc;
    
    protected constructor(p1,p2: SecThrProc);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override;
    begin
      p1.Prepare(evs);
      p2.Prepare(evs);
    end;
    
    private procedure SyncExecImpl; override;
    begin
      p1.StartExecImpl;
      p2.StartExecImpl;
      
      foreach var l in p1.own_otp do Otp(l);
      foreach var l in p2.own_otp do Otp(l);
    end;
    
  end;
  
  SecThrProcExec = sealed class(SecThrProc)
    private fname, nick: string;
    private pars: array of string;
    
    protected constructor(fname, nick: string; params pars: array of string);
    begin
      self.fname := fname;
      self.nick := nick;
      self.pars := pars;
    end;
    
    private ev: ManualResetEvent;
    private prep_otp: ThrProcOtp;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override :=
    case System.IO.Path.GetExtension(fname) of
      
      '.pas':
      begin
        var pas_fname := fname;
        fname := System.IO.Path.ChangeExtension(pas_fname, '.exe');
        if evs.TryGetValue(pas_fname, self.ev) then exit;
        self.ev := new ManualResetEvent(false);
        evs[pas_fname] := self.ev;
        
        var p := new SecThrProcCustom(()->
        begin
          CompilePasFile(pas_fname);
          self.ev.Set;
        end);
        
        p.StartExecImpl;
        prep_otp := p.own_otp;
      end;
      
    end;
    
    private procedure SyncExecImpl; override;
    begin
      if prep_otp<>nil then foreach var l in prep_otp do Otp(l);
      if ev<>nil then ev.WaitOne;
      ExecuteFile(fname, nick, pars);
    end;
    
  end;
  
function operator+(p1,p2: SecThrProc): SecThrProc; extensionmethod :=
new SecThrProcSum(p1,p2);
procedure operator+=(var p1: SecThrProc; p2: SecThrProc); extensionmethod :=
p1 := p1+p2;

function operator*(p1,p2: SecThrProc): SecThrProc; extensionmethod :=
new SecThrProcMlt(p1,p2);

function ProcTask(p: Action0): SecThrProc :=
new SecThrProcCustom(p);

function CompTask(fname: string) :=
ProcTask(()->CompilePasFile(fname));

function ExecTask(fname, nick: string; params pars: array of string) :=
new SecThrProcExec(fname, nick, pars);

function EmptyTask := ProcTask(()->exit());

function SetEvTask(ev: ManualResetEvent) := ProcTask(()->begin ev.Set() end);
function EventTask(ev: ManualResetEvent) := ProcTask(()->begin ev.WaitOne() end);

function CombineAsyncTask(self: sequence of SecThrProc): SecThrProc; extensionmethod;
begin
  Result := EmptyTask;
  
  var evs := new List<ManualResetEvent>;
  foreach var t in self do
  begin
    var ev := new ManualResetEvent(false);
    
    var T_Wait: SecThrProc := EmptyTask;
    foreach var pev in evs.SkipLast(System.Environment.ProcessorCount+1) do T_Wait:=T_Wait + EventTask(pev);
    
    evs += ev;
    var T_ver :=
      T_Wait + t +
      SetEvTask(ev)
    ;
    
    Result := Result * T_ver;
  end;
  
end;

{$endregion Task operations}

// потому что лямбды не работают в initialization
///--
procedure InitMiscUtils :=
try
  // Заранее, чтоб выводить ошибки при инициализации
  Logger.main_log := new ConsoleLogger;
  
  RegisterThr;
  DefaultEncoding := enc;
  is_secondary_proc := GetArgs(StrConsts.OutputPipeId).Any;
  Timer.main := new ExeTimer;
  
  if is_secondary_proc then
    Logger.main_log := new ParentStreamLogger else
  begin
//    Console.OutputEncoding := enc;
    //ToDo желательно ещё Console.SetError, чтоб выводить в файл ошибки из финализации дочеренных процессов
    // - но при этом не забыть и про ошибку в финализации текущего процесса
  end;
  
  while not System.Environment.CurrentDirectory.EndsWith('POCGL') do
    System.Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(System.Environment.CurrentDirectory);
except
  on e: Exception do ErrOtp(e);
end;

///--
procedure FnlzMiscUtils;
begin
  
  try
    Logger.main_log.Close;
  except
    on e: System.IO.IOException do
    begin
      Sleep(1000); // обычно это из за ошибки вообще в другом процессе, лучше сначала дать довывести ту ошибку
      // тут из за Sleep, часто, следующая срочка даже не успевает выполнится потому что sec_proc_halt_strs
      Console.Error.WriteLine($'WARNING: {GetRelativePath(GetEXEFileName)} failed to close output because: {e}');
    end;
  end;
  
  if not is_secondary_proc then Readln;
  StartBgThread(()->
  begin
    Sleep(5000);
    Console.Error.WriteLine($'WARNING: {GetRelativePath(GetEXEFileName)} needed force halt because of some lingering non-background threads');
    if not is_secondary_proc then Readln;
    Halt;
  end);
end;

initialization
  InitMiscUtils;
finalization
  FnlzMiscUtils;
end.