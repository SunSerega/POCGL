unit PathUtils;
{$string_nullbased+}

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