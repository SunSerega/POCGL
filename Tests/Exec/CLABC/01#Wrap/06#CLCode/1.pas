## uses OpenCLABC;

procedure PrintProps(self: CLCode); extensionmethod;
begin
  $'SourceCode:     {self.SourceCode}'.Println;
  $'SourceIL:       {_ObjectToString(self.SourceIL)}'.Println;
  $'HasGlobalInit:  {self.HasGlobalInit}'.Println;
  $'HasGlobalFnlz:  {self.HasGlobalFnlz}'.Println;
//  $'HostPipeNames:  {self.HostPipeNames}'.Println;
end;

var code := new CLProgramCode('kernel void k(int x) {}');

Println(code.GetType);
code.PrintProps;
code.GetAllKernels.PrintLines;

var code2 := new CLProgramCode(code.Native);
(code=code2).Println;
Arr(code).Contains(code2).Println;
Println(code2.GetType);
code2.PrintProps;
code2.GetAllKernels.PrintLines;
