uses BinSpecData;

begin
  //  System.IO.Directory.EnumerateDirectories('gl ext spec')
  //  .Select(s->s.Substring('gl ext spec'.Length+1))
  //  .PrintLines;
  //  exit;
  
  var db := BinSpecDB.InitFromFolder('gl ext spec');
  
  //  writeln('done reading');
  
  db.Save('gl ext spec.bin');
  
end.