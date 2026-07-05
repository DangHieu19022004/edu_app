@echo off
cd /d D:\edu_app\be

call venv\Scripts\activate.bat
python manage.py runserver 0.0.0.0:8000

pause
