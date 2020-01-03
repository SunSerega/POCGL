unit RepUtils;

uses System.Diagnostics;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

const GitExe = 'C:\Program Files\Git\bin\git.exe';
var exe_dir := System.IO.Path.GetDirectoryName(GetEXEFileName);

{$region Otp}

procedure Otp(line: string) :=
MiscUtils.Otp(line);

procedure ErrOtp(e: Exception) :=
MiscUtils.ErrOtp(e);

{$endregion Otp}

{$region Rep operations}

procedure CloneRep(key, folder, nick: string);
begin
  Otp($'Cloning {nick}');
  folder := GetFullPath(folder,exe_dir);
  
  var psi := new ProcessStartInfo(GitExe, $'clone --progress -v "{key}" "{folder}"');
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  
  var p := Process.Start(psi);
  p.ErrorDataReceived += (o,e)->if not string.IsNullOrWhiteSpace(e.Data) then Otp($'{nick} : {e.Data.Trim(#32)}');
  p.BeginErrorReadLine;
  
  p.WaitForExit;
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
  
  var p := Process.Start(psi);
  p.OutputDataReceived += (o,e)->if not string.IsNullOrWhiteSpace(e.Data) then Otp($'{nick} : {e.Data.Trim(#32)}');
  p.ErrorDataReceived += (o,e)->if not string.IsNullOrWhiteSpace(e.Data) then Otp($'{nick} : {e.Data.Trim(''= ''.ToCharArray())}');
  p.BeginOutputReadLine;
  p.BeginErrorReadLine;
  
  p.WaitForExit;
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

end.