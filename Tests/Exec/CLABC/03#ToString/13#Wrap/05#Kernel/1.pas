uses OpenCLABC;

begin
  var code := new ProgramCode(Context.Default, ReadAllText('1.cl'));
  Writeln(code['TEST']);
end.