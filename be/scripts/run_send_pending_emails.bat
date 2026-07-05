@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BE_DIR=%SCRIPT_DIR%.."
pushd "%BE_DIR%"

set "PYTHON_EXE=%BE_DIR%\venv\Scripts\python.exe"
if not exist "%PYTHON_EXE%" (
  set "PYTHON_EXE=python"
)

"%PYTHON_EXE%" manage.py send_pending_emails
set "EXIT_CODE=%ERRORLEVEL%"

popd
exit /b %EXIT_CODE%
