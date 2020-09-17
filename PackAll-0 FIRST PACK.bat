


IF NOT EXIST "Utils\.git" (
	git.exe submodule update --progress --init -- "Utils"
)

IF NOT EXIST "PackAll.exe" (
	"C:\Program Files (x86)\PascalABC.NET\pabcnetc" "PackAll.pas"
	DEL "PackAll.pdb"
)

start PackAll.exe "Stages= FirstPack + Spec + OpenCL+OpenCLABC + OpenGL+OpenGLABC + Compile + Test + Release"


