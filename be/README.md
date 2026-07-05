# Edu App Backend

Django REST Framework backend cho ứng dụng giáo dục.

## Yêu cầu hệ thống

- Python 3.8+
- pip
- virtualenv (khuyến nghị)

## Cài đặt

1. Clone repository và di chuyển vào thư mục dự án:
```bash
cd d:\edu_app\be
```

2. Tạo virtual environment:
```bash
python -m venv venv
```

3. Kích hoạt virtual environment:
```bash
# Windows
.\venv\Scripts\Activate.ps1

# Linux/Mac
source venv/bin/activate
```

4. Cài đặt dependencies:
```bash
pip install -r requirements.txt
```

5. Tạo file .env từ .env.example:
```bash
cp .env.example .env
```

6. Chạy migrations:
```bash
python manage.py migrate
```

7. Tạo superuser (tùy chọn):
```bash
python manage.py createsuperuser
```

8. Chạy development server:
```bash
python manage.py runserver
```

API sẽ chạy tại: http://127.0.0.1:8000/

## Tu dong gui email lap lich tren Windows

Email `pending` khong tu chay theo `runserver`. Hay dung Windows Task Scheduler de chay dinh ky file:

```text
D:\edu_app\be\scripts\run_send_pending_emails.bat
```

Goi y cau hinh:
- Trigger: lap lai moi `1 minute`
- Action: `Start a program`
- Program/script: `edu_app\be\scripts\run_send_pending_emails.bat`
- Start in: `edu_app\be\scripts`

## API Endpoints

- Admin Panel: http://127.0.0.1:8000/admin/
- API Root: http://127.0.0.1:8000/api/
- Health Check: http://127.0.0.1:8000/api/health/

## Cấu trúc dự án

```
edu_app_be/
├── config/          # Cấu hình Django chính
│   ├── settings.py  # Cài đặt dự án
│   ├── urls.py      # URL routing chính
│   └── wsgi.py      # WSGI configuration
├── core/            # App core
│   ├── models.py    # Database models
│   ├── views.py     # API views
│   ├── serializers.py # DRF serializers
│   └── urls.py      # App URLs
├── media/           # Uploaded media files
├── staticfiles/     # Static files
├── .env             # Environment variables
├── .gitignore       # Git ignore file
├── manage.py        # Django management script
└── requirements.txt # Python dependencies
```

## Công nghệ sử dụng

- Django 5.2.12
- Django REST Framework 3.16.1
- django-cors-headers 4.9.0
- python-dotenv 1.2.2

## Phát triển

### Tạo app mới
```bash
python manage.py startapp <app_name>
```

### Tạo migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### Chạy tests
```bash
python manage.py test
```

## Deployment

Trước khi deploy production:
1. Đặt DEBUG=False trong .env
2. Cập nhật SECRET_KEY với giá trị bảo mật
3. Cấu hình ALLOWED_HOSTS
4. Sử dụng database production (PostgreSQL khuyến nghị)
5. Cấu hình static/media files với cloud storage

## License

[Chọn license phù hợp]
