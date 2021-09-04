uses OpenCLABC;

begin
  Writeln(new ProgramCode(Context.Default, ReadAllText('1.cl')));
end.