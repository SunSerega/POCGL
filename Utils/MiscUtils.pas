unit MiscUtils;
uses System.Diagnostics;
uses System.Threading;
uses System.Threading.Tasks;

{$region Misc}

var sec_procs := new List<Process>;
var sec_thrs := new List<Thread>;
var in_err_state := false;

type
  MessageException = class(Exception)
    constructor(text: string) :=
    inherited Create(text);
  end;
  
  ThrProcOtp = sealed class
    q := new Queue<string>;
    done := false;
    ev := new ManualResetEvent(false);
    
    [System.ThreadStatic] static curr: ThrProcOtp;
    
    procedure Enq(l: string) :=
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
    
    function Deq: string;
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
    
    function Enmr: sequence of string;
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
procedure Otp(line: string) :=
if ThrProcOtp.curr<>nil then
  ThrProcOtp.curr.Enq(line) else
lock otp_lock do
begin
  
  if log_file<>nil then
    while true do
    try
      if System.IO.File.Exists(log_file) then
        System.IO.File.Copy(log_file, log_file+'.savepoint');
      System.IO.File.AppendAllLines(log_file, Arr(line));
      System.IO.File.Delete(log_file+'.savepoint');
      break;
    except end;
  
  if timed_log_file<>nil then
    while true do
    try
      if System.IO.File.Exists(timed_log_file) then
        System.IO.File.Copy(timed_log_file, timed_log_file+'.savepoint');
      System.IO.File.AppendAllLines(timed_log_file, Arr(Format('{0:HH:mm:ss}', DateTime.Now)+$' | {line}'));
      System.IO.File.Delete(timed_log_file+'.savepoint');
      break;
    except end;
  
  if line.ToLower.Contains('error') then      System.Console.ForegroundColor := System.ConsoleColor.Red else
  if line.ToLower.Contains('exception') then  System.Console.ForegroundColor := System.ConsoleColor.Red else
  if line.ToLower.Contains('warning') then    System.Console.ForegroundColor := System.ConsoleColor.Yellow else
    System.Console.ForegroundColor := System.ConsoleColor.DarkGreen;
  
  System.Console.WriteLine(line);
end;

procedure ErrOtp(e: Exception);
begin
  if e is ThreadAbortException then exit;
  
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

{$endregion Otp}

{$region Process execution}

procedure RunFile(fname, nick: string; l_otp: string->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then raise new System.IO.FileNotFoundException(nil,fname);
  if l_otp=nil then l_otp := l->MiscUtils.Otp($'{nick}: {l}');
  
  MiscUtils.Otp($'Runing {nick}');
  
  var psi := new ProcessStartInfo(fname, pars.Append('"SecondaryProc"').JoinIntoString);
  fname := fname.Substring(fname.LastIndexOf('\')+1);
//  fname := fname.Remove(fname.LastIndexOf('.'));
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  
  var p := new Process;
  lock sec_procs do sec_procs += p;
  p.StartInfo := psi;
  
  var thr_otp := new ThrProcOtp;
  p.OutputDataReceived += (o,e) ->
  if e.Data=nil then
    thr_otp.Finish else
    thr_otp.Enq(e.Data);
  
  p.Start;
  
  try
    p.BeginOutputReadLine;
    
    foreach var l in thr_otp.Enmr do l_otp(l);
//    p.WaitForExit;
    if p.ExitCode<>0 then
    begin
      var ex := System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode);
      ErrOtp(new Exception($'Error in {nick}:', ex));
    end;
    
    MiscUtils.Otp($'Finished runing {nick}');
  except
    on ThreadAbortException do
    begin
      
      try
        p.Kill;
      except end;
      
    end;
  end;
end;

procedure CompilePasFile(fname: string; l_otp, err: string->());
begin
  fname := GetFullPath(fname);
  if l_otp=nil then l_otp := MiscUtils.Otp;
  if err=nil then err := s->raise new MessageException($'Error compiling "{fname}": {s}');
  
  l_otp($'Compiling "{fname}"');
  
  var psi := new ProcessStartInfo('C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe', $'"{fname}"');
  fname := fname.Substring(fname.LastIndexOf('\')+1);
//  fname := fname.Remove(fname.LastIndexOf('.'));
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.RedirectStandardInput := true;
  
  var p := new Process;
  p.StartInfo := psi;
  p.Start;
  p.StandardInput.WriteLine;
  p.WaitForExit;
  
  var res := p.StandardOutput.ReadToEnd.Remove(#13).Trim(#10' '.ToArray);
  if res.ToLower.Contains('error') then
    err(res) else
    l_otp($'Finished compiling "{fname}": {res}');
  
end;

procedure ExecuteFile(fname, nick: string; otp, err: string->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  var ffname := fname.Contains('\') ? fname.Substring(fname.LastIndexOf('\')+1) : fname;
  if ffname.Contains('.') then
    case ffname.Substring(ffname.LastIndexOf('.')) of
      
      '.pas':
      begin
        
        CompilePasFile(fname, otp, err);
        
        fname := fname.Remove(fname.Length-4)+'.exe';
        ffname := ffname.Remove(ffname.Length-4)+'.exe';
      end;
      
      '.exe': ;
      
      else raise new MessageException($'Unknown file extention: "{fname}"');
    end else
      raise new MessageException($'file without extention: "{fname}"');
  
  RunFile(fname, nick, otp, pars);
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
  lock sec_thrs do sec_thrs += Thread.CurrentThread;
  if in_err_state then Thread.CurrentThread.Abort;
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
      on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
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

function ProcTask(p: Action0) :=
new SecThrProcCustom(p);

function CompTask(fname: string) :=
new SecThrProcCustom(()->CompilePasFile(fname));

function ExecTask(fname, nick: string; params pars: array of string) :=
new SecThrProcCustom(()->ExecuteFile(fname, nick, pars));

{$endregion Task operations}

begin
  RegisterThr;
  while not System.Environment.CurrentDirectory.EndsWith('POCGL') do
    System.Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(System.Environment.CurrentDirectory);
end.