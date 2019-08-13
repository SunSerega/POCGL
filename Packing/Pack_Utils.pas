﻿unit Pack_Utils;
uses System.Diagnostics;
uses System.Threading.Tasks;

var sec_procs := new List<Process>;

type
  PackException = class(Exception)
    constructor(text: string) :=
    inherited Create(text);
  end;
  
procedure ErrOtp(e: Exception);
begin
  foreach var p in sec_procs do
    try
      p.Kill;
    except end;
  
  if e is PackException then
    writeln(e.Message) else
    writeln(e);
  
  if not CommandLineArgs.Contains('SecondaryProc') then readln;
  
  Halt(e.HResult);
end;

var otp_lock := new object;
procedure Otp(line: string) :=
lock otp_lock do writeln(line);

function GetFullPath(fname: string): string;
begin
  if fname.Substring(1).StartsWith(':\') then
  begin
    Result := fname;
    exit;
  end;
  
  var path := System.Environment.CurrentDirectory;
  if path.EndsWith('\') then path := path.Remove(path.Length-1);
  path += '\Packing';
  
  while fname.StartsWith('..\') do
  begin
    fname := fname.Substring(3);
    path := System.IO.Path.GetDirectoryName(path);
  end;
  if fname.StartsWith('\') then fname := fname.Substring(1);
  
  Result := $'{path}\{fname}';
end;

procedure RunFile(fname: string; params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  var psi := new ProcessStartInfo(fname, pars.Append('"SecondaryProc"').JoinIntoString);
  fname := fname.Substring(fname.LastIndexOf('\')+1);
//  fname := fname.Remove(fname.LastIndexOf('.'));
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  
  var p := new Process;
  sec_procs += p;
  p.StartInfo := psi;
  p.OutputDataReceived += (o,e)->Otp($'{fname}: {e.Data}');
  p.Start;
  
  p.WaitForExit;
  if p.ExitCode<>0 then
  begin
    Otp($'Error runing {fname}{#10}{#10}{p.StandardOutput.ReadToEnd}');
    ErrOtp(System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode));
  end;
  
end;

procedure CompilePasFile(fname: string);
begin
  fname := GetFullPath(fname);
  
  var psi := new ProcessStartInfo('C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe', $'"{fname}"');
  fname := fname.Substring(fname.LastIndexOf('\')+1);
//  fname := fname.Remove(fname.LastIndexOf('.'));
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  
  var p := new Process;
  p.StartInfo := psi;
  p.Start;
  p.WaitForExit;
  
  var res := p.StandardOutput.ReadToEnd;
  if res.ToLower.Contains('error') then
    ErrOtp(new PackException(res)) else
    Otp($'Compiling "{fname}": {res}');
  
end;

procedure ExecuteFile(fname: string; params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  var ffname := fname.Contains('\') ? fname.Substring(fname.LastIndexOf('\')+1) : fname;
  if ffname.Contains('.') then
    case ffname.Substring(ffname.LastIndexOf('.')) of
      
      '.pas':
      begin
        
        CompilePasFile(fname);
        
        fname := fname.Remove(fname.Length-4)+'.exe';
        ffname := ffname.Remove(ffname.Length-4)+'.exe';
      end;
      
      '.exe': ;
      
      else raise new PackException($'Unknown file extention: "{fname}"');
    end else
      raise new PackException($'file without extention: "{fname}"');
  
  RunFile(fname, pars);
end;



function operator+(t1,t2: Task): Task; extensionmethod :=
new Task(()->
begin
  t1.RunSynchronously;
  t2.RunSynchronously;
end);

function operator*(t1,t2: Task): Task; extensionmethod :=
new Task(()->
begin
  t1.Start;
  t2.Start;
  t1.Wait;
  t2.Wait;
end);

function CompTask(fname: string) :=
new Task(()->
try
  CompilePasFile(fname);
except
  on e: Exception do ErrOtp(e);
end);

function ExecTask(fname: string; params pars: array of string) :=
new Task(()->
try
  ExecuteFile(fname, pars);
except
  on e: Exception do ErrOtp(e);
end);

end.