@echo off
SET SOURCEDIR=C:\Program Files (x86)\Steam\steamapps\common\skyrim\Data
SET TARGETDIR=%USERPROFILE%\Dropbox\SkyrimMod\SkyBox\dist\Data
SET DEPSOURCEDIR=D:\Projects\SKSE\SuperStash\SuperStash
SET DEPTARGETDIR=%USERPROFILE%\Dropbox\SkyrimMod\SkyBox\dist\dep\SuperStash\SuperStash

xcopy /E /U /Y "%SOURCEDIR%\*" "%TARGETDIR%\"
xcopy /E /D /U /Y "%DEPSOURCEDIR%\*" "%DEPTARGETDIR%\"