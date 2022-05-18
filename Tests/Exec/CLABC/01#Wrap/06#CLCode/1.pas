## uses OpenCLABC;
var code := new CLProgramCode('kernel void k(int x) {}');

Println(code.GetType);
Println(code.Properties.GetType);
code.GetAllKernels.PrintLines;

('='*30).Println;
Println(code.Properties.Source);
('='*30).Println;

var code2 := new CLProgramCode(code.Native);
(code=code2).Println;
Arr(code).Contains(code2).Println;
Println(code2.GetType);
Println(code2.Properties.GetType);
code2.GetAllKernels.PrintLines;

('='*30).Println;
Println(code2.Properties.Source);
('='*30).Println;