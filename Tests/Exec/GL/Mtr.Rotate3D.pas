## uses OpenGL;

var v := new Vec3f(1,0,0);
var m := Mtr3f.Rotate3Dcw(Vec3f.Create(1,1,1).Normalized, Pi*2/3).Println;
loop 4 do
v := m*v.Println;
v.Println;