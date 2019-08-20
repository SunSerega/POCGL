unit RepUtils;

uses System.Diagnostics;
uses MiscUtils in '..\Utils\MiscUtils.pas';

const GitExe = 'C:\Program Files\Git\bin\git.exe';

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
  folder := GetFullPath(folder, 'Reps');
  
  var psi := new ProcessStartInfo(GitExe, $'clone --progress -v "{key}" "{folder}"');
  psi.UseShellExecute := false;
  psi.RedirectStandardError := true;
  psi.RedirectStandardInput := true;
  psi.RedirectStandardOutput := true;
  
  var p := Process.Start(psi);
  p. ErrorDataReceived += (o,e)->Otp($'{nick}#ErrThr : {e.Data}');
  p.OutputDataReceived += (o,e)->Otp($'{nick}#OtpThr : {e.Data}');
  p. BeginErrorReadLine;
  p.BeginOutputReadLine;
  
  p.WaitForExit;
  Otp($'Done cloning {nick}');
  
end;

procedure PullRep(key, folder, nick: string);
begin
  var ToDo := 0;
end;

{$endregion Rep operations}

end.