unit POCGL_Utils;

uses SubExecutables in 'Utils\SubExecutables';

uses AOtp           in 'Utils\AOtp';
uses PathUtils      in 'Utils\PathUtils';

type
  MessageException = AOtp.MessageException;
  
procedure Otp(l: OtpLine) := AOtp.Otp(l);
procedure ErrOtp(e: Exception) := AOtp.ErrOtp(e);

function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory) := PathUtils.GetFullPath(fname, base_folder);
function GetFullPathRTA(fname: string)                                                          := PathUtils.GetFullPathRTA(fname);

function GetRelativePath(fname: string; base_folder: string := System.Environment.CurrentDirectory) := PathUtils.GetRelativePath(fname, base_folder);
function GetRelativePathRTA(fname: string)                                                          := PathUtils.GetRelativePathRTA(fname);

function is_separate_execution := Logger.main is ConsoleLogger;

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