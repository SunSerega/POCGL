uses OpenGL;

begin
  Randomize(0);
  Vec4d.Random(0,1).Println;
  Mtr4d.Random(0,1).Println;
  Vec4d.Random(-1,+1).Println;
  Mtr4d.Random(-1,+1).Println;
  Vec4d.Random(+1,-1).Println;
  Mtr4d.Random(+1,-1).Println;
end.