uses System.IO;
uses '../../../POCGL_Utils';

var enc := new System.Text.UTF8Encoding(true);

begin
  var samples_dir := GetFullPath('../Spec Samples', GetEXEFileName);
  if Directory.Exists(samples_dir) then Directory.Delete(samples_dir, true);
  Directory.CreateDirectory(samples_dir);
  
  var spec_dir := 'D:/1Cергей/Мои программы/проекты/POCGL/Packing/Spec';
  Directory.EnumerateDirectories(spec_dir)
  .Where(dir->not dir.StartsWith('0'))
  .SelectMany(dir->Directory.EnumerateFiles(dir, '*.md', SearchOption.AllDirectories))
  .ForEach(fname->
  begin
    var in_code := false;
    var sb := new StringBuilder;
    var i := 0;
    
    var AddSample: Action0 := ()->
    begin
      var res_fname := samples_dir + '/' + fname.SubString(spec_dir.Length+1).Replace('\','_').Replace('/','_') + $' sample#{i}.pas';
      if FileExists(res_fname) then raise new System.IO.IOException($'file "{res_fname}" already exists');
      var text := sb.ToString.Trim;
      if 'uses' in text then WriteAllText(res_fname, text, enc);
      sb.Clear;
      i += 1;
    end;
    
    foreach var l in ReadLines(fname, enc) do
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