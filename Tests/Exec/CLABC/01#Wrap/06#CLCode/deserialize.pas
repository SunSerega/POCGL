## uses OpenCLABC;

function ReSer<T>(self: T): T; extensionmethod;
  where T: BinCLCode;
begin
  Result := T(BinCLCode.Deserialize(self.Serialize));
end;

var h := new CLHeaderCode('void p();');
var h_dict := Dict('p.h' to h);

var lib := new CLCodeLib(new CLCompCode('#include "p.h"'#10'void p() {}', h_dict));

lib := lib.ReSer;

//TODO https://community.amd.com/t5/general-discussions/accessviolationexception-when-linking-opencl-programs-on-9800x3d/m-p/743880#M4798
var b_opt := new CLProgramCompOptions;
b_opt.CLKernelArgInfo := false;

var b1 := new CLCompCode('#include "p.h"'#10'kernel void k1(int x) { p(); }', h_dict, b_opt);
var b2 := new CLCompCode('#include "p.h"'#10'kernel void k2(int x) { p(); }', h_dict, b_opt);

b1 := b1.ReSer;
b2 := b2.ReSer;

var opt := new CLProgramLinkOptions;
opt.OptSignedZero := true; //TODO INTEL#?
var p := new CLProgramCode(new LinkableCLCode[]( lib, b1, b2 ), opt);

p := p.ReSer;

p.GetAllKernels.PrintLines;