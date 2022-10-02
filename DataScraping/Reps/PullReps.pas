uses System.Diagnostics;

uses POCGL_Utils  in '..\..\POCGL_Utils';
uses AOtp         in '..\..\Utils\AOtp';
uses AQueue       in '..\..\Utils\AQueue';

const remote_official = '0_official';
const remote_own = 'SunSerega';

procedure PullRep(name, branch, nick: string);
begin
  Otp($'Pulling {nick}');
  var path := GetFullPathRTA(name);
  System.IO.Directory.CreateDirectory(path);
  
  var parts := new List<string>;
  if not FileExists(GetFullPath('.git', path)) then
  begin
    parts += $'echo [init] && git submodule update --init "." || cd .';
    parts += $'echo [rename origin] && git remote rename "origin" "{remote_official}" || cd .';
    parts += $'echo [remove origin push] && git remote set-url --push "{remote_official}" NO_PUSH_URL';
    parts += $'echo [add own remote] && git remote add --fetch -t {branch} "{remote_own}" "git@github.com:{remote_own}/{name}.git" || cd .';
  end;
  parts += $'echo [checkout] && git checkout {branch}';
  parts += $'echo [pull] && git pull {remote_official} {branch} || echo pull own: && git pull {remote_own} {branch}';
  parts += $'echo [push] && git push {remote_own} {branch}';
  
  var psi := new ProcessStartInfo('cmd', '/c "(' + parts.JoinToString(') && (') + ')"');
  psi.FileName.Print; psi.Arguments.Println;
  psi.WorkingDirectory := path;
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardOutput := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  p.OutputDataReceived += (o,e)->if e.Data=nil then              else p_otp.Enq( $'{nick}[OUT] : {e.Data.Trim(#32)}'                );
  p.ErrorDataReceived  += (o,e)->if e.Data=nil then p_otp.Finish else p_otp.Enq( $'{nick}[ERR] : {e.Data.Trim(|''='',#32|)}' );
  
  p.Start;
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp do Otp(l);
  Otp($'Done pulling {nick}');
end;

begin
  try
    Seq(
      new class( nick := 'OpenCL', name := 'OpenCL-Docs',     branch := 'main' ),
      new class( nick := 'OpenGL', name := 'OpenGL-Registry', branch := 'custom' )
    ).ForEach(r->PullRep(r.name, r.branch, r.nick));
  except
    on e: Exception do ErrOtp(e);
  end;
end.