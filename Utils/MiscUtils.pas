unit MiscUtils;

uses System.Diagnostics;
uses System.Threading;
uses System.Threading.Tasks;

{$region Misc}

var sec_procs := new List<Process>;
var sec_thrs := new List<Thread>;
var in_err_state := false;
var nfi := new System.Globalization.NumberFormatInfo;
var enc := new System.Text.UTF8Encoding(true);

function TimeToStr(self: int64): string; extensionmethod :=
(self/10/1000/1000).ToString('N7', nfi).PadLeft(15);

type
  MessageException = class(Exception)
    constructor(text: string) :=
    inherited Create(text);
  end;
  
  Timers = static class
    
    static pas_comp := int64(0);
    static every_pas_comp := new Dictionary<string, int64>;
    
    static exe_exec := int64(0);
    static every_exe_exec := new Dictionary<string, int64>;
    
    static procedure AddPasTime(nick: string; t: int64) :=
    lock every_pas_comp do
    begin
      pas_comp += t;
      if every_pas_comp.ContainsKey(nick) then
        every_pas_comp[nick] += t else
        every_pas_comp[nick] := t;
    end;
    
    static procedure AddExeTime(nick: string; t: int64) :=
    lock every_exe_exec do
    begin
      exe_exec += t;
      if every_exe_exec.ContainsKey(nick) then
        every_exe_exec[nick] += t else
        every_exe_exec[nick] := t;
    end;
    
    static procedure LogAll;
    
  end;
  
  OtpLine = sealed class
    s: string;
    t: int64;
    
    static pack_timer := Stopwatch.StartNew;
    static function operator implicit(s: string): OtpLine;
    begin
      Result := new OtpLine;
      Result.s := s;
      Result.t := pack_timer.ElapsedTicks;
    end;
    
    function ConvStr(f: string->string): OtpLine;
    begin
      Result := new OtpLine;
      Result.s := f(self.s);
      Result.t := self.t;
    end;
    
  end;
  
  ThrProcOtp = sealed class
    q := new Queue<OtpLine>;
    done := false;
    ev := new ManualResetEvent(false);
    
    [System.ThreadStatic] static curr: ThrProcOtp;
    
    procedure Enq(l: OtpLine) :=
    lock q do
    begin
      q.Enqueue(l);
      ev.Set;
    end;
    
    procedure EnqSub(o: ThrProcOtp) :=
    foreach var l in o.Enmr do Enq(l);
    
    procedure Finish;
    begin
      done := true;
      lock q do ev.Set;
    end;
    
    function Deq: OtpLine;
    begin
      Result := nil;
//      lock output do Writeln($'{Thread.CurrentThread.ManagedThreadId}: start deq');
      
      lock q do
        if q.Count=0 then
        begin
          if done then
          begin
//            lock output do Writeln($'{Thread.CurrentThread.ManagedThreadId}: exit deq');
            exit;
          end else
            ev.Reset;
        end else
        begin
          Result := q.Dequeue;
//          lock output do Writeln($'{Thread.CurrentThread.ManagedThreadId}: deq ret "{Result}"');
          exit;
        end;
      
      ev.WaitOne;
      lock q do Result := (q.Count=0) and done ? nil : q.Dequeue;
//      lock output do Writeln($'{Thread.CurrentThread.ManagedThreadId}: deq wait ret "{Result}"');
    end;
    
    function Enmr: sequence of OtpLine;
    begin
      while true do
      begin
        var l := Deq;
        if l=nil then exit;
        yield l;
      end;
    end;
    
  end;
  
function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  if fname.Substring(1).StartsWith(':\') then
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

{$endregion Misc}

{$region Otp}

var otp_lock := new object;
var log_file: string := nil;
var timed_log_file: string := nil;

const AddTimeMarksStr = 'AddTimeMarks';
var otp_time_marks := CommandLineArgs.Contains(AddTimeMarksStr);

procedure Otp(line: OtpLine) :=
if ThrProcOtp.curr<>nil then
  ThrProcOtp.curr.Enq(line) else
lock otp_lock do
begin
  
  if log_file<>nil then
    while true do
    try
      if System.IO.File.Exists(log_file) then
        System.IO.File.Copy(log_file, log_file+'.savepoint');
      System.IO.File.AppendAllLines(log_file, Arr(line.s));
      System.IO.File.Delete(log_file+'.savepoint');
      break;
    except end;
  
  if timed_log_file<>nil then
    while true do
    try
      if System.IO.File.Exists(timed_log_file) then
        System.IO.File.Copy(timed_log_file, timed_log_file+'.savepoint');
      System.IO.File.AppendAllLines(timed_log_file, Arr($'{line.t.TimeToStr} | {line.s}'));
      System.IO.File.Delete(timed_log_file+'.savepoint');
      break;
    except end;
  
  if line.s.ToLower.Contains('error') then      System.Console.ForegroundColor := System.ConsoleColor.Red else
  if line.s.ToLower.Contains('fatal') then      System.Console.ForegroundColor := System.ConsoleColor.Red else
  if line.s.ToLower.Contains('exception') then  System.Console.ForegroundColor := System.ConsoleColor.Red else
  if line.s.ToLower.Contains('warning') then    System.Console.ForegroundColor := System.ConsoleColor.Yellow else
    System.Console.ForegroundColor := System.ConsoleColor.DarkGreen;
  
  if otp_time_marks then line.s := $'{line.t.TimeToStr} | {line.s}';
  System.Console.WriteLine(line.s);
end;

/// Остановка других потоков и подпроцессов, довывод асинхронного вывода и вывод ошибки
/// На случай ThreadAbortException - после вызова ErrOtp в потоке больше ничего быть не должно
procedure ErrOtp(e: Exception);
begin
  if e is ThreadAbortException then
  begin
    Thread.ResetAbort;
    exit;
  end;
  
  lock sec_procs do
  begin
    if in_err_state then exit;
    in_err_state := true;
  end;
  
  lock sec_thrs do
    foreach var thr in sec_thrs do
      if thr<>Thread.CurrentThread then
        thr.Abort;
  
  lock sec_procs do
    foreach var p in sec_procs do
      try
        p.Kill;
      except end;
  
  if ThrProcOtp.curr<>nil then
  begin
    var q := ThrProcOtp.curr.q;
    ThrProcOtp.curr := nil;
    lock q do foreach var l in q do Otp(l);
  end;
  
  if e is MessageException then
    Otp(e.Message) else
    Otp(e.ToString);
  
  if not CommandLineArgs.Contains('SecondaryProc') then
  begin
    Readln;
    Halt;
  end else
    Halt(e.HResult);
  
end;

static procedure Timers.LogAll;
begin
  log_file := nil;
  Otp('');
  
  Otp($'.pas compilation : {pas_comp.TimeToStr}');
  if every_pas_comp.Count<>0 then
  begin
    var max_key_w := every_pas_comp.Keys.Max(key->key.Length);
    foreach var key in every_pas_comp.Keys do
      Otp($'    - {key.PadRight(max_key_w)} : {every_pas_comp[key].TimeToStr}');
  end;
  
  Otp($'.exe execution   : {exe_exec.TimeToStr}');
  if every_exe_exec.Count<>0 then
  begin
    var max_key_w := every_exe_exec.Keys.Max(key->key.Length);
    foreach var key in every_exe_exec.Keys do
      Otp($'    - {key.PadRight(max_key_w)} : {every_exe_exec[key].TimeToStr}');
  end;
  
end;

{$endregion Otp}

{$region Fixers}

type
  Fixer<T> = abstract class// where T: Fixer<T>; //ToDo #2191
    protected name: string;
    protected used: boolean;
    
    private static all := new Dictionary<string, T>;
    public static adders := new List<T>;
    protected static empty: T;
    protected constructor(name: string);
    begin
      self.name := name;
      if name=nil then exit; // внутренний фиксер, то есть или empty, или содержащийся в контейнере
      all.Add(name, T(self as object)); //ToDo #2191, но T() нужно
    end;
    
    private static function GetItem(name: string): T;
    begin
      if all.TryGetValue(name, Result) then
        (Result as object as Fixer<T>).used := true else //ToDo #2191
        Result := empty;
    end;
    public static property Item[name: string]: T read GetItem; default;
    
    protected static function ReadBlocks(lines: sequence of string; power_sign: string): sequence of (string, array of string);
    begin
      var res := new List<string>;
      var name: string := nil;
      
      foreach var l in lines do
        if l.StartsWith(power_sign) then
        begin
          if name<>nil then
          begin
            yield (name, res.ToArray);
            res.Clear;
          end;
          name := l.Substring(power_sign.Length).Trim;
        end else
        if name<>nil then
          res += l;
      
      if name<>nil then yield (name, res.ToArray);
    end;
    protected static function ReadBlocks(fname: string) := ReadBlocks(ReadLines(fname), '#');
    
    protected procedure WarnUnused; abstract;
    public static procedure WarnAllUnused :=
    foreach var f in all.Values do
      if ((f as object as Fixer<T>).name<>nil) and not (f as object as Fixer<T>).used then //ToDo #2191 //ToDo #2191
        (f as object as Fixer<T>).WarnUnused; //ToDo #2191
    
  end;
  
{$endregion Fixers}

{$region Process execution}

procedure RunFile(fname, nick: string; l_otp: OtpLine->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then raise new System.IO.FileNotFoundException(nil,fname);
  if l_otp=nil then l_otp := l->MiscUtils.Otp(l.ConvStr(s->$'{nick}: {s}'));
  
  MiscUtils.Otp($'Runing {nick}');
  
  var psi := new ProcessStartInfo(fname, pars.Append('"SecondaryProc"').JoinIntoString);
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.WorkingDirectory := System.IO.Path.GetDirectoryName(fname);
  
  var p := new Process;
  lock sec_procs do sec_procs += p;
  p.StartInfo := psi;
  
  var thr_otp := new ThrProcOtp;
  p.OutputDataReceived += (o,e) ->
  if e.Data=nil then
    thr_otp.Finish else
    thr_otp.Enq(e.Data);
  
  var exp_time_marks := pars.Contains(AddTimeMarksStr);
  p.Start;
  var start_time_mark := OtpLine.pack_timer.ElapsedTicks;
  var curr_exe_timer := Stopwatch.StartNew;
  
  try
    p.BeginOutputReadLine;
    
    var thr_otp_sq := thr_otp.Enmr;
    if exp_time_marks then thr_otp_sq := thr_otp_sq.Select(l->
    begin
      var ind := l.s.IndexOf(' | ');
      if ind=-1 then
      begin
        Result := l;
        exit;
      end;
      Result := new OtpLine;
      Result.t := start_time_mark+int64.Parse(l.s.Remove(ind).Remove('.'));
      Result.s := l.s.Remove(0, ind+3);
    end);
    foreach var l in thr_otp_sq do l_otp(l);
//    p.WaitForExit;
    
    curr_exe_timer.Stop;
    Timers.AddExeTime(nick, curr_exe_timer.ElapsedTicks);
    curr_exe_timer.Reset;
    
    if p.ExitCode<>0 then
    begin
      var ex := System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode);
      ErrOtp(new Exception($'Error in {nick}:', ex));
    end;
    
    MiscUtils.Otp($'Finished runing {nick}');
  finally
    
    try
      p.Kill;
    except end;
    
    curr_exe_timer.Stop;
    Timers.AddExeTime(nick, curr_exe_timer.ElapsedTicks);
  end;
end;

procedure CompilePasFile(fname: string; l_otp: OtpLine->(); err: string->());
begin
  fname := GetFullPath(fname);
  var nick := fname.Substring(fname.LastIndexOf('\')+1);
  
  if l_otp=nil then l_otp := MiscUtils.Otp;
  if err=nil then err := s->raise new MessageException($'Error compiling "{fname}": {s}');
  
  l_otp($'Compiling "{fname}"');
  
  var psi := new ProcessStartInfo('C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe', $'"{fname}"');
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.RedirectStandardInput := true;
  
  var p := new Process;
  p.StartInfo := psi;
  
  var comp_timer := Stopwatch.StartNew;
  p.Start;
  p.StandardInput.WriteLine;
  p.WaitForExit;
  comp_timer.Stop;
  Timers.AddPasTime(nick, comp_timer.ElapsedTicks);
  
  var res := p.StandardOutput.ReadToEnd.Remove(#13).Trim(#10' '.ToArray);
  if res.ToLower.Contains('error') then
    err(res) else
    l_otp($'Finished compiling: {res}');
  
end;

procedure ExecuteFile(fname, nick: string; l_otp: OtpLine->(); err: string->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  var ffname := fname.Contains('\') ? fname.Substring(fname.LastIndexOf('\')+1) : fname;
  if ffname.Contains('.') then
    case ffname.Substring(ffname.LastIndexOf('.')) of
      
      '.pas':
      begin
        
        CompilePasFile(fname, l_otp, err);
        
        fname := fname.Remove(fname.Length-4)+'.exe';
        ffname := ffname.Remove(ffname.Length-4)+'.exe';
      end;
      
      '.exe': ;
      
      else raise new MessageException($'Unknown file extention: "{fname}"');
    end else
      raise new MessageException($'file without extention: "{fname}"');
  
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

procedure RegisterThr;
begin
  var thr := Thread.CurrentThread;
  
  lock sec_thrs do sec_thrs += thr;
  if in_err_state then thr.Abort;
  
end;

type
  SecThrProc = abstract class
    own_otp: ThrProcOtp;
    
    procedure SyncExec; abstract;
    
    function CreateThread := new Thread(()->
    try
      RegisterThr;
      ThrProcOtp.curr := self.own_otp;
      SyncExec;
      self.own_otp.Finish;
    except
      on e: Exception do ErrOtp(e);
    end);
    
    function StartExec: Thread;
    begin
      self.own_otp := new ThrProcOtp;
      Result := CreateThread;
      Result.Start;
    end;
    
  end;
  
  SecThrProcCustom = sealed class(SecThrProc)
    p: Action0;
    constructor(p: Action0) := self.p := p;
    
    procedure SyncExec; override := p;
    
  end;
  
  SecThrProcSum = sealed class(SecThrProc)
    p1,p2: SecThrProc;
    
    constructor(p1,p2: SecThrProc);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    procedure SyncExec; override;
    begin
      p1.SyncExec;
      p2.SyncExec;
    end;
    
  end;
  
  SecThrProcMlt = sealed class(SecThrProc)
    p1,p2: SecThrProc;
    
    constructor(p1,p2: SecThrProc);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    procedure SyncExec; override;
    begin
      p1.StartExec;
      p2.StartExec;
      
      foreach var l in p1.own_otp.Enmr do Otp(l);
      foreach var l in p2.own_otp.Enmr do Otp(l);
    end;
    
  end;
  
function operator+(p1,p2: SecThrProc): SecThrProc; extensionmethod :=
new SecThrProcSum(p1,p2);

function operator*(p1,p2: SecThrProc): SecThrProc; extensionmethod :=
new SecThrProcMlt(p1,p2);

function ProcTask(p: Action0): SecThrProc :=
new SecThrProcCustom(p);

function CompTask(fname: string) :=
ProcTask(()->CompilePasFile(fname));

function ExecTask(fname, nick: string; params pars: array of string) :=
ProcTask(()->ExecuteFile(fname, nick, pars));

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
    evs += ev;
    
    var T_Wait: SecThrProc := EmptyTask;
    foreach var pev in evs.SkipLast(System.Environment.ProcessorCount+1) do T_Wait:=T_Wait + EventTask(pev);
    
    var T_ver :=
      T_Wait + t +
      SetEvTask(ev)
    ;
    
    Result := Result * T_ver;
  end;
  
end;

{$endregion Task operations}

begin
  DefaultEncoding := enc;
  RegisterThr;
  while not System.Environment.CurrentDirectory.EndsWith('POCGL') do
    System.Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(System.Environment.CurrentDirectory);
end.