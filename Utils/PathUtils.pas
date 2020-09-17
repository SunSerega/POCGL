unit PathUtils;
{$string_nullbased+}

var exe_file_name: string;
var exe_dir: string;

function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  if System.IO.Path.IsPathRooted(fname) then
  begin
    Result := fname;
    exit;
  end;
  
  var path := GetFullPath(base_folder);
  if path.EndsWith('\') then path := path.Remove(path.Length-1);
  
  if fname.StartsWith('\') then fname := fname.Substring(1);
  while fname.StartsWith('..\') do
  begin
    fname := fname.Substring(3);
    path := System.IO.Path.GetDirectoryName(path);
  end;
  
  Result := $'{path}\{fname}';
end;
function GetFullPathRTE(fname: string) := GetFullPath(fname, exe_dir);

function GetRelativePath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  fname := GetFullPath(fname);
  base_folder := GetFullPath(base_folder);
  
  var ind := 0;
  while true do
  begin
    if ind=fname.Length then break;
    if ind=base_folder.Length then break;
    if fname[ind]<>base_folder[ind] then break;
    ind += 1;
  end;
  
  if ind=0 then
  begin
    Result := fname;
    exit;
  end;
  
  var res := new StringBuilder;
  
  if ind <> base_folder.Length then
    loop base_folder.Skip(ind).Count(ch->ch='\') + 1 do
      res += '..\';
  
  if ind <> fname.Length then
  begin
    if fname[ind]='\' then ind += 1;
    res.Append(fname, ind, fname.Length-ind);
  end;
  
  Result := res.ToString;
end;
function GetRelativePathRTE(fname: string) := GetRelativePath(fname, exe_dir);

begin
  exe_file_name := System.Diagnostics.Process.GetCurrentProcess.MainModule.FileName;
  exe_dir := System.IO.Path.GetDirectoryName(exe_file_name);
end.