@setlocal enableextensions
@cd /d "%~dp0"



start PackAll.exe "Stages= Dummy+OpenCL+OpenCLABC + Compile + Test + Release"


