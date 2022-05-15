unit PathUtils;
{$zerobasedstrings}

var assembly_file_name: string;
var assembly_dir: string;

function GetFullPath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  try
    if System.IO.Path.IsPathRooted(fname) then
    begin
      Result := fname;
      exit;
    end;
  except
    on e: System.ArgumentException do
      raise new System.ArgumentException($'Строка "{fname}" содержала недопустимые символы', 'fname');
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
function GetFullPathRTA(fname: string) := GetFullPath(fname, assembly_dir);

function GetRelativePath(fname: string; base_folder: string := System.Environment.CurrentDirectory): string;
begin
  var split_path: string->array of string :=
  path->GetFullPath(path).Split('/', '\');
  
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
    res.Append('..\');
  res += fname_parts.Skip(c).JoinToString('\');
  Result := res.ToString;
end;
function GetRelativePathRTA(fname: string) := GetRelativePath(fname, assembly_dir);

procedure CopyFile(source, destination: string);
begin
  if FileExists(destination) then raise new System.InvalidOperationException($'File {destination} already exists');
  var source_str := System.IO.File.OpenRead(source);
  try
    var destination_str := System.IO.File.Create(destination);
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
  System.IO.Directory.CreateDirectory(destination);
  var di := new System.IO.DirectoryInfo(source);
  foreach var fi in di.EnumerateFiles do
    fi.CopyTo(System.IO.Path.Combine(destination, fi.Name));
  foreach var sdi in di.GetDirectories do
    CopyDir(sdi.FullName, System.IO.Path.Combine(destination, sdi.Name));
end;

begin
  assembly_file_name := System.Reflection.Assembly.GetExecutingAssembly.Location;
  assembly_dir := System.IO.Path.GetDirectoryName(assembly_file_name);
//  exe_file_name := System.Diagnostics.Process.GetCurrentProcess.MainModule.FileName;
//  exe_dir := System.IO.Path.GetDirectoryName(exe_file_name);
end.