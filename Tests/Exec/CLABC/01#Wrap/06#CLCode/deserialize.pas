## uses OpenCLABC;

var h := new CLHeaderCode('void p();');
var h_dict := Dict(('p.h', h));

var lib := new CLCodeLib(new CLCompCode('#include "p.h"'#10'void p() {}', h_dict));

lib := CLCodeLib(BinCLCode.Deserialize(lib.Serialize));

var b1 := new CLCompCode('#include "p.h"'#10'kernel void k1(int x) { p(); }', h_dict);
var b2 := new CLCompCode('#include "p.h"'#10'kernel void k2(int x) { p(); }', h_dict);

b1 := CLCompCode(BinCLCode.Deserialize(b1.Serialize));
b2 := CLCompCode(BinCLCode.Deserialize(b2.Serialize));

var opt := new CLProgramLinkOptions;
opt.OptSignedZero := true; //TODO INTEL#?
var p := new CLProgramCode(|lib as LinkableCLCode, b1, b2|, opt);

p := CLProgramCode(BinCLCode.Deserialize(p.Serialize));

p.GetAllKernels.PrintLines;