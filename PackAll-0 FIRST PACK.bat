


IF NOT EXIST "Utils\.git" (
	git submodule init
	git submodule update --progress --init --remote -- "Utils"
)

IF NOT EXIST "PackAll.exe" (
	"C:\Program Files (x86)\PascalABC.NET\pabcnetc" "PackAll.pas"
	DEL "PackAll.pdb"
)

start PackAll.exe "Stages= FirstPack + Spec + OpenCL+OpenCLABC + OpenGL+OpenGLABC + Compile + Test + Release"


