@echo off
set curdir=%cd%
cd "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\"
for /F "tokens=* USEBACKQ" %%F in (`vswhere.exe -latest -property installationPath`) do (set VSDIR=%%F)
call "%VSDIR%\Common7\Tools\VsDevCmd.bat" -arch=%2% > nul
cd %curdir%
CL /O2 /LD /nologo %1%
