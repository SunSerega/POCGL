uses OpenCLABC;

begin
  var code := new ProgramCode(Context.Default, ReadAllText('1.cl'));
  Writeln(code.GetType);
  Writeln(code.Properties.GetType);
  code.GetAllKernels.PrintLines(k->k.Name);
  
  Writeln('='*30);
  Writeln(code.Properties.Source);
  Writeln('='*30);
  
  var code2 := new ProgramCode(code.Native);
  (code=code2).Println;
  Arr(code).Contains(code2).Println;
  Writeln(code2.GetType);
  Writeln(code2.Properties.GetType);
  code2.GetAllKernels.PrintLines(k->k.Name);
  
  Writeln('='*30);
  Writeln(code2.Properties.Source);
  Writeln('='*30);
  
end.