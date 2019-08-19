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
  
function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  if fname.Substring(1).StartsWith(':\') then
  begin
    Result := fname;
    exit;
  end;
  
  var path := base_folder;
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

procedure ErrOtp(e: Exception);
begin
  in_err_state := true;
  
  lock sec_thrs do
    foreach var thr in sec_thrs do
      if thr<>Thread.CurrentThread then
        thr.Abort;
  
  lock sec_procs do
    foreach var p in sec_procs do
      try
        p.Kill;
      except end;
  
  if e is MessageException then
    writeln(e.Message) else
    writeln(e);
  
  if not CommandLineArgs.Contains('SecondaryProc') then Readln;
  
  Halt(e.HResult);
end;

var otp_lock := new object;
procedure Otp(line: string) :=
lock otp_lock do writeln(line);

{$endregion Otp}

{$region Process execution}

procedure RunFile(fname, nick: string; otp: string->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  if otp=nil then otp := MiscUtils.Otp;
  
  otp($'Runing {nick}');
  
  var psi := new ProcessStartInfo(fname, pars.Append('"SecondaryProc"').JoinIntoString);
  fname := fname.Substring(fname.LastIndexOf('\')+1);
//  fname := fname.Remove(fname.LastIndexOf('.'));
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  
  var p := new Process;
  sec_procs += p;
  p.StartInfo := psi;
  p.OutputDataReceived += (o,e) -> if not string.IsNullOrWhiteSpace(e.Data) then otp($'{nick}: {e.Data}');
  p.Start;
  
  try
    p.BeginOutputReadLine;
    
    p.WaitForExit;
    if p.ExitCode<>0 then
    begin
      var ex := System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode);
      ErrOtp(new Exception($'Error in {nick}:', ex));
    end;
    
    otp($'Finished runing {nick}');
  except
    on ThreadAbortException do
    try
      p.Kill;
    except end;
  end;
end;

procedure CompilePasFile(fname: string; otp, err: string->());
begin
  fname := GetFullPath(fname);
  if otp=nil then otp := MiscUtils.Otp;
  if err=nil then err := s->ErrOtp(new MessageException($'Error compiling "{fname}": {s}'));
  
  otp($'Compiling "{fname}"');
  
  var psi := new ProcessStartInfo('C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe', $'"{fname}"');
  fname := fname.Substring(fname.LastIndexOf('\')+1);
//  fname := fname.Remove(fname.LastIndexOf('.'));
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  
  var p := new Process;
  p.StartInfo := psi;
  p.Start;
  p.WaitForExit;
  
  var res := p.StandardOutput.ReadToEnd.Remove(#13).Trim(#10' '.ToArray);
  if res.ToLower.Contains('error') then
    err(res) else
    otp($'Finished compiling "{fname}": {res}');
  
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
  sec_thrs += Thread.CurrentThread;
  if in_err_state then exit;
end;

type
  SecThrProc = abstract class
    function StartExec: Thread; abstract;
    procedure SyncExec :=
    StartExec.Join;
  end;
  
  SecThrProcCustom = sealed class(SecThrProc)
    p: Action0;
    constructor(p: Action0) := self.p := p;
    
    function StartExec: Thread; override := new Thread(()->
    try
      RegisterThr;
      p;
    except
      on e: Exception do ErrOtp(e);
    end);
    
  end;
  
  SecThrProcSum = sealed class(SecThrProc)
    p1,p2: SecThrProc;
    
    constructor(p1,p2: SecThrProc);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    function StartExec: Thread; override := new Thread(()->
    try
      RegisterThr;
      p1.SyncExec;
      p2.SyncExec;
    except
      on e: Exception do ErrOtp(e);
    end);
    
  end;
  
  SecThrProcMlt = sealed class(SecThrProc)
    p1,p2: SecThrProc;
    
    constructor(p1,p2: SecThrProc);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    function StartExec: Thread; override := new Thread(()->
    try
      RegisterThr;
      var t1 := p1.StartExec;
      var t2 := p2.StartExec;
      t1.Join;
      t2.Join;
    except
      on e: Exception do ErrOtp(e);
    end);
    
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