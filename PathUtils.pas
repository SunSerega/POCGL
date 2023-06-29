unit PathUtils;
{$zerobasedstrings}

uses System.IO;

var assembly_file_name: string;
var assembly_dir: string;

var dir_sep := |Path.DirectorySeparatorChar,Path.AltDirectorySeparatorChar|.Distinct.ToArray;

function GetFullPath(fname: string; base_folder: string := nil): string;
begin
  
  fname := fname.Replace('\','/');
  try
    if Path.IsPathRooted(fname) then
    begin
      Result := fname;
      exit;
    end;
  except
    on e: System.ArgumentException do
      raise new System.ArgumentException($'Строка "{fname}" содержала недопустимые символы', 'fname');
  end;
  
  if base_folder=nil then
    base_folder := System.Environment.CurrentDirectory;
  base_folder := GetFullPath(base_folder.Replace('\','/'));
  if base_folder.EndsWith('/') then
    base_folder := base_folder.Remove(base_folder.Length-1);
  var base_folder_parts := base_folder.Split('/');
  
  while true do
  begin
    if fname.StartsWith('/') then
      fname := fname.Substring(1);
    if not fname.StartsWith('..') then break;
    fname := fname.Substring('..'.Length);
    base_folder_parts := base_folder_parts[:^1];
  end;
  
  Result := base_folder_parts.Append(fname).JoinToString('/');
end;
function GetFullPathRTA(fname: string) := GetFullPath(fname, assembly_dir);

function GetRelativePath(fname: string; base_folder: string := nil): string;
begin
  if base_folder=nil then
    base_folder := System.Environment.CurrentDirectory.Replace('\','/');
  
  var split_path: string->array of string :=
    path->GetFullPath(path).Split(dir_sep);
  
  var fname_parts: array of string := split_path(fname);
  
  var base_folder_parts := split_path(base_folder);
  if string.IsNullOrWhiteSpace( base_folder_parts[^1] ) then
    base_folder_parts := base_folder_parts[:^1];
  
  if fname_parts.SequenceEqual(base_folder_parts) then
  begin
    Result := '';
    exit;
  end;
  
  var c := fname_parts.ZipTuple(base_folder_parts).TakeWhile(\(part1, part2)->part1=part2).Count;
  if c=0 then
  begin
    Result := fname;
    exit;
  end;
  
  var res := new StringBuilder;
  loop base_folder_parts.Length-c do
    res += '../';
  res += fname_parts.Skip(c).JoinToString('/');
  Result := res.ToString;
end;
function GetRelativePathRTA(fname: string) := GetRelativePath(fname, assembly_dir);

procedure CopyFile(source, destination: string);
begin
  if FileExists(destination) then raise new System.InvalidOperationException($'File {destination} already exists');
  var source_str := &File.OpenRead(source);
  try
    var destination_str := &File.Create(destination);
    try
      source_str.CopyTo(destination_str);
    finally
      destination_str.Close;
    end;
  finally
    source_str.Close;
  end;
end;

procedure CopyDir(source, destination: string);
begin
  Directory.CreateDirectory(destination);
  var di := new DirectoryInfo(source);
  foreach var fi in di.EnumerateFiles do
    fi.CopyTo(Path.Combine(destination, fi.Name));
  foreach var sdi in di.EnumerateDirectories do
    CopyDir(sdi.FullName, Path.Combine(destination, sdi.Name));
end;

begin
  assembly_file_name := System.Reflection.Assembly.GetExecutingAssembly.Location.Replace('\','/');
  assembly_dir := Path.GetDirectoryName(assembly_file_name).Replace('\','/');
//  exe_file_name := System.Diagnostics.Process.GetCurrentProcess.MainModule.FileName;
//  exe_dir := Path.GetDirectoryName(exe_file_name);
end.