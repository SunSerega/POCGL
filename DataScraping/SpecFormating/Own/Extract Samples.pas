uses System.IO;
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  var samples_dir := GetFullPath('..\Spec Samples', GetEXEFileName);
  if Directory.Exists(samples_dir) then Directory.Delete(samples_dir, true);
  Directory.CreateDirectory(samples_dir);
  
  Directory.EnumerateDirectories('D:\1Cергей\Мои программы\проекты\POCGL\Packing\Spec')
  .Where(dir->not dir.StartsWith('0'))
  .SelectMany(dir->Directory.EnumerateFiles(dir, '*.md', SearchOption.AllDirectories).Tabulate(fname->dir))
  .ForEach(t->
  begin
    if not ReadAllText(t[0]).Contains('uses') then exit;
    
    var in_code := false;
    var sb := new StringBuilder;
    var i := 0;
    
    var AddSample: Action0 := ()->
    begin
      var fname := samples_dir + '\' + t[0].SubString(t[1].Length+1).Replace('\','_') + $' sample#{i}.pas';
      if FileExists(fname) then raise new System.IO.IOException($'file "{fname}" already exists');
      WriteAllText(fname, sb.ToString.Trim);
      sb.Clear;
      i += 1;
    end;
    
    foreach var l in ReadLines(t[0]) do
      if l.TrimStart.StartsWith('```') then
      begin
        if in_code then AddSample;
        in_code := not in_code;
      end else
      if in_code then
        sb.AppendLine(l);
    
    if sb.Length<>0 then AddSample;
  end);
  
  
end.