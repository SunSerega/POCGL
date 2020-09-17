unit SubExecuters;

uses System.Diagnostics;

uses AOtp;
uses AQueue; //ToDo #2307
uses PathUtils;
uses Timers;

type
  SubProcessEmergencyKiller = sealed class(EmergencyHandler)
    private p: Process;
    private use_halt_str := false;
    private halt_str: System.IO.Pipes.AnonymousPipeServerStream;
    
    public constructor(p: Process) :=
    self.p := p;
    
    public procedure Handle; override;
    begin
      if p.HasExited then exit;
      
      if not use_halt_str then
      begin
        p.Kill;
        exit;
      end;
      
      try
        halt_str.WriteByte(1);
      except
        on e: System.IO.IOException do
        begin
          Otp($'WARNING: Failed to use halt stream of process [{GetRelativePath(p.MainModule.FileName)}]:{#10}{e}');
          try
            p.Kill;
          except
          end;
          exit;
        end;
      end;
      
      if not p.WaitForExit(100) then p.Kill;
    end;
    
  end;
  
procedure RunFile(fname, nick: string; l_otp: OtpLine->(); params pars: array of string);
// Если менять - то в SubExecutables тоже
const OutputPipeIdStr = 'OutputPipeId';
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then raise new System.IO.FileNotFoundException(nil,fname);
  
  AOtp.Otp($'Runing {nick}');
  if l_otp=nil then l_otp := l->AOtp.Otp(l.ConvStr(s->$'{nick}: {s}'));
  
  var p := new Process;
  var pek := new SubProcessEmergencyKiller(p);
  
  var pipe := new System.IO.Pipes.AnonymousPipeServerStream(System.IO.Pipes.PipeDirection.In, System.IO.HandleInheritability.Inheritable);
  pek.halt_str := new System.IO.Pipes.AnonymousPipeServerStream(System.IO.Pipes.PipeDirection.Out, System.IO.HandleInheritability.Inheritable);
  
  var psi := new ProcessStartInfo(fname, pars.Append($'"{OutputPipeIdStr}={pipe.GetClientHandleAsString} {pek.halt_str.GetClientHandleAsString}"').JoinToString);
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.WorkingDirectory := System.IO.Path.GetDirectoryName(fname);
  p.StartInfo := psi;
  
  var curr_timer: ContainerBaseTimer := Timer.main.exe_exec[nick];
  
  {$region otp capture}
  var start_time_mark: int64;
  var pipe_connection_established := false;
  
  var thr_otp := new AsyncProcOtp(AsyncProcOtp.curr);
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
      if br.ReadByte <> 0 then raise new System.InvalidOperationException($'Output of {nick} didn''t start from 0');
      
      //ToDo разобраться на сколько это надо и куда сувать
      // - update: таки без него не видит завершение вывода при умирании процесса
      pipe.DisposeLocalCopyOfClientHandle;
      pek.halt_str.DisposeLocalCopyOfClientHandle;
      
      pipe_connection_established := true;
      pek.use_halt_str := true;
      
      while true do
      begin
        var otp_type := br.ReadInt32;
        
        case otp_type of
          
          1:
          thr_otp.Enq(new OtpLine(
            br.ReadString,
            start_time_mark + br.ReadInt64
          ));
          
          2:
          begin
            thr_otp.Finish;
            curr_timer.Load(br);
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
      //ToDo #2306
      foreach var l in thr_otp as IEnumerable<OtpLine> do l_otp(l);
      p.WaitForExit;
      
      if p.ExitCode<>0 then
      begin
        var ex := System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode);
        ErrOtp(new MessageException($'Error in {nick}: {ex}'));
      end;
      
      AOtp.Otp($'Finished runing {nick}');
    finally
      try
        p.Kill;
      except
      end;
      lock EmergencyHandler.All do
        EmergencyHandler.All.Remove(pek);
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
  
  if l_otp=nil then l_otp := AOtp.Otp;
  if err=nil then err := s->raise new MessageException($'Error compiling "{GetRelativePath(fname)}": {s}');
  
  l_otp($'Compiling "{GetRelativePath(fname)}"');
  
  var psi := new ProcessStartInfo(
    'C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe',
    search_paths.Select(spath->$'/SearchDir:"{spath}"').Append($'"{fname}"').JoinToString
  );
//  Otp(psi.Arguments);
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

procedure ExecuteFile(fname, nick: string; l_otp: OtpLine->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  case System.IO.Path.GetExtension(fname) of
    
    '.pas':
    begin
      CompilePasFile(fname, l_otp, nil);
      fname := System.IO.Path.ChangeExtension(fname, '.exe');
    end;
    
    '.exe': ;
    
    else raise new MessageException($'ERROR: Not supported file extention: "{fname}"');
  end;
  
  RunFile(fname, nick, l_otp, pars);
end;



procedure RunFile(fname, nick: string; params pars: array of string) :=
RunFile(fname, nick, nil, pars);

procedure CompilePasFile(fname: string) :=
CompilePasFile(fname, nil, nil);

procedure ExecuteFile(fname, nick: string; params pars: array of string) :=
ExecuteFile(fname, nick, nil, pars);

end.