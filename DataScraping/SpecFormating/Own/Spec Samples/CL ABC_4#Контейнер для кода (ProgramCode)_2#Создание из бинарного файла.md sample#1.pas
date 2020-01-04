uses OpenCLABC;

begin
  var code := new ProgramCode(ReadAllText('0.cl'));
  
  var nf := System.IO.File.Create('0.bin');
  code.SerializeTo(nf);
  nf.Close;
  
end.