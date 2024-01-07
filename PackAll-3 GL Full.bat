@setlocal enableextensions
@cd /d "%~dp0"



start PackAll.exe "Stages= Dummy+OpenGL+OpenGLABC + Compile + Test + Release" %*


