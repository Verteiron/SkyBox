@echo off
SET SOURCEDIR=C:\Program Files (x86)\Steam\steamapps\common\skyrim\Data
SET TARGETDIR=%USERPROFILE%\Dropbox\SkyrimMod\SuperStash\dist\Data

xcopy /E /U /Y "%SOURCEDIR%\*" "%TARGETDIR%\"
