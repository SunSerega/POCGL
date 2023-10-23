unit Testing;

//TODO #2897
{$savepcu false}

uses System.Diagnostics;

uses '../PathUtils';

type
  FatalTestingException = sealed class(Exception) end;
  
  ExecutingTest = sealed class
    private arg_executable: string;
    private arg_max_exec_time: integer;
    private arg_pause_when_loaded: boolean;
    
    private executor: string;
    private p: Process;
    private paused: boolean;
    
    public constructor(executable: string; max_exec_time: integer; pause_when_loaded: boolean);
    begin
      if System.IO.Path.GetExtension(executable) <> '.exe' then raise new System.NotSupportedException(executable);
      executable := GetFullPath(executable);
      
      self.arg_executable         := executable;
      self.arg_max_exec_time      := max_exec_time;
      self.arg_pause_when_loaded  := pause_when_loaded;
      
      {$resource TestExecutor.exe}
      executor := System.IO.Path.ChangeExtension(executable, '.Executor.exe');
      if not FileExists(executor) then
      begin
        var executor_f := System.IO.File.Create(executor);
        GetResourceStream('TestExecutor.exe').CopyTo(executor_f);
        executor_f.Close;
      end;
      
      var args := new List<string>;
      args += $'MaxExecTime={max_exec_time}';
      if pause_when_loaded then
        args += 'PauseWhenLoaded';
      
      self.p := new Process;
      self.paused := pause_when_loaded;
      p.StartInfo.CreateNoWindow := true;
      p.StartInfo.FileName := executor;
      p.StartInfo.Arguments := args.JoinToString;
      p.StartInfo.WorkingDirectory := System.IO.Path.GetDirectoryName(executable);
      p.StartInfo.UseShellExecute := false;
      p.StartInfo.RedirectStandardInput := true;
      p.StartInfo.RedirectStandardOutput := true;
      p.StartInfo.RedirectStandardError := true;
      p.Start;
    end;
    
    public constructor(test_to_repeat: ExecutingTest) := Create(
      test_to_repeat.arg_executable,
      test_to_repeat.arg_max_exec_time,
      test_to_repeat.arg_pause_when_loaded
    );
    
    public function FinishExecution: (string, string);
    begin
      if paused then p.StandardInput.WriteLine;
      var t_otp := p.StandardOutput.ReadToEndAsync;
      var t_err := p.StandardError.ReadToEndAsync;
      var otp := t_otp.Result.Remove(#13).Trim(#10);
      var err := t_err.Result.Remove(#13).Trim(#10).Split(|#10|,2);
      p.WaitForExit;
      DeleteFile(executor);
      case err[0] of
        
        '', '%ExecutionException%':
        Result := (otp, err.Last);
        
        else raise new FatalTestingException(err.Last);
      end;
    end;
    
  end;
  
function ExecTest(executable: string; time: integer): (string, string);
begin
  var t := new ExecutingTest(executable, time, false);
  Result := t.FinishExecution;
end;

end.