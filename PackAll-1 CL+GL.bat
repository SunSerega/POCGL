@setlocal enableextensions
@cd /d "%~dp0"



start PackAll.exe "Stages= Reference + Dummy+OpenCL+OpenGL + Compile + Test + Release" %*


