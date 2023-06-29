unit POCGL_Utils;

uses 'Utils/SubExecutables';

uses 'Utils/AOtp';
uses 'Utils/PathUtils';

type
  OtpLine           = AOtp.OtpLine;
  MessageException  = AOtp.MessageException;
  
procedure Otp(l: OtpLine) := AOtp.Otp(l);
procedure Otp(l: string; params kinds: array of string) := AOtp.Otp(l, kinds);
procedure ErrOtp(e: Exception) := AOtp.ErrOtp(e);

function GetFullPath(fname: string; base_folder: string := nil) := PathUtils.GetFullPath(fname, base_folder);
function GetFullPathRTA(fname: string)                          := PathUtils.GetFullPathRTA(fname);

function GetRelativePath(fname: string; base_folder: string := nil) := PathUtils.GetRelativePath(fname, base_folder);
function GetRelativePathRTA(fname: string)                          := PathUtils.GetRelativePathRTA(fname);

function IsSeparateExecution := AOtp.IsSeparateExecution;
procedure FinishedPause := AOtp.FinishedPause;

function nfi := FileLogger.nfi;
function enc := FileLogger.enc;

begin
  try
    while not FileExists('POCGL_Utils.pas') do
      System.Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(System.Environment.CurrentDirectory);
  except
    on e: Exception do ErrOtp(e);
  end;
end.