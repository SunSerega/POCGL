## uses OpenGL;

Randomize(0);
var v1 := Vec2d.Random(-1,+1);
var v2 := Vec2d.Random(-1,+1);

var res := |
  Vec2d.CrossCW(v1,v2),
  Vec3d.Create(0,0,1) * Vec3d.CrossCW(Vec3d(v1),Vec3d(v2)),
  Mtr2d.FromCols(v1,v2).Determinant,
  Mtr2d.FromRows(v1,v2).Determinant
|;
res.PrintLines;
Println(res.Distinct.Count=1);