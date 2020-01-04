uses System.IO;
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  try
    var inp_dir := GetFullPath('..\..\..\Reps\OpenGL-Registry\extensions', GetEXEFileName);
    var otp_dir := GetFullPath('..\ext spec texts', GetEXEFileName);
    
    if Directory.Exists(otp_dir) then Directory.Delete(otp_dir,true);
    
    var fls := Directory.EnumerateFiles(inp_dir, '*.txt',SearchOption.AllDirectories).ToList;
    var done := 0;
    var start_time := DateTime.Now;
    
    System.Threading.Thread.Create(()->
    while true do
    begin
      var cdone := done;
      Otp($'Formating spec texts: {cdone,4} of {fls.Count,4}, {cdone/fls.Count,6:P}');
      if cdone=fls.Count then
      begin
        Otp($'Done in {DateTime.Now-start_time}');
        if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString;
        Halt;
      end;
      Sleep(500);
    end).Start;
    
    foreach var fname in fls.Shuffle do
    begin
      
      var text := ReadAllText(fname);
      text := text.Remove(#13).Replace(#9,' '*4);
      while text.Contains(' '#10) do text := text.Replace(' '#10, #10);
      text := text
        .Replace('New Procedures and'#10'Functions', 'New Procedures and Functions')
        .Replace('enum outZ'#10, 'enum outZ,'#10)
        .Replace('uint memoryObject'#10, 'uint memoryObject,'#10)
        .Replace('(double x, double y, double z, double )', '(double x, double y, double z, double w)')
        .Replace('float params;'#10,'float params);'#10)
      ;
      
      var fname2 := otp_dir + fname.Substring(inp_dir.Length);
      System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(fname2));
      WriteAllText(fname2, text);
      
      done += 1;
    end;
    
  except
    on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
    on e: Exception do ErrOtp(e);
  end;
end.