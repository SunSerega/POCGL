@setlocal enableextensions
@cd /d "%~dp0"

call DeleteAllTemp.bat NoPause



IF NOT EXIST "PackAll.exe" (
	"C:\Program Files (x86)\PascalABC.NET\pabcnetc" "PackAll.pas"
	DEL "PackAll.pdb"
)

start PackAll.exe "Stages= PullUpstream + Reference + Dummy + OpenCL+OpenCLABC + OpenGL+OpenGLABC + Compile + Test + Release" %*


