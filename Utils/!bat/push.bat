call 0-cd-git-root.bat
git subtree push --prefix="Utils" --rejoin Utils SunUtils-main
git push
git pull Utils SunUtils-main:SunUtils-main
pause