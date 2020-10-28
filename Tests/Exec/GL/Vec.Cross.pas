uses OpenGL;

begin
  var v1 := new Vec3d(1,0,0);
  var v2 := new Vec3d(0,1,0);
  Vec3d.CrossCW(v1, v2).Println;
  Vec3d.CrossCCW(v1, v2).Println;
end.