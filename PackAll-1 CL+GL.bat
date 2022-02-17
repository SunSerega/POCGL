@setlocal enableextensions
@cd /d "%~dp0"



start PackAll.exe "Stages= Reference + OpenCL+OpenGL + Compile + Test + Release"


