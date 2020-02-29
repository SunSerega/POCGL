uses System.Diagnostics;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

const GitExe = 'C:\Program Files\Git\bin\git.exe';
var exe_dir := System.IO.Path.GetDirectoryName(GetEXEFileName);

{$region Rep operations}

procedure CloneRep(key, folder, nick: string);
begin
  Otp($'Cloning {nick}');
  folder := GetFullPath(folder,exe_dir);
  
  var psi := new ProcessStartInfo(GitExe, $'clone --progress -v "{key}" "{folder}"');
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new ThrProcOtp;
  p.ErrorDataReceived += (o,e) ->
  if e.Data=nil then
    p_otp.Finish else
    p_otp.Enq( $'{nick} : {e.Data}' );
  
  p.Start;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp.Enmr do Otp(l);
  Otp($'Done cloning {nick}');
  
end;

procedure PullRep(folder, nick: string);
begin
  Otp($'Pulling {nick}');
  folder := GetFullPath(folder,exe_dir);
  
  var psi := new ProcessStartInfo(GitExe, $'pull --progress -v --no-rebase "origin"');
  psi.WorkingDirectory := folder;
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardOutput := true;
  var p := new Process;
  p.StartInfo := psi;
  
  var p_otp := new ThrProcOtp;
  p.OutputDataReceived += (o,e)->if e.Data=nil then p_otp.Finish else p_otp.Enq( $'{nick} : {e.Data.Trim(#32)}' );
  p.ErrorDataReceived += (o,e)->if e.Data<>nil then                   p_otp.Enq( $'{nick} : [Info] {e.Data.Trim(''= ''.ToCharArray())}' );
  
  p.Start;
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  foreach var l in p_otp.Enmr do Otp(l);
  Otp($'Done pulling {nick}');
end;

procedure UpdateRep(key, folder, nick: string);
begin
  folder := GetFullPath(folder,exe_dir);
  
  if System.IO.Directory.Exists(folder+'\.git') then
    PullRep (       folder, nick ) else
    CloneRep( key,  folder, nick );
  
end;

{$endregion Rep operations}

begin
  try
    Arr(
      new class( name := 'OpenCL Docs',     path := 'OpenCL-Docs',     key := 'git@github.com:KhronosGroup/OpenCL-Docs.git'     ),
//      new class( name := 'OpenCL Registry', path := 'OpenCL-Registry', key := 'git@github.com:KhronosGroup/OpenCL-Registry.git' ),
      new class( name := 'OpenGL Registry', path := 'OpenGL-Registry', key := 'git@github.com:KhronosGroup/OpenGL-Registry.git' )
    ).Select(r->ProcTask(()-> UpdateRep(r.key, r.path, r.name) ))
    .CombineAsyncTask
    .SyncExec;
  except
    on e: Exception do ErrOtp(e);
  end;
end.