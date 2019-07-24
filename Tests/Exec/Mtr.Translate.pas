uses OpenGL;

begin
  
  Mtr2f.Traslate(10).Println;
  Mtr3f.Traslate(10,20).Println;
  Mtr4f.Traslate(10,20,30).Println;
  Mtr2x3f.Traslate(10,20).Println;
  Mtr3x2f.Traslate(10).Println;
  Mtr2x4f.Traslate(10,20).Println;
  Mtr4x2f.Traslate(10).Println;
  Mtr3x4f.Traslate(10,20,30).Println;
  Mtr4x3f.Traslate(10,20).Println;
  
  Mtr2f.TraslateTransposed(10).Println;
  Mtr3f.TraslateTransposed(10,20).Println;
  Mtr4f.TraslateTransposed(10,20,30).Println;
  Mtr2x3f.TraslateTransposed(10).Println;
  Mtr3x2f.TraslateTransposed(10,20).Println;
  Mtr2x4f.TraslateTransposed(10).Println;
  Mtr4x2f.TraslateTransposed(10,20).Println;
  Mtr3x4f.TraslateTransposed(10,20).Println;
  Mtr4x3f.TraslateTransposed(10,20,30).Println;
  
end.