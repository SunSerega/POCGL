## uses OpenCLABC;

var h := new CLHeaderCode('void p();');
var h_dict := Dict(('p.h', h));

var b0 := new CLCompCode('#include "p.h"'#10'void p() {}',                    h_dict);
var b1 := new CLCompCode('#include "p.h"'#10'kernel void k1(int x) { p(); }', h_dict);
var b2 := new CLCompCode('#include "p.h"'#10'kernel void k2(int x) { p(); }', h_dict);

b0 := CLCompCode(BinCLCode.Deserialize(b0.Serialize));
b1 := CLCompCode(BinCLCode.Deserialize(b1.Serialize));
b2 := CLCompCode(BinCLCode.Deserialize(b2.Serialize));

var opt := new CLProgramLinkOptions;
opt.OptSignedZero := true; //TODO INTEL#?
var p := new CLProgramCode(new LinkableCLCode[](b0, b1, b2), opt);

p := CLProgramCode(BinCLCode.Deserialize(p.Serialize));

p.GetAllKernels.PrintLines;