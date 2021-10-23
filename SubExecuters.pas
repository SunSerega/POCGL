unit SubExecuters;

uses System.Diagnostics;

uses AOtp;
uses PathUtils;
uses Timers;

{$region Helpers}

type
  SubProcessEmergencyKiller = sealed class(EmergencyHandler)
    private p: Process;
    private use_halt_str := false;
    private halt_str: System.IO.Pipes.AnonymousPipeServerStream;
    
    public constructor(p: Process) :=
    self.p := p;
    
    public procedure Handle; override;
    begin
      try
        if p.HasExited then exit;
      except
        // Если процесс ещё даже запустится не успел
        on System.InvalidOperationException do exit;
      end;
      
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
  
function GetUsedModules(fname: string; prev: array of string): sequence of string;
const uses_str = 'uses';
const in_str = 'in';
begin
  fname := System.IO.Path.ChangeExtension(fname, '.pas');
  if not FileExists(fname) then exit;
  
  
  if fname in prev then exit;
  prev := prev+|fname|;
  
  var text := ReadAllText(fname, enc);
  if not text.Contains('{savepcu false}') then
    yield fname;
  
  var dir := System.IO.Path.GetDirectoryName(fname);
  var ind := 0;
  while true do
  begin
    ind := text.IndexOf(uses_str, ind);
    if ind=-1 then break;
    ind += uses_str.Length;
    
    var ind2 := text.IndexOf(';', ind);
    if ind2=-1 then raise new System.FormatException(fname);
    
    foreach var u_str in text.Substring(ind, ind2-ind).Split(',') do
      yield sequence GetUsedModules(GetFullPath(
        if u_str.Contains(in_str) then
          u_str.Split(|in_str|, 2, System.StringSplitOptions.None)[1].Trim(''' '.ToCharArray) else
          u_str.Trim
      ,
        dir
      ), prev);
  end;
end;
function GetUsedModules(fname: string) := GetUsedModules(fname, new string[0]);
var GetUsedModules_lock := new object;

{$endregion Helpers}

{$region Core}

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
            start_time_mark + br.ReadInt64,
            br.ReadBoolean
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
      foreach var l in thr_otp do l_otp(l);
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

procedure CompilePasFile(fname: string; l_otp: OtpLine->(); err: string->(); general_task: boolean; args: string; params search_paths: array of string);
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then
    raise new System.IO.FileNotFoundException($'File "{GetRelativePath(fname)}" not found');
  
  var nick := System.IO.Path.GetFileNameWithoutExtension(fname);
  
  foreach var p in Process.GetProcessesByName(nick) do
  begin
    Otp($'WARNING: Killed runing process [{nick}] to be able to compile .pas file');
    p.Kill;
  end;
  
  if l_otp=nil then l_otp := AOtp.Otp;
  if err=nil then err := s->raise new MessageException($'Error compiling "{GetRelativePath(fname)}": {s}');
  
  var locks := new List<System.IO.FileStream>;
  lock GetUsedModules_lock do
  begin
    var lock_names := GetUsedModules(fname).Distinct.Select(u_name->u_name+'.compile_lock').ToList;
    
    while true do
    try
      foreach var used_fname in lock_names do
        locks += System.IO.File.Create(used_fname, 1, System.IO.FileOptions.DeleteOnClose);
      break;
    except
      on e: System.IO.IOException do
      begin
        foreach var l in locks do
          l.Close;
        locks.Clear;
        Sleep(100);
        continue;
      end;
    end;
    
  end;
  
  l_otp(new OtpLine($'Compiling "{GetRelativePath(fname)}"', general_task));
  
  var args_strs := search_paths.Select(spath->$'/SearchDir:"{spath}"');
  if args<>nil then args_strs := args_strs.Append(args);
  args_strs := args_strs.Append($'"{fname}"');
  var psi := new ProcessStartInfo(
    'C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe',
    args_strs.JoinToString
  );
//  Otp(psi.Arguments);
  psi.UseShellExecute := false;
  psi.CreateNoWindow := true;
  psi.RedirectStandardOutput := true;
  
  var p := new Process;
  p.StartInfo := psi;
  
  var res_sb := new StringBuilder;
  var p_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  Timer.main.pas_comp[nick].MeasureTime(()->
  begin
    p.OutputDataReceived += (o,e)->
      if e.Data=nil then
        p_otp.Finish else
      begin
        p_otp.Enq(new OtpLine($'Compiling: {e.Data}', general_task));
        res_sb.AppendLine(e.Data);
      end;
    p.Start;
    p.BeginOutputReadLine;
    foreach var l in p_otp do l_otp(l);
    p.WaitForExit;
  end);
  
  foreach var l in locks do
    l.Close;
  
  var res := res_sb.ToString.Remove(#13).Trim(#10' '.ToArray);
  if res.ToLower.Contains('error') then
    err(res);
  
end;

procedure ExecuteFile(fname, nick: string; l_otp: OtpLine->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  case System.IO.Path.GetExtension(fname) of
    
    '.pas':
    begin
      CompilePasFile(fname, l_otp, nil, false, nil);
      fname := System.IO.Path.ChangeExtension(fname, '.exe');
    end;
    
    '.exe': ;
    
    else raise new MessageException($'ERROR: Not supported file extention: "{fname}"');
  end;
  
  RunFile(fname, nick, l_otp, pars);
end;

{$endregion Core}

{$region Additional overloads}

procedure RunFile(fname, nick: string; params pars: array of string) :=
RunFile(fname, nick, nil, pars);

procedure CompilePasFile(fname: string; general_task: boolean; args: string := nil) :=
CompilePasFile(fname, nil, nil, general_task, args);

procedure ExecuteFile(fname, nick: string; params pars: array of string) :=
ExecuteFile(fname, nick, nil, pars);

{$endregion Additional overloads}

end.