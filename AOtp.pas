///Всё для асинхронного вывода (и вывода в целом)
unit AOtp;

interface

uses System.Threading;

uses AQueue;
uses CLArgs;

var pack_timer := Stopwatch.StartNew;

var nfi := new System.Globalization.NumberFormatInfo;
var enc := new System.Text.UTF8Encoding(true);

type
  
  {$region Exception's}
  
  MessageException = class(Exception)
    public constructor(text: string) :=
    inherited Create(text);
    private constructor := raise new System.InvalidOperationException;
  end;
  ParentHaltException = class(Exception)
    public constructor := exit;
  end;
  
  {$endregion Exception's}
  
  {$region OtpLine}
  
  OtpLine = class
    s: string;
    t: int64;
    
    constructor(s: string; t: int64);
    begin
      self.s := s;
      self.t := t;
    end;
    constructor(s: string) := Create(s, pack_timer.ElapsedTicks);
    
    static function operator implicit(s: string): OtpLine := new OtpLine(s);
    static function operator implicit(s: char): OtpLine := new OtpLine(s);
    
    function ConvStr(f: string->string) := new OtpLine(f(self.s), self.t);
    
    function GetTimedStr :=
    $'{t/System.TimeSpan.TicksPerSecond,15:N7} | {s}';
    
    procedure Println; virtual :=
    Console.WriteLine(s);
    
  end;
  OtpLineColored = sealed class(OtpLine)
    bg_colors := System.Linq.Enumerable.Empty&<(integer,System.ConsoleColor)>;
    
    constructor(s: string; bg_colors: sequence of (integer,System.ConsoleColor));
    begin
      inherited Create(s);
      self.bg_colors := bg_colors;
    end;
    
    procedure Println; override;
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
  
  {$endregion OtpLine}
  
  {$region AsyncProcOtp}
  
  AsyncProcOtp = sealed class(AsyncQueue<OtpLine>)
    private parent: AsyncProcOtp;
    public [System.ThreadStatic] static curr: AsyncProcOtp;
    
    public constructor(parent: AsyncProcOtp) :=
    self.parent := parent;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure Dump;
    
  end;
  
  {$endregion AsyncProcOtp}
  
  {$region Logger's}
  
  Logger = abstract class
    public static main: Logger;
    public sub_loggers := new List<Logger>;
    
    public static procedure operator+=(log1, log2: Logger) :=
    lock log1.sub_loggers do log1.sub_loggers += log2;
    public static function operator+(log1, log2: Logger): Logger;
    begin
      log1 += log2;
      Result := log1;
    end;
    
    public procedure Otp(l: OtpLine) :=
    lock self do
    begin
      
      OtpImpl(l);
      
      lock sub_loggers do
        foreach var log in sub_loggers do
          log.Otp(l);
    end;
    protected procedure OtpImpl(l: OtpLine); abstract;
    
    public event PreClose: procedure;
    public procedure Close; virtual;
    begin
      var PreClose := self.PreClose;
      if PreClose<>nil then PreClose();
      
      foreach var log in sub_loggers do
        log.Close;
      
    end;
    
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
      
      l.Println;
      
      Console.ForegroundColor := System.ConsoleColor.DarkGreen;
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
    
    public property IsTimed: boolean read timed;
    
    public procedure OtpImpl(l: OtpLine); override;
    begin
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
  
  {$endregion Logger's}
  
  {$region EmergencyHandler's}
  
  EmergencyHandler = abstract class
    public static All := new List<EmergencyHandler>;
    
    public constructor :=
    lock All do All += self;
    
    public procedure Handle; abstract;
    
  end;
  
  {$endregion EmergencyHandler'}
  
procedure RegisterThr;
procedure StartBgThread(p: ()->());

procedure Otp(line: OtpLine);
procedure ErrOtp(e: Exception);

implementation

uses PathUtils;

procedure AsyncProcOtp.Dump;
begin
  if parent<>nil then parent.Dump;
  lock self.q do
    foreach var l in q do
      Otp(l);
end;

var in_err_state := false;
var in_err_state_lock := new object;

var sec_thrs := new List<Thread>;

procedure RegisterThr;
begin
  var thr := Thread.CurrentThread;
  
  lock sec_thrs do sec_thrs += thr;
  if in_err_state then thr.Abort;
  
end;

procedure StartBgThread(p: ()->());
begin
  var thr := new Thread(RegisterThr + p);
  thr.IsBackground := true;
  thr.Start;
end;

procedure Otp(line: OtpLine) :=
if AsyncProcOtp.curr<>nil then
  AsyncProcOtp.curr.Enq(line) else
if Logger.main=nil then
  line.Println else
  Logger.main.Otp(line);

/// Остановка других потоков и подпроцессов, довывод асинхронного вывода и вывод ошибки
/// На случай ThreadAbortException - после вызова ErrOtp в потоке больше ничего быть не должно
procedure ErrOtp(e: Exception);
begin
  var EternalSleep := procedure->
  begin
    Thread.CurrentThread.IsBackground := true;
    Thread.CurrentThread.Suspend;
  end;
  
  if e is ThreadAbortException then
  begin
    Thread.ResetAbort;
    EternalSleep;
  end;
//  Console.Error.WriteLine($'pre err {e}');
  
  // Обычно это из за попытки писать в закрытый пайп, при аварийном завершении родителя
  // Даём время родителю убить данный процесс через sec_proc_halt_strs
  if e.GetType = typeof(System.IO.IOException) then Sleep(100);
  lock in_err_state_lock do
  begin
    if in_err_state then
    begin
      Monitor.Exit(in_err_state_lock);
      EternalSleep;
    end;
    in_err_state := true;
  end;
  
  lock sec_thrs do
    foreach var thr in sec_thrs do
      if thr<>Thread.CurrentThread then
      try
        thr.Abort;
      except
        on abort_e: System.Threading.ThreadStateException do
          if not thr.ThreadState.HasFlag(System.Threading.ThreadState.Suspended) then
            raise abort_e;
      end;
  
  foreach var h in EmergencyHandler.All do
    h.Handle;
  
  try
    
    if AsyncProcOtp.curr<>nil then
    begin
      var curr_otp := AsyncProcOtp.curr;
      AsyncProcOtp.curr := nil;
      curr_otp.Dump;
    end;
    
    if e is ParentHaltException then
      else
    if e is MessageException then
      Otp(e.Message) else
      Otp(e.ToString);
    
  except
    on dbl_e: System.IO.IOException do
    begin
      Sleep(100); // Обычно это из за ошибки вообще в другом процессе, лучше сначала дать довывести ту ошибку
      Console.Error.WriteLine($'{GetRelativePath(GetEXEFileName)} failed to output it''s error because: {dbl_e}');
    end;
  end;
  
  if Logger.main is ConsoleLogger then
  begin
    Readln;
    Halt;
  end else
    Halt(e.HResult);
  
end;

// Потому что лямбды не работают в finalization
procedure MakeSureToExit;
begin
  if Logger.main is ConsoleLogger then ReadString(#10'Press Enter to exit:');
  StartBgThread(()->
  begin
    Sleep(5000);
    Console.Error.WriteLine($'WARNING: {GetRelativePath(GetEXEFileName)} needed force halt because of some lingering non-background threads');
    if Logger.main is ConsoleLogger then ReadString('Press Enter to Halt:');
    Halt;
  end);
end;

initialization
  try
    Logger.main := new ConsoleLogger;
    RegisterThr;
    DefaultEncoding := enc;
  except
    on e: Exception do ErrOtp(e);
  end;
finalization
  try
    Logger.main.Close;
    MakeSureToExit;
  except
    on e: Exception do Console.Error.WriteLine(e);
  end;
end.