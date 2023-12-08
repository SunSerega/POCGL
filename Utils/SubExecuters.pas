unit SubExecuters;

uses System.Diagnostics;

uses AOtp;
uses CLArgs;
uses PathUtils;
uses Timers;

uses AQueue; //TODO #2543

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
  
  CompHelper = static class
    
    private static pas_comp_path := default(string);
    
    public static function SetPasCompPath(path: string): boolean;
    begin
      Result := false;
      if not FileExists(path) then
      begin
        Otp($'WARNING: PasCompPath "{path}" did not refer to a file');
        exit;
      end;
      path := System.IO.Path.GetFullPath(path);
//      Otp($'PasCompPath is set to "{path}"', true);
      if pas_comp_path<>nil then
        raise new System.InvalidOperationException($'Path already set to: {pas_comp_path}');
      pas_comp_path := path;
      Result := true;
    end;
    
    private static pas_comp_path_lock := new object;
    public static function PasCompPath: string;
    begin
      lock pas_comp_path_lock do
      begin
        if pas_comp_path=nil then
        begin
          foreach var path in GetArgs('PasCompPath') do
            if SetPasCompPath(path) then
              break;
          if pas_comp_path=nil then
          begin
            var path := 'C:\Program Files (x86)\PascalABC.NET\pabcnetcclear.exe';
            if FileExists(path) then
              pas_comp_path := path;
          end;
        end;
        if pas_comp_path=nil then
          raise new System.NotImplementedException($'No Pascal compiler found');
      end;
      
      Result := pas_comp_path;
    end;
    
    public static function SubProcessArgs: sequence of string;
    begin
      try
        var path := PasCompPath;
        Result := |$'"PasCompPath={path}"'|;
      except
        Result := System.Array.Empty&<string>;
      end;
    end;
    
  end;
  
function GetUsedModules(fname: string; prev: array of string): sequence of string;
const savepcu_d = '{'+'$savepcu false}';
begin
  if fname in prev then exit;
  prev := prev+|fname|;
  
  var text := ReadAllText(fname, FileLogger.enc);
  if savepcu_d not in text then
    yield fname;
  
  var dir := System.IO.Path.GetDirectoryName(fname);
  foreach var uses_m in text.Matches('(?<!(//|'').*)(?<!\w)uses\s([^;]*);') do
  begin
    var uses_s := uses_m.Groups[2].Value.Trim;
//    Console.WriteLine($'<{prev.JoinToString('';'')}> Looking at file [{fname}]: "{uses_m}" ({uses_s})');
    foreach var unit_m in uses_s.Matches('(?:\w+\s+in\s+)?''([^'']+)''|([\w\.]+)') do
    begin
      var unit_s := unit_m.Groups[1].Value+unit_m.Groups[2].Value;
      unit_s := unit_s.Trim;
//      Console.WriteLine($'Looking at uses [{uses_s}]: "{unit_m}" ({unit_s})');
      var uu_fname := GetFullPath(System.IO.Path.ChangeExtension(unit_s, '.pas'), dir);
      if not FileExists(uu_fname) then
      begin
        if unit_s.Split('.').First = 'System' then
          continue;
        if unit_s in |
          'OpenGL','OpenCL',
          'OpenGLABC','OpenCLABC',
          'GraphWPF'
        | then continue;
        Otp($'WARNING: Compiling "{fname}", used unit "{uu_fname}" ({unit_s}) in ({uses_m}) not found');
        continue;
      end;
      yield sequence GetUsedModules(uu_fname, prev);
    end;
  end;
  
end;
function GetUsedModules(fname: string) := GetUsedModules(fname, System.Array.Empty&<string>);

{$endregion Helpers}

{$region Core}

type SubexecReadCanceledException = sealed class(Exception) end;
procedure RunFile(fname, nick: string; on_timer: Timer->(); l_otp: OtpLine->(); l_err: Exception->(); params pars: array of string);
// Если менять - то в SubExecutables тоже
const OutputPipeIdStr = 'OutputPipeId';
begin
  nick := nick?.Replace('error', 'errоr');
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then raise new System.IO.FileNotFoundException(nil,fname);
  
  if (on_timer=nil) and (nick<>nil) then
    on_timer := t->ExeTimer.Executions.Add(nick, GetRelativePathRTA(fname), LoadedTimer(t));
  
  if nick<>nil then AOtp.Otp($'Runing {nick}');
  if l_otp=nil then l_otp := l->
  begin
    if nick<>nil then l := l.ConvStr(s->nick+': '+s.Replace(#9, ' '*8));
    AOtp.Otp(l);
  end;
  if l_err=nil then l_err := e->
  AOtp.ErrOtp(new MessageException($'Error in {nick??fname}: {e}'));
  
  var p := new Process;
  var pek := if nick=nil then nil else new SubProcessEmergencyKiller(p);
  
  var pipe := if nick=nil then nil else new System.IO.Pipes.AnonymousPipeServerStream(System.IO.Pipes.PipeDirection.In, System.IO.HandleInheritability.Inheritable);
  if pek<>nil then pek.halt_str := new System.IO.Pipes.AnonymousPipeServerStream(System.IO.Pipes.PipeDirection.Out, System.IO.HandleInheritability.Inheritable);
  
  var all_pars := pars.AsEnumerable;
  if nick<>nil then
  begin
    all_pars := all_pars
      + $'"{OutputPipeIdStr}={pipe.GetClientHandleAsString} {pek.halt_str.GetClientHandleAsString}"'
      + CompHelper.SubProcessArgs
    ;
  end;
  
  var psi := new ProcessStartInfo(fname, all_pars.JoinToString);
  psi.UseShellExecute := false;
  psi.RedirectStandardOutput := true;
  psi.WorkingDirectory := System.IO.Path.GetDirectoryName(fname);
  p.StartInfo := psi;
  
  {$region otp capture}
  var start_time_mark: int64;
  var pipe_connection_established := default(boolean?);
  
  var thr_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  p.OutputDataReceived += (o,e)->
  try
    if e.Data=nil then
    begin
      // Only .Finish here, in case output after pipe is closed
//      if pipe_connection_established<>true then
      thr_otp.Finish;
    end else
      thr_otp.Enq(e.Data);
  except
    on exc: Exception do ErrOtp(exc);
  end;
  
  if nick<>nil then StartBgThread(()->
  try
    var br := new System.IO.BinaryReader(pipe);
    
    on_timer(new LoadedTimer(()->
    try
      if br.ReadByte <> 0 then raise new System.InvalidOperationException($'Output of {nick} didn''t start from 0');
      
      //TODO разобраться на сколько это надо и куда сувать
      // - update: таки без него не видит завершение вывода при умирании процесса
      pipe.DisposeLocalCopyOfClientHandle;
      pek.halt_str.DisposeLocalCopyOfClientHandle;
      
      pipe_connection_established := true;
      pek.use_halt_str := true;
      
      while true do
      begin
        var otp_type := br.ReadInt32;
        
        case otp_type of
          
          1: thr_otp.Enq(OtpLine.Load(br, start_time_mark));
          
          2:
          begin
            // .Finish in OutputDataReceived, in case error comes there after pipe closing
//            thr_otp.Finish;
            Result := br;
            break;
          end;
          
          else raise new MessageException($'ERROR: Invalid bin otp type: [{otp_type}]');
        end;
        
      end;
      
    except
      on e: System.IO.EndOfStreamException do
      begin
        if pipe_connection_established=true then
          Otp($'WARNING: Pipe reading for {nick} ended unexpectedly') else
          Otp($'WARNING: Pipe connection for {nick} wasn''t established');
        raise new SubexecReadCanceledException;
      end;
    end));
    
  except
    on SubexecReadCanceledException do ;
    on e: Exception do
    begin
      if pipe_connection_established=nil then
        pipe_connection_established := false;
      ErrOtp(e);
    end;
  end);
  
  {$endregion otp capture}
  
  var exec_proc := procedure->
  begin
    start_time_mark := OtpLine.TotalTime.Ticks;
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
      
      if p.ExitCode<>0 then l_err(System.Runtime.InteropServices.Marshal.GetExceptionForHR(p.ExitCode));
      if nick<>nil then AOtp.Otp($'Finished runing {nick}');
    finally
      try
        p.Kill;
      except
      end;
      if pek<>nil then
        lock EmergencyHandler.All do
          EmergencyHandler.All.Remove(pek);
    end;
    
  end;
  if nick<>nil then
    exec_proc else
    on_timer(new SimpleTimer(exec_proc));
  
  if (pipe<>nil) and (pipe_connection_established<>true) then pipe.Close;
end;

var unit_locking_lock := new object;
procedure CompilePasFile(fname: string; on_timer: SimpleTimer->(); l_otp: OtpLine->(); err: string->(); kind: OtpKind; args: string; params search_paths: array of string);
begin
  fname := GetFullPath(fname);
  if not System.IO.File.Exists(fname) then
    raise new System.IO.FileNotFoundException($'File "{GetRelativePath(fname)}" not found');
  
  var nick := System.IO.Path.GetFileNameWithoutExtension(fname).Replace('error', 'errоr');
  if on_timer=nil then
    on_timer := t->ExeTimer.Compilations.Add(nick, GetRelativePathRTA(fname), t);
  
  foreach var p in Process.GetProcessesByName(nick) do
  begin
    Otp($'WARNING: Killed runing process [{nick}] to be able to compile .pas file');
    p.Kill;
  end;
  
  if l_otp=nil then l_otp := AOtp.Otp;
  if err=nil then err := s->raise new MessageException($'Error compiling "{GetRelativePath(fname)}": {s}');
  
  l_otp(new OtpLine($'Compiling "{GetRelativePath(fname)}"', kind));
  
  var locks := new List<System.IO.FileStream>;
  lock unit_locking_lock do
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
    
//    foreach var used_fname in lock_names do
//      Otp($'Locked [{used_fname}]', new OtpKind('console only'));
  end;
  
  var args_strs := search_paths.Select(spath->$'/SearchDir:"{spath}"').Append('/Locale:en');
  if args<>nil then args_strs := args_strs.Append(args);
  args_strs := args_strs.Append($'"{fname}"');
  var psi := new ProcessStartInfo(
    CompHelper.PasCompPath,
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
  p.OutputDataReceived += (o,e)->
    if e.Data=nil then
      p_otp.Finish else
    begin
      p_otp.Enq(new OtpLine($'Compiling: {e.Data}', kind));
      res_sb.AppendLine(e.Data);
    end;
  
  on_timer(new SimpleTimer(()->
  begin
    p.Start;
    p.BeginOutputReadLine;
    foreach var l in p_otp do l_otp(l);
    p.WaitForExit;
  end));
  
  foreach var l in locks do
    l.Close;
  
  var res := res_sb.ToString.Remove(#13).Trim(#10' '.ToArray);
  if 'error' in res.ToLower then
    err(res);
  
end;

procedure ExecuteFile(fname, nick: string; l_otp: OtpLine->(); params pars: array of string);
begin
  fname := GetFullPath(fname);
  
  case System.IO.Path.GetExtension(fname) of
    
    '.pas':
    begin
      CompilePasFile(fname, nil, l_otp, nil, OtpKind.Empty, nil);
      fname := System.IO.Path.ChangeExtension(fname, '.exe');
    end;
    
    '.exe': ;
    
    else raise new MessageException($'ERROR: Not supported file extention: "{fname}"');
  end;
  
  RunFile(fname, nick, nil, l_otp, nil, pars);
end;

{$endregion Core}

{$region Additional overloads}

procedure RunFile(fname, nick: string; params pars: array of string) :=
  RunFile(fname, nick, nil, nil, nil, pars);

procedure CompilePasFile(fname: string; kind: OtpKind; args: string := nil) :=
  CompilePasFile(fname, nil, nil, nil, kind, args);

procedure ExecuteFile(fname, nick: string; params pars: array of string) :=
  ExecuteFile(fname, nick, nil, pars);

{$endregion Additional overloads}

end.