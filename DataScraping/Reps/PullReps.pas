uses System.Diagnostics;

uses '../../Utils/AOtp';
uses '../../Utils/AQueue';
uses '../../Utils/CLArgs';

uses '../../POCGL_Utils';

const remote_official = '0_official';
const remote_own = 'SunSerega';

var branch_per_repo := new Dictionary<string, string>;

procedure ExecCommands(path, nick: string; kinds: array of string; params commands: array of string);
begin
  var otp_kind := new OtpKind(kinds??System.Array.Empty&<string>);
  
  var psi := new ProcessStartInfo('cmd', '/c "(' + commands.JoinToString(') && (') + ')"');
  Otp($'{psi.FileName} {psi.Arguments}', otp_kind);
  psi.WorkingDirectory := path;
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardOutput := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new AsyncProcOtp(AsyncProcOtp.curr);
  p.OutputDataReceived += (o,e)->if e.Data=nil then              else p_otp.Enq(new OtpLine( $'{nick}[OUT] : {e.Data.Trim(#32)}'        , otp_kind));
  p.ErrorDataReceived  += (o,e)->if e.Data=nil then p_otp.Finish else p_otp.Enq(new OtpLine( $'{nick}[ERR] : {e.Data.Trim(|''='',#32|)}', otp_kind));
  
  p.Start;
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp do
    Otp(l.ConvStr(s->s
      .Replace('github.com:','')
      .Replace('https://github.com/','')
      .RegexReplace('\s+', ' ')
    ));
  
  if p.ExitCode<>0 then
    Halt(p.ExitCode);
end;

procedure PullRep(name, branch, nick: string);
begin
  Otp($'Pulling {nick}');
  var path := GetFullPathRTA(name);
  System.IO.Directory.CreateDirectory(path);
  
  if branch_per_repo.Get(name) is string(var branch_override) then
  begin
    Otp($'Branch override: {branch} => {branch_override}', 'console only');
    branch := branch_override;
  end;
  
  if not FileExists(GetFullPath('.git', path)) then
    ExecCommands(path, nick+'+init', |'console only'|
      , $'echo [init] && git submodule update --init "." || cd .'
      , $'echo [rename origin] && git remote rename "origin" "{remote_official}" || cd .'
      , $'echo [remove origin push] && git remote set-url --push "{remote_official}" NO_PUSH_URL'
      , $'echo [add own remote] && git remote add --fetch -t {branch} "{remote_own}" "git@github.com:{remote_own}/{name}.git" || cd .'
      , $'echo [checkout] && git checkout -B {branch} {remote_own}/{branch} 2>&1'
    );
  
  ExecCommands(path, nick, nil
    , $'echo [checkout] && git checkout {branch} 2>&1'
    , $'echo [pull-own]: && git pull {remote_own} {branch}'
    , $'echo [fetch-main] && git fetch {remote_official} main:main'
    , $'echo [merge-main] && git merge main'
  );
  
  ExecCommands(path, nick, |'console only'|
    , $'echo [push main] && git push {remote_own} main || cd .'
    , $'echo [push {branch}] && git push {remote_own} {branch} || cd .'
  );
  
  Otp($'Done pulling {nick}');
end;

begin
  try
    foreach var arg in GetArgs('BranchOverride') do
    begin
      var (repo, branch) := arg.Split(|':'|, 2);
      branch_per_repo.Add(repo, branch);
    end;
    
    Seq(
      new class( nick := 'OpenCL', name := 'OpenCL-Docs',     branch := 'custom' ),
      new class( nick := 'OpenGL', name := 'OpenGL-Registry', branch := 'custom' )
    ).ForEach(r->PullRep(r.name, r.branch, r.nick));
    // Not parallel, because that would break git index
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.