@echo off
setlocal
cd /d "%~dp0"

echo ======================================================================
echo  RadSearch: Synchronizing with Remote Repository...
echo ======================================================================

where git >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Pulling latest updates from GitHub...
    git pull origin main
    if %ERRORLEVEL% equ 0 (
        echo [OK] Synchronization complete.
    ) else (
        echo [WARNING] Git pull encountered an error. Starting existing local files...
    )
) else (
    echo [INFO] Git is not installed or not in PATH on this machine.
    echo Skipping remote sync and running local RadSearch instance.
)

echo Starting RadSearch...
call "%~dp0Run_RadSearch.bat"
exit /b 0
