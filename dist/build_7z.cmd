@echo off
SET FILENAME=SkyBox
SET ZEXE=c:\Program Files\7-Zip\7z.exe

for /f "tokens=1,2,3,4 delims=^/ " %%W in ('@echo %date%') DO SET NEWTIME=%%Z-%%X-%%Y
for /f "tokens=1,2,3 delims=:." %%W in ('@echo %time%') DO SET NEWTIME=%NEWTIME%_%%W-%%X-%%Y

echo %NEWTIME%
mkdir "%NEWTIME%_%COMPUTERNAME%"
cd "%NEWTIME%_%COMPUTERNAME%"
xcopy /y ..\data\*.esp .
xcopy /y ..\data\*.bsa .
xcopy /y ..\data\*readme* .
xcopy /y ..\..\doc\*readme* .
if exist ..\data\skse ( echo d | xcopy /e /y ..\data\skse skse )
"%ZEXE%" a -r "%FILENAME%_%NEWTIME%_%COMPUTERNAME%.7z" "*"
xcopy /y *.7z ..
cd ..
set I=0
echo Removing temp files, this may take a sec...
:DeleteTemp
REM Wait 1 second
ping -n 1 -w 1000 1.0.0.0 > nul
rmdir /s /q "%NEWTIME%_%COMPUTERNAME%"
set /A I += 1
echo Try %I%
if %I% GTR 5 goto NoDelete
if exist "%NEWTIME%_%COMPUTERNAME%" goto DeleteTemp
goto End
:NoDelete
echo Couldn't remove %NEWTIME%_%COMPUTERNAME% directory, delete it yourself!
:End