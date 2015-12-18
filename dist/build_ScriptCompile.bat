@echo off
if [%1]==[] (set DATA=data) else (set DATA=%1)
"C:\Program Files (x86)\Steam\steamapps\common\skyrim\Papyrus Compiler\PapyrusCompiler.exe" "%DATA%\scripts\Source" -all -f="TESV_Papyrus_Flags.flg" -i="%DATA%\scripts\Source;C:\Program Files (x86)\Steam\steamapps\common\skyrim\Data\Scripts\source" -o="%DATA%\scripts"
IF %ERRORLEVEL% NEQ 0 pause
