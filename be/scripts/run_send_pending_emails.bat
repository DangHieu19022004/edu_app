@echo off
setlocal EnableExtensions
title EduApp Pending Email Worker

set "SCRIPT_DIR=%~dp0"
set "BE_DIR=%SCRIPT_DIR%.."
set "PYTHON_EXE=%BE_DIR%\venv\Scripts\python.exe"

if not exist "%PYTHON_EXE%" (
  set "PYTHON_EXE=python"
)

if /I "%~1"=="once" goto :runOnce

pushd "%BE_DIR%"
set "PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True"

echo ============================================================
echo EduApp pending email worker is running.
echo It will check scheduled emails every 60 seconds.
echo Close this window to stop.
echo ============================================================
echo.

:loop
echo [%date% %time%] Checking pending emails...
"%PYTHON_EXE%" manage.py send_pending_emails --skip-checks
set "EXIT_CODE=%ERRORLEVEL%"
if %EXIT_CODE% NEQ 0 (
  echo [%date% %time%] Command failed with exit code %EXIT_CODE%.
)
echo [%date% %time%] Waiting 60 seconds...
timeout /t 60 /nobreak >nul
echo.
goto :loop

:runOnce
pushd "%BE_DIR%"
set "PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True"
"%PYTHON_EXE%" manage.py send_pending_emails --skip-checks
set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%
