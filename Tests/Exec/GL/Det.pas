uses OpenGL;

begin
  Randomize(0);
  
  Mtr2d.Random(0,10).Println.Det.Println;
  Writeln('='*30);
  Mtr3d.Random(0,10).Println.Det.Println;
  Writeln('='*30);
  Mtr4d.Random(0,10).Println.Det.Println;
  
end.