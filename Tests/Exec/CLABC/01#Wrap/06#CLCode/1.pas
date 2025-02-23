## uses OpenCLABC;

procedure PrintProps(self: CLProgramCode); extensionmethod;
begin
  Println(self.GetType);
  
  $'SourceCode:     {self.SourceCode}'.Println;
  
  // Missing before 2.1
//  $'SourceIL:       {ObjectToString(self.SourceIL)}'.Println;
  
  // Missing before 2.2
//  $'HasGlobalInit:  {self.HasGlobalInit}'.Println;
//  $'HasGlobalFnlz:  {self.HasGlobalFnlz}'.Println;
  
  // Intel extension
//  $'HostPipeNames:  {self.HostPipeNames}'.Println;
  
  self.GetAllKernels.PrintLines;
end;

var code := new CLProgramCode('kernel void k(int x) {}');
code.PrintProps;

var code2 := new CLProgramCode(code.Native);
(code=code2).Println;
Arr(code).Contains(code2).Println;
code2.PrintProps;
