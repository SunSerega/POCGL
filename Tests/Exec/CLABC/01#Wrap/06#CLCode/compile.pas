## uses OpenCLABC;

Println(new CLCodeLibOptions);
Println(new CLProgramCompOptions);
Println(new CLProgramLinkOptions);

var k_text := 'kernel void k(int x) {}';

// Build
var c1 := new CLProgramCode(k_text);
c1.GetAllKernels.PrintLines;

//TODO https://community.amd.com/t5/general-discussions/accessviolationexception-when-linking-opencl-programs-on-9800x3d/m-p/743880#M4798
var c2a_opt := new CLProgramCompOptions;
c2a_opt.CLKernelArgInfo := false;
// Compile
var c2a := new CLCompCode(k_text, nil, c2a_opt);
// Link
var c2 := new CLProgramCode(c2a);
c2.GetAllKernels.PrintLines;

// Compile+Link a lib
var lib := new CLCodeLib(new CLCompCode('void p(int x) {}'));
Println(lib);

// Link lib+compiled code
var c3 := new CLProgramCode(lib, c2a);
c3.GetAllKernels.PrintLines;