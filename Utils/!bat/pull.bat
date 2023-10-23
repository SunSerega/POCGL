call 0-cd-git-root.bat
git subtree pull --prefix="Utils" Utils SunUtils-main
git push
git pull Utils SunUtils-main:SunUtils-main
pause