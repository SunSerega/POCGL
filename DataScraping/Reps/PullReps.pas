uses System.Diagnostics;
uses POCGL_Utils in '..\..\POCGL_Utils';
uses AOtp         in '..\..\Utils\AOtp';
uses ATask        in '..\..\Utils\ATask';

procedure PullRep(name, nick: string);
begin
  Otp($'Pulling {nick}');
  
  var psi := new ProcessStartInfo('git', $'submodule update --progress --remote --init -- "{GetFullPathRTA(name)}"');
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardOutput := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  p.OutputDataReceived += (o,e)->if e.Data=nil then p_otp.Finish else p_otp.Enq( $'{nick} : {e.Data.Trim(#32)}' );
  p.ErrorDataReceived += (o,e)->if e.Data<>nil then                   p_otp.Enq( $'{nick} : [Info] {e.Data.Trim(''= ''.ToCharArray())}' );
  
  p.Start;
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp do Otp(l);
  Otp($'Done pulling {nick}');
end;

begin
  try
    Arr(
      new class( nick := 'OpenCL Docs',     name := 'OpenCL-Docs'     ),
      new class( nick := 'OpenGL Registry', name := 'OpenGL-Registry' )
    ).Select(r->ProcTask(()-> PullRep(r.name, r.nick) ))
    .CombineAsyncTask
    .SyncExec;
  except
    on e: Exception do ErrOtp(e);
  end;
end.