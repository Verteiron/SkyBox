@echo off
SET FILENAME=vSS_SuperStash
SET ZEXE=c:\Program Files\7-Zip\7z.exe

for /f "tokens=1,2,3,4 delims=^/ " %%W in ('@echo %date%') DO SET NEWTIME=%%Z-%%X-%%Y
for /f "tokens=1,2,3 delims=:." %%W in ('@echo %time%') DO SET NEWTIME=%NEWTIME%_%%W-%%X-%%Y

echo %NEWTIME%
mkdir "%NEWTIME%_%COMPUTERNAME%"
cd "%NEWTIME%_%COMPUTERNAME%"
xcopy /y ..\data\*.esp .
xcopy /y ..\datadep\*.bsa .
xcopy /y ..\data\*readme* .
xcopy /y ..\..\doc\*readme* .
echo d | xcopy /e /y ..\data\skse skse
echo d | xcopy /e /y ..\dep\skse skse
echo d | xcopy /e /y ..\data\vSS vSS
"%ZEXE%" a -r "vSS_SuperStash_deps_%NEWTIME%.7z" "*"
xcopy /y *.7z ..
cd ..
ping -n 1 -w 1000 1.0.0.0 > nul
rmdir /s /q "%NEWTIME%_%COMPUTERNAME%"
