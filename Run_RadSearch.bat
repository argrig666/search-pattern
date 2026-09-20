@echo off
setlocal
cd /d "%~dp0"

:: 1. Check for local portable AutoHotkey v2 executable in current folder
if exist "%~dp0AutoHotkey64.exe" (
    start "" "%~dp0AutoHotkey64.exe" "%~dp0RadSearch_ProgressiveAccordion.ahk"
    exit /b 0
)

if exist "%~dp0AutoHotkey.exe" (
    start "" "%~dp0AutoHotkey.exe" "%~dp0RadSearch_ProgressiveAccordion.ahk"
    exit /b 0
)

:: 2. Check for system installed AutoHotkey v2 in Program Files
if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe" (
    start "" "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe" "%~dp0RadSearch_ProgressiveAccordion.ahk"
    exit /b 0
)

if exist "%ProgramFiles%\AutoHotkey\AutoHotkey.exe" (
    start "" "%ProgramFiles%\AutoHotkey\AutoHotkey.exe" "%~dp0RadSearch_ProgressiveAccordion.ahk"
    exit /b 0
)

:: 3. Fallback: Try default system shell association
start "" "%~dp0RadSearch_ProgressiveAccordion.ahk"
if %ERRORLEVEL% equ 0 exit /b 0

:: 4. If neither worked, provide guidance
echo ======================================================================
echo  RadSearch Launcher: AutoHotkey v2 executable not found!
echo ======================================================================
echo  To run RadSearch without administrator privileges:
echo   1. Download the portable zip: https://www.autohotkey.com/download/ahk-v2.zip
echo   2. Extract AutoHotkey64.exe into this folder:
echo      %~dp0
echo   3. Run this batch file again.
echo ======================================================================
pause
exit /b 1
