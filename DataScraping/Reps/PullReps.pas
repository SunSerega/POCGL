uses System.Diagnostics;
uses POCGL_Utils  in '..\..\POCGL_Utils';
uses AOtp         in '..\..\Utils\AOtp';
uses AQueue       in '..\..\Utils\AQueue';

procedure Init;
begin
  Otp($'Init');
  
  var psi := new ProcessStartInfo('git', 'submodule update --init');
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardOutput := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  p.OutputDataReceived += (o,e)->if e.Data=nil then p_otp.Finish else p_otp.Enq( $'Init : {e.Data.Trim(#32)}'                );
  p.ErrorDataReceived  += (o,e)->if e.Data=nil then              else p_otp.Enq( $'Init : [Info] {e.Data.Trim(|''='',#32|)}' );
  
  p.Start;
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp do Otp(l);
  Otp($'Done init');
end;

procedure PullRep(name, branch, nick: string);
begin
  Otp($'Pulling {nick}');
  
  var path := GetFullPathRTA(name);
  var psi := new ProcessStartInfo('cmd', $'/c "echo checkout: && git checkout {branch} && (echo pull: && git pull 0_official {branch} & echo push: && git push SunSerega {branch})"');
  psi.WorkingDirectory := path;
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardOutput := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  p.OutputDataReceived += (o,e)->if e.Data=nil then p_otp.Finish else p_otp.Enq( $'{nick} : {e.Data.Trim(#32)}'                );
  p.ErrorDataReceived  += (o,e)->if e.Data=nil then              else p_otp.Enq( $'{nick} : [Info] {e.Data.Trim(|''='',#32|)}' );
  
  p.Start;
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp do Otp(l);
  Otp($'Done pulling {nick}');
end;

begin
  try
    Init;
    Arr(
      new class( nick := 'OpenCL Docs',     name := 'OpenCL-Docs',     branch := 'main' ),
      new class( nick := 'OpenGL Registry', name := 'OpenGL-Registry', branch := 'unused-groups' )
    ).ForEach(r->PullRep(r.name, r.branch, r.nick));
  except
    on e: Exception do ErrOtp(e);
  end;
end.