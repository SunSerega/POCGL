call 0-cd-git-root.bat
git remote add -f Utils git@github.com:SunSerega/SunUtils.git
git subtree add --prefix="Utils" Utils SunUtils-main
pause