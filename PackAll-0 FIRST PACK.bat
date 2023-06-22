@setlocal enableextensions
@cd /d "%~dp0"



IF NOT EXIST "PackAll.exe" (
	"C:\Program Files (x86)\PascalABC.NET\pabcnetc" "PackAll.pas"
	DEL "PackAll.pdb"
)

start PackAll.exe "Stages= FirstPack + Reference + Dummy + OpenCL+OpenCLABC + OpenGL+OpenGLABC + Compile + Test + Release"


