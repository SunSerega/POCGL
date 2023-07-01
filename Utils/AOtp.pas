///Всё для асинхронного вывода (и вывода в целом)
unit AOtp;

interface

uses System.Threading;

uses AQueue;
uses CLArgs;

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
  
  {$region OtpKind}
  
  OtpKind = record
    private kind_names: array of string;
    
    public constructor(params kind_names: array of string) :=
      self.kind_names := kind_names;
    public constructor := Create(System.Array.Empty&<string>);
    
    public static property Invalid: OtpKind read default(OtpKind);
    public static property Empty: OtpKind read new OtpKind;
    public property IsInvalid: boolean read kind_names=nil;
    
    public static function operator implicit(kind_names: array of string): OtpKind :=
      new OtpKind(kind_names);
    public static function operator in(kind_name: string; k: OtpKind) :=
      kind_name in k.kind_names;
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(kind_names.Length);
      foreach var kind_name in kind_names do
        bw.Write(kind_name);
    end;
    public static function Load(br: System.IO.BinaryReader): OtpKind;
    begin
      Result.kind_names := new string[br.ReadInt32];
      for var i := 0 to Result.kind_names.Length-1 do
        Result.kind_names[i] := br.ReadString;
    end;
    
    public function ToString: string; override;
    begin
      if self.IsInvalid then
      begin
        Result := 'Invalid';
        exit;
      end;
      var res := new StringBuilder;
      res += 'OtpKind[';
      foreach var kind_name in kind_names index i do
      begin
        if i<>0 then
          res += '+';
        res += '"';
        res += kind_name;
        res += '"';
      end;
      res += ']';
      Result := res.ToString;
    end;
    
  end;
  
  GeneralOtpKind = record
    private registered := new HashSet<string>;
    private linked := new List<GeneralOtpKind>(1);
    
    public static procedure Link(k1, k2: GeneralOtpKind);
    begin
      k1.linked += k2;
      k2.linked += k1;
    end;
    
    private cached_kind := OtpKind.Invalid;
    public static procedure operator+=(var k: GeneralOtpKind; otp_kind: string) :=
      lock k.registered do
      begin
//        foreach var l in k.linked do
//          if otp_kind in l.registered then
//            raise new System.InvalidOperationException;
        k.cached_kind := OtpKind.Invalid;
        k.registered += otp_kind;
      end;
    
    public function Unwrap: OtpKind;
    begin
      lock registered do
        if not cached_kind.IsInvalid then
          Result := cached_kind else
        begin
          Result := new OtpKind(registered.ToArray);
          cached_kind := Result;
        end;
    end;
    
  end;
  
  {$endregion OtpKind}
  
  {$region OtpLine}
  
  OtpLine = class
    private s: string;
    private t: int64;
    private kind: OtpKind;
    
    private static pack_timer := Stopwatch.StartNew;
    public static function TotalTime := pack_timer.Elapsed;
    
    private constructor(s: string; t: int64; kind: OtpKind);
    begin
      self.s := s;
      self.t := t;
      self.kind := kind;
    end;
    public constructor(s: string; kind: OtpKind) := Create(s, pack_timer.ElapsedTicks, kind);
    public constructor(s: string) := Create(s, OtpKind.Empty);
    private constructor := raise new System.InvalidOperationException;
    
    public static function operator implicit(s: string): OtpLine := new OtpLine(s);
    public static function operator implicit(s: char): OtpLine := new OtpLine(s);
    
    public function ConvStr(f: string->string) := new OtpLine(f(self.s), self.t, self.kind);
    
    public function GetTimedStr :=
      $'{t/System.TimeSpan.TicksPerSecond,15:N7} | {s}';
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(self.s);
      bw.Write(self.t);
      kind.Save(bw);
    end;
    public static function Load(br: System.IO.BinaryReader; extra_time: int64) :=
      new OtpLine(
        br.ReadString,
        extra_time+br.ReadInt64,
        OtpKind.Load(br)
      );
    
    public function ToString: string; override := s;
    public procedure Println; virtual :=
      Console.WriteLine(self);
    
  end;
  OtpLineColored = sealed class(OtpLine)
    private bg_colors := System.Linq.Enumerable.Empty&<(integer,System.ConsoleColor)>;
    
    public constructor(s: string; kind: OtpKind; bg_colors: sequence of (integer,System.ConsoleColor));
    begin
      inherited Create(s, kind);
      self.bg_colors := bg_colors;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure Println; override;
    begin
      var org_c := Console.BackgroundColor;
      var i := 0;
      foreach var (len, c) in bg_colors do
      begin
        Console.BackgroundColor := c;
        Console.Write( s.Substring(i,len) );
        i += len;
      end;
      Console.BackgroundColor := org_c;
      Console.WriteLine( s.Remove(0,i) );
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
    protected static main: Logger;
    protected sub_loggers := new List<Logger>;
    
    public static procedure operator+=(log1, log2: Logger) :=
      lock log1.sub_loggers do log1.sub_loggers += log2;
    public static function operator+(log1, log2: Logger): Logger;
    begin
      log1 += log2;
      Result := log1;
    end;
    public static procedure AttachToMain(l: Logger) := main += l;
    
    public procedure Otp(l: OtpLine) := lock self do
    begin
      
      OtpImpl(l);
      
      foreach var log in sub_loggers do
        log.Otp(l);
    end;
    protected procedure OtpImpl(l: OtpLine); abstract;
    
    public procedure Close;
    begin
      
      CloseImpl;
      
      foreach var log in sub_loggers do
        log.Close;
      
    end;
    public procedure CloseImpl; abstract;
    
  end;
  
  ConsoleLogger = sealed class(Logger)
    
    private constructor;
    begin
      if Logger.main<>nil then
        raise new System.InvalidOperationException;
      Logger.main := self;
    end;
    
    public procedure OtpImpl(l: OtpLine); override;
    begin
      if 'error'     in l.s.ToLower then Console.ForegroundColor := System.ConsoleColor.Red else
      if 'fatal'     in l.s.ToLower then Console.ForegroundColor := System.ConsoleColor.Red else
      if 'exception' in l.s.ToLower then Console.ForegroundColor := System.ConsoleColor.Red else
      if 'warning'   in l.s.ToLower then Console.ForegroundColor := System.ConsoleColor.Yellow else
        Console.ForegroundColor := System.ConsoleColor.DarkGreen;
      
      l.Println;
      
      Console.ForegroundColor := System.ConsoleColor.DarkGreen;
    end;
    
    public procedure CloseImpl; override := exit;
    
  end;
  
  FileLogger = sealed class(Logger)
    private bu_fname: string;
    private main_sw: System.IO.StreamWriter;
    private backup_sw: System.IO.StreamWriter;
    private timed: boolean;
    private req_kinds, bad_kinds: OtpKind;
    private is_closed := false;
    
    public static nfi := new System.Globalization.NumberFormatInfo;
    public static enc := new System.Text.UTF8Encoding(true);
    
    private static g_exp_kinds, g_req_kinds, g_bad_kinds: GeneralOtpKind;
    static constructor := GeneralOtpKind.Link(g_req_kinds, g_bad_kinds);
    
    public static procedure RegisterGenerallyExpKind(kind: string) := g_exp_kinds += kind;
    public static procedure RegisterGenerallyReqKind(kind: string);
    begin
      g_req_kinds += kind;
      RegisterGenerallyExpKind(kind);
    end;
    public static procedure RegisterGenerallyBadKind(kind: string);
    begin
      g_bad_kinds += kind;
      RegisterGenerallyExpKind(kind);
    end;
    
    public constructor(fname: string; timed: boolean := false; req_kinds: OtpKind? := nil; bad_kinds: OtpKind? := nil);
    begin
      self.bu_fname   := fname+'.backup';
      self.main_sw    := new System.IO.StreamWriter(fname, false, enc);
      self.backup_sw  := new System.IO.StreamWriter(bu_fname, false, enc);
      self.timed      := timed;
      self.req_kinds  := if req_kinds<>nil then req_kinds.Value else g_req_kinds.Unwrap;
      self.bad_kinds  := if bad_kinds<>nil then bad_kinds.Value else if timed then OtpKind.Empty else g_bad_kinds.Unwrap;
    end;
    
    public property IsTimed: boolean read timed;
    
    public procedure OtpImpl(l: OtpLine); override;
    begin
      if l.kind.kind_names.Any(k->k not in g_exp_kinds.Unwrap) then
        raise new System.InvalidOperationException($'Kind {l.kind} was not expected');
      if self.req_kinds.kind_names.Any(k->k not in l.kind) then
        exit;
      if self.bad_kinds.kind_names.Any(k->k in l.kind) then
        exit;
      
      if is_closed then
      begin
        Logger.main.OtpImpl($'WARNING: Tried to write after file close: {l}');
        exit;
      end;
      
      var s := timed ? l.GetTimedStr : l.s;
      
      main_sw.WriteLine(s);
      main_sw.Flush;
      
      backup_sw.WriteLine(s);
      backup_sw.Flush;
      
    end;
    
    public procedure CloseImpl; override;
    begin
//      Write(
//        $'[{bu_fname}] FileLogger.CloseImpl:'+#10+
//        System.Environment.StackTrace
//      );
      is_closed := true;
      main_sw.Close;
      backup_sw.Close;
      System.IO.File.Delete(bu_fname);
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
procedure Otp(line: string; kind: OtpKind);
procedure Otp(line: string; kinds: array of string);
procedure ErrOtp(e: Exception);

function IsSeparateExecution: boolean;
procedure FinishedPause;

implementation

uses PathUtils;

procedure AsyncProcOtp.Dump;
begin
  if parent<>nil then
    parent.Dump;
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
procedure Otp(line: string; kind: OtpKind) :=
  Otp(new OtpLine(line, kind));
procedure Otp(line: string; kinds: array of string) :=
  Otp(line, new OtpKind(kinds));

/// Остановка других потоков и подпроцессов, довывод асинхронного вывода и вывод ошибки
/// На случай ThreadAbortException - после вызова ErrOtp в потоке больше ничего быть не должно
procedure ErrOtp(e: Exception);
begin
//  Otp(e.ToString);
  
  foreach var h in EmergencyHandler.All do
    h.Handle;
  
  if e is ParentHaltException then
    Halt;
  
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
//  Otp($'Thread {Thread.CurrentThread.ManagedThreadId} runs ErrOtp');
//  Otp(System.Environment.StackTrace);
//  Otp(e.ToString);
  
  lock sec_thrs do
    foreach var thr in sec_thrs do
      if thr<>Thread.CurrentThread then
      try
        thr.Abort;
      except
        on abort_e: System.Threading.ThreadStateException do
          if not thr.ThreadState.HasFlag(System.Threading.ThreadState.Suspended) then
            raise;
      end;
  
  try
    
    if AsyncProcOtp.curr<>nil then
    begin
      var curr_otp := AsyncProcOtp.curr;
      AsyncProcOtp.curr := nil;
      curr_otp.Dump;
    end;
    
    if e is MessageException then
      Otp(e.Message) else
      Otp(e.ToString);
    
  except
    on dbl_e: System.IO.IOException do
    begin
      Sleep(100); // Обычно это из за ошибки вообще в другом процессе, лучше сначала дать довывести ту ошибку
      Console.Error.WriteLine($'{GetRelativePath(GetEXEFileName)} failed to output it''s error because: {dbl_e}');
      Console.Error.WriteLine('Trying again, simplified:');
      Console.Error.WriteLine(e);
      Console.Error.WriteLine('(end simplified error output)');
    end;
  end;
  
  FinishedPause;
  Halt(e.HResult);
end;

function IsSeparateExecution := Logger.main is ConsoleLogger;
procedure FinishedPause;
begin
  if not IsSeparateExecution then exit;
  if '[REDIRECTIOMODE]' in System.Environment.GetCommandLineArgs.Skip(1).Take(1) then exit;
  if 'SkipFinishedPause' in CommandLineArgs then exit;
  ReadString(#10'Press Enter to exit:');
end;

// Потому что лямбды не работают в finalization
procedure MakeSureToExit;
begin
  FinishedPause;
  StartBgThread(()->
  begin
    Sleep(5000);
    Console.Error.WriteLine($'WARNING: {GetRelativePath(GetEXEFileName)} needed force halt because of some lingering non-background threads');
    FinishedPause;
    Halt(1);
  end);
end;

initialization
  try
    OtpLine.TotalTime;
    new ConsoleLogger;
    RegisterThr;
    DefaultEncoding := FileLogger.enc;
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