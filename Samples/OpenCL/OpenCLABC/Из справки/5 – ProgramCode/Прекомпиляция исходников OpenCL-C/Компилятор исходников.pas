uses OpenCLABC;

begin
  
  // проход по всем .cl файлам в данной папке
  foreach var fname in System.IO.Directory.EnumerateFiles(System.Environment.CurrentDirectory, '*.cl') do
  begin
    var code := new ProgramCode(ReadAllText(fname));
    
    var nf := System.IO.File.Create(fname+'.bin');
    code.SerializeTo(nf);
    nf.Close;
    
  end;
  
end.